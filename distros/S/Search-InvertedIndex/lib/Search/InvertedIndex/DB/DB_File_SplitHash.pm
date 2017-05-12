package Search::InvertedIndex::DB::DB_File_SplitHash;

# $RCSfile: DB_File_SplitHash.pm,v $ $Revision: 1.5 $ $Date: 1999/10/20 16:51:00 $ $Author: snowhare $

use strict;
use Carp;
use Fcntl qw (:flock);
use DB_File;
use Class::NamedParms;
use Class::ParmList;
use Tie::DB_File::SplitHash;
use vars qw (@ISA $VERSION);

@ISA     = qw(Class::NamedParms);
$VERSION = "1.07";

# Used to catch attempts to open the same db 
# to multiple objects simultaneously and to
# store the object refs for the db databases.

my $open_maps = {};
my $FH_COUNT  = 0;

=head1 NAME

Search::InvertedIndex::DB::DB_File_SplitHash - A Berkeley database interface object for Search::InvertedIndex 

=head1 SYNOPSIS

  use Search::InvertedIndex::DB::DB_File_SplitHash;

  my $db = Search::InvertedIndex::DB::DB_File_SplitHash->new({
             -map_name => '/www/search-engine/databases/test-map_names/test',
                -multi => 4,
            -file_mode => 0644,
            -lock_mode => 'EX',
         -lock_timeout => 30,
       -blocking_locks => 0,
            -cachesize => 1000000,
        -write_through => 0, 
      -read_write_mode => 'RDONLY';
        });

  my $inv_map = Search::InvertedIndex->new({ -database => $db });

  my $query = Search::InvertedIndex::Query->new(...);
  my $result = $inv_map->search({ -query => $query });

  my $update = Search::InvertedIndex::Update->new(...);
  my $result = $inv_map->update({ -update => $update });

  $inv_map->close;

=head1 DESCRIPTION

Provides a standard interface to an underlaying database -
in this case Berkeley DB as extended by the Tie::DB_File::SplitHash
package.

There are twelve standard API calls required of any database interface
used by the Search::InvertedIndex module:

 new     - Takes all parameters required for initialization. 
           Free form parameters as required by the underlaying
           database.
 open    - Actually opens the database. No parameters.
 close   - Closes the database. No parameters.
 lock    - Sets a lock state of (UN, SH or EX) and optionally allows setting/
           changing the 'blocking/non-blocking' and timeouts for locking.
 get     - Fetches a string -value for a -key. Returns 'undef' if no -key matches in the database.
 put     - Stores a string -value for a -key. Returns true on success, false on failure.
 exists  - Returns true if the -key is defined in the database, false otherwise.
 delete  - Removes a -key and associated -value from database. Returns true on success, false on failure.
 clear   - Clears all keys/values from the database 
 status  - Returns open and lock status messages. 

 DESTROY - Used to dispose of the database object

=head1 CHANGES

 1.00 1999.06.16 - Initial release.

 1.01 1999.06.17 - Bug fix to 'close' method. Failed to clear the filehandle used for locking.

 1.02 1999.06.18 - Major bugfix to locking system and performance tweaking

 1.03 1999.07.01 - Documentation corrections.

 1.04 1999.10.20 - Removed use of 'use attr' for portability improvement

 1.06 2000.01.25 - Bugfix (added 'use Tie::DB_File::SplitHash;' to initialization)

 1.07 2000.03.23 - Bugfix for disposal when database was never actually opened 

=head2 Public API

=cut

####################################################################

=over 4

=item C<new($parm_ref);>

Provides the interface for obtaining a new Search::InvertedIndex
object for manipulating a inverted database.

Example 1: my $inv_map = Search::InvertedIndex->new;

Example 2: my $inv_map = Search::InvertedIndex->new({
                     -map_name => '/tmp/imap', # file path to map
                        -multi => 4,           # multiple DB file factor. Defaults to 4 
                    -file_mode => 0644,        # File permissions to open with. Defaults to 0666.
                    -cachesize => 1000000,     # DB cache size. Defaults to 1000000
                    -lock_mode => 'EX',        # DB lock mode. Defaults to EX
                 -lock_timeout => 30,          # Seconds to try and get locks. Defaults to 30
                -write_through => 0,           # Write through on cache? Defaults to 0 (no)
               -blocking_locks => 0,           # Locks should block? Defaults to 0 (no)
              -read_write_mode => 'RDWR',      # RDONLY or RDWR? Defaults to 'RDWR'
             });

=back

=cut

sub new {
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self  = Class::NamedParms->new(qw(-map_name  -file_mode     -write_through
                                          -cachesize -lock_timeout  -blocking_locks
                                          -fd        -filehandle    -read_write_mode
                                          -multi     -lock_mode     -open_status 
                                          -ident     -hash));

    bless $self,$class;

   # Read any passed parms
    my ($parm_ref) = {};
    if ($#_ == 0) {
        $parm_ref  = shift; 
    } elsif ($#_ > 0) { 
        %$parm_ref = @_; 
    }

    # Check the passed parms and set defaults as necessary
    my $parms = Class::ParmList->new({ -parms => $parm_ref,
                                 -legal => [-map_name,    -cachesize,     -read_write_mode,
                                            -multi,       -write_through,
                                            -lock_mode,   -lock_timeout,
                                            -file_mode,   -blocking_locks,
                                           ],
                              -required => [-map_name, -lock_mode ],
                              -defaults => { -multi => 4,            -blocking_locks => 0,
                                         -file_mode => 0666,               -cachesize => 5000000,
                                     -write_through => 0,            -read_write_mode => 'RDWR',
                                      -lock_timeout => 30,      
                                           },
                               });

       if (not defined $parms) {
           my $error_message = Class::ParmList->error;
           croak (__PACKAGE__ . "::new() - $error_message\n");
    }
    $self->SUPER::set($parms->all_parms);
    my $map_name = $self->SUPER::get('-map_name');
    $self->map_name($map_name);

    $self->SUPER::set({ -fd => undef,
               -open_status => 0,
                -filehandle => undef, 
                     -ident => time,
     });

    $self;
}


###############################################################
# Special accessor for '-map_name' because it is referenced 
# so frequently.
sub map_name {
    my $self = shift;
    my $package = __PACKAGE__;
    if (@_ == 1) {
        $self->{$package}->{-map_name} = shift;
        return;
    } else {
        return $self->{$package}->{-map_name};
    }
}
###############################################################

=over 4

=item C<open;>

Actually open the database for use.

Example 1: $inv_map->open;

=back

=cut

sub open {
    my $self= shift;

#    use attrs qw(method);
    
    # Check if they have _already_ opened this map
    my ($map) = $self->map_name;
    if ($map eq '') {
        croak (__PACKAGE__ . "::open() - Called without a -map_name specification\n");
    }
    if (defined $open_maps->{$map}) {
        croak (__PACKAGE__ . "::open() - Attempted to open -map_name '$map' multiple times\n");
    }

    # Do it.
    $self->_open_multi_map;
    if (not defined $open_maps->{$map}) {
        croak (__PACKAGE__ . "::open() - failed to open '$map'. Reason unknown. $!\n");
    }
    my ($fd) = $self->SUPER::get(-fd);
    if (not defined $fd) {
        croak (__PACKAGE__ . "::open() - failed to open '$map' - bad file descriptor returned\n");
    }
    $self->SUPER::set({ -open_status => 1 });
}

####################################################################

=over 4

=item C<status($parm_ref);>

Returns the requested status line for the database. Allowed requests
are '-open', and '-lock'.

Example 1: 
 my $status = $db->status(-open); # Returns either '1' or '0'

Example 2:
 my $status = $db->status(-lock_mode); # Returns 'UN', 'SH' or 'EX'

=back

=cut

sub status {
    my $self = shift;

    my ($request) = @_;

    $request = lc ($request);
    if ($request eq '-open') {
        return $self->SUPER::get(-open_status);
    }
    if ($request eq '-lock_mode') {
        return uc($self->SUPER::get(-lock_mode));
    }
    croak (__PACKAGE__ . "::status - Invalid status request of '$request' made. Only '-lock' and '-open' are legal.\n");
}

####################################################################

=over 4

=item C<lock($parm_ref);>

Sets or changes a filesystem lock on the underlaying database files.
Forces 'sync' if the stat is changed from 'EX' to a lower lock state 
(i.e. 'SH' or 'UN'). Croaks on errors.

Example:

    $inv->lock({ -lock_mode => 'EX',
              -lock_timeout => 30,
            -blocking_locks => 0,
          });

The only _required_ parameter is the -lock_mode. The other
parameters can be inherited from the object state. If the
other parameters are used, they change the object state
to match the new settings.

=back

=cut

sub lock {
    my $self = shift;

    my ($parm_ref) = {};
    if ($#_ == 0) {
        $parm_ref  = shift; 
    } elsif ($#_ > 0) { 
        %$parm_ref = @_; 
    }
    my $parms = Class::ParmList->new ({ -parms => $parm_ref,
                                        -legal => [-blocking_locks, -lock_timeout], 
                                     -required => [-lock_mode],
                                   });
    if (not defined $parms) {
        my $error_message = Class::ParmList->error;
        croak (__PACKAGE__ . "::lock() - $error_message\n");
    }
    my $map = $self->map_name;
    if (not defined $open_maps->{$map}) {
        croak (__PACKAGE__ . "::lock() - attempted to lock a map '$map' that was not open.\n");
    }
    my ($new_lock_mode,$new_blocking_locks,$new_lock_timeout) = $parms->get(-lock_mode,-blocking_locks,-lock_timeout);
    my ($old_lock_mode) = $self->SUPER::get(-lock_mode);
    $old_lock_mode      = uc ($old_lock_mode);

    if (defined $new_blocking_locks) {
        $self->SUPER::set({ -blocking_locks => $new_blocking_locks });
    }
    if (defined $new_lock_timeout) {
        $self->SUPER::set({ -lock_timeout => $new_lock_timeout });
    }
    my ($lock_timeout,$blocking_locks,$fh) = $self->SUPER::get(-lock_timeout,-blocking_locks,-filehandle);
    if (not defined $fh) {
        croak (__PACKAGE__ . "::lock() - no filehandle available for locking\n");
    }
    $new_lock_mode = uc ($new_lock_mode);
    return if ($new_lock_mode eq $old_lock_mode);

    # Sync if leaving 'EX' mode for another mode 
    if (($new_lock_mode ne 'EX') and ($old_lock_mode eq 'EX')) {
        if (not defined $map) {
            croak (__PACKAGE__ . "::lock() - no database open for locking\n");
        }
        my $db_object = $open_maps->{$map};
        if (not defined $db_object) {
            croak (__PACKAGE__ . "::lock() - no database object available for syncing $map\n");
        }
        $db_object->sync;
    }

    # Assemble the locking flags
    my $operation = 0;
    if (not $blocking_locks) {
        $operation |= LOCK_NB();
    }
    if ($new_lock_mode eq 'EX') {
        $operation |= LOCK_EX();
    } elsif ($new_lock_mode eq 'SH') {
        $operation |= LOCK_SH();
    } elsif ($new_lock_mode eq 'UN') {
        $operation |= LOCK_UN();
    } else {
        croak (__PACKAGE__ . "::lock() - Unknown locking mode of '$new_lock_mode' was specified\n");
    }
     # Get the new lock or die trying    
    $lock_timeout *= 10;
    no strict 'refs';
    until (flock ($fh,$operation)) {
        if (0 >= $lock_timeout--) {
            croak (__PACKAGE__ . "::lock() - Unable to obtain a '$new_lock_mode' lock on the map: $!");
        }
        select (undef,undef,undef,0.1); # Sleep 1/10th of a second
    }
    use strict 'refs';
    # The idea is to never think we have a lock we don't actually have
    $self->SUPER::set({ -lock_mode => $new_lock_mode });
}

####################################################################

=over 4

=item C<close;>

Closes the currently open -map_name and flushes all associated buffers.

=back

=cut

sub close {
    my ($self) = shift;
    $self->SUPER::set({ -open_status => 0 });
    my ($map) = $self->map_name;
    return if (not defined $map);
    my $db_object = $open_maps->{$map};
    return if (not defined $db_object);
    $db_object->sync;
    $db_object = undef;
    my ($hash) = $self->SUPER::get(-hash);
    $self->SUPER::clear(qw(-filehandle -fd -hash));
    delete $open_maps->{$map};
    if (not untie (%$hash)) {
        croak(__PACKAGE__ . "::close() - failed to untie hash\n");
    }
}

####################################################################

=over 4

=item C<DESTROY;>

Closes the currently open -map_name and flushes all associated buffers.

=back

=cut

sub DESTROY {
    my ($self) = shift;
    $self->close;
}

###############################################################

=over 4

=item C<put({ -key => $key, -value => $value });>

Stores the -value at the -key location in the database. No
serialization is performed - this is a pure 'store a string'
method. Returns '1' on success, '0' on failure.

=back

=cut

sub put {
    my ($self) = shift;

    # We *DON'T* use Class::ParmList here because this routine
    # is called many thousands of times. Performance counts here.
    my ($parm_ref) = {};
    if ($#_ == 0) {
        $parm_ref  = shift; 
    } elsif ($#_ > 0) { 
        %$parm_ref = @_; 
    }
    my $parms = {};
    %$parms = map { (lc($_),$parm_ref->{$_}) } keys %$parm_ref; 
    my @key_list = keys %$parms;
    if ($#key_list != 1) {
        croak (__PACKAGE__ . "::put() - incorrect number of parameters\n");
    }
    my $key = $parms->{'-key'};
    if (not defined $key) {
        croak (__PACKAGE__ . "::put() - invalid passed -key. 'undef' not allowed as a key.\n");
    }
    my $value = $parms->{'-value'};
    if (not defined $key) {
        croak (__PACKAGE__ . "::delete() - invalid passed -value. 'undef' not allowed as a value.\n");
    }
    my ($map) = $self->map_name;
    my ($db_object) = $open_maps->{$map};
    my ($status) = $db_object->put($key,$value);
    if ($status) {
        return 0;
    }
    1;
}

####################################################################

=over 4

=item C<get({ -key => $key });>

Returns the -value at the -key location in the database. No
deserialization is performed - this is a pure 'fetch a string'
method. It returns 'undef' if no such key exists in the database.

Example:

  my ($value) = $db->get({ -key => $key });

=back

=cut

sub get {
    my ($self) = shift;

    # We *DON'T* use Class::ParmList here because this routine
    # is called many thousands of times. Performance counts here.
    my ($parm_ref) = {};
    if ($#_ == 0) {
        $parm_ref  = shift; 
    } elsif ($#_ > 0) { 
        %$parm_ref = @_; 
    }
    my $parms = {};
    %$parms = map { (lc($_),$parm_ref->{$_}) } keys %$parm_ref; 
    my @key_list = keys %$parms;
    if ($#key_list != 0) {
        croak (__PACKAGE__ . "::get() - incorrect number of parameters\n");
    }
    my $key = $parms->{'-key'};
    if (not defined $key) {
        croak (__PACKAGE__ . "::get() - invalid passed -key. 'undef' not allowed as a key.\n");
    }
    my ($value);
    my ($map) = $self->map_name;
    my ($db_object) = $open_maps->{$map};
    my ($status) = $db_object->get($key,$value);
    return undef if ($status);
    $value;
}

####################################################################

=over 4

=item C<delete({ -key => $key });>

Deletes the -value at the -key location in the database. 

=back

=cut

sub delete {
    my ($self) = shift;
#    use attrs qw (method);

    # We *DON'T* use Class::ParmList here because this routine
    # is called many thousands of times. Performance counts here.
    my ($parm_ref) = {};
    if ($#_ == 0) {
        $parm_ref  = shift; 
    } elsif ($#_ > 0) { 
        %$parm_ref = @_; 
    }
    my $parms = {};
    %$parms = map { (lc($_),$parm_ref->{$_}) } keys %$parm_ref; 
    my @key_list = keys %$parms;
    if ($#key_list != 0) {
        croak (__PACKAGE__ . "::delete() - incorrect number of parameters\n");
    }
    if ($key_list[0] ne '-key') {
        croak (__PACKAGE__ . "::delete() - invalid passed parameter name of '$key_list[0]'\n");
    }
    my $key = $parms->{'-key'};
    if (not defined $key) {
        croak (__PACKAGE__ . "::delete() - invalid passed -key value. 'undef' not allowed as a key.\n");
    }
    my ($map) = $self->map_name;
    my ($db_object) = $open_maps->{$map};
    my ($status) = $db_object->del($key);
    return 0 if ($status);
    1;
}
####################################################################

=over 4

=item C<exists{-key => $key});>

Returns true if the -key exists in the database. 
Returns false if the -key does not exist in the database.

=back

=cut

sub exists {
    my ($self) = shift;

    # We *DON'T* use Class::ParmList here because this routine
    # is called many thousands of times. Performance counts here.
    my ($parm_ref) = {};
    if ($#_ == 0) {
        $parm_ref  = shift; 
    } elsif ($#_ > 0) { 
        %$parm_ref = @_; 
    }
    my $parms = {};
    %$parms = map { (lc($_),$parm_ref->{$_}) } keys %$parm_ref; 
    my @key_list = keys %$parms;
    if ($#key_list != 0) {
        croak (__PACKAGE__ . "::delete() - incorrect number of parameters\n");
    }
    if ($key_list[0] ne '-key') {
        croak (__PACKAGE__ . "::delete() - invalid passed parameter name of '$key_list[0]'\n");
    }
    my $key = $parms->{'-key'};
    if (not defined $key) {
        croak (__PACKAGE__ . "::delete() - invalid passed -key value. 'undef' not allowed as a key.\n");
    }
    my ($map) = $self->map_name;
    my ($db_object) = $open_maps->{$map};
    $db_object->exists($key);
}

####################################################################

=over 4

=item C<clear;>

Internal method. Not for access outside of the module.

Completely clears the map database.

=back

=cut

sub clear {
    my ($self) = shift;

    my ($map) = $self->map_name;
    my ($db_object) = $open_maps->{$map};
    $db_object->CLEAR;
}

###############################################################
# _open_multi_map;
#
#Internal method. Not for access outside of the module.
#
#Actually open the map for use using either DB_File or
#Tie::DB_File_SplitHash as appropriate.
#
#Example 1: $self->_open_multi_map;
#

sub _open_multi_map {
    my ($self) = shift;

    # Open the map
    my $map = $self->map_name;
    my ($cachesize,$file_mode,$lock_mode,$lock_timeout,$blocking_locks,
        $multi,$write_through,$read_write_mode) = $self->SUPER::get(-cachesize,-file_mode,
        -lock_mode,-lock_timeout,-blocking_locks,-multi,-write_through,-read_write_mode);

    # Cache tuning is allowed
    $DB_HASH->{'cachesize'} = $cachesize;

    # Read/Write mode setup
    my $flags = 0;
    $read_write_mode = uc($read_write_mode);
    if ($read_write_mode eq 'RDONLY') {
        $flags |= O_RDONLY();
    } elsif ($read_write_mode eq 'RDWR') {
        $flags |= O_RDWR()|O_CREAT();
    } else {
        croak(__PACKAGE__ . "::_open_multi_map() - Unrecognized -read_write_mode of '$read_write_mode' (must be either 'RDWR' or 'RDONLY')\n");
    }

    # Allow for 'write through'
    if ($write_through) {
        $flags |= O_SYNC();
    }

    # Tie the map database
    my $hash = {};
    my $db_object;
    if ($multi == 1) { # Performance hack. With only 1 it is 2-3x faster to just tie directly to DB_File.
        eval { 
            $db_object = tie (%$hash,'DB_File',$map,$flags,$file_mode,$DB_HASH);
        };
    } else {
        eval { 
            $db_object = tie (%$hash,'Tie::DB_File::SplitHash',$map,$flags,$file_mode,$DB_HASH,$multi);
        };
    }

    if ($@) {
        croak (__PACKAGE__ . "::_open_multi_map() - Unable to tie -map_name '$map': $@\n");
    }

    if (not defined $db_object) {
        croak (__PACKAGE__ . "::_open_multi_map() - Unable to tie -map_name '$map': $!\n");
    }
    if (not ref $db_object) {
        croak (__PACKAGE__ . "::_open_multi_map() - Returned object was not a reference: $!\n");
    }
    $open_maps->{$map} = $db_object;

    # Set locking up for the initial state
    my $fd = $db_object->fd;
    if (not defined $fd) {
        croak (__PACKAGE__ . "::_open_multi_map() - Unable to get a file descriptor for the -map_name '$map': $!\n");
    }
    $FH_COUNT++;
    my $fh = "FH_COUNTER_$FH_COUNT";
    no strict 'refs';
    CORE::open ($fh, "+<&=$fd") or croak (__PACKAGE__ . "::_open_multi_map() - unable to open file descriptor for locking: $!");
    use strict 'refs';
    $self->SUPER::set({ -filehandle => $fh, 
                         -lock_mode => 'UN',
                              -hash => $hash,
                                 -fd => $fd,
                    });
    $lock_mode = 'SH' if (not defined $lock_mode);
    $lock_mode = uc($lock_mode);
    eval { $self->lock({ -lock_mode => $lock_mode }); }; # Lock gets its arguments from the object state by default
    if ($@) {
        my $error = $@;
        $self->SUPER::clear(-filehandle,-hash,-fd);
        delete $open_maps->{$map};
        undef $hash;
        undef $db_object;
        croak (__PACKAGE__ . "::_open_multi_map() - Failed to lock the -map_name '$map' to lock mode '$lock_mode': $error\n");
    }

}

####################################################################

=head1 COPYRIGHT

Copyright 1999, Benjamin Franz (<URL:http://www.nihongo.org/snowhare/>) and 
FreeRun Technologies, Inc. (<URL:http://www.freeruntech.com/>). All Rights Reserved.
This software may be copied or redistributed under the same terms as Perl itelf.

=head1 AUTHOR

Benjamin Franz

=head1 TODO

Everything.

=cut

1;
