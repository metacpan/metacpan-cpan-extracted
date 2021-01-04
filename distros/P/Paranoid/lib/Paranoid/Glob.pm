# Paranoid::Glob -- Paranoid Glob objects
#
# $Id: lib/Paranoid/Glob.pm, 2.08 2020/12/31 12:10:06 acorliss Exp $
#
# This software is free software.  Similar to Perl, you can redistribute it
# and/or modify it under the terms of either:
#
#   a)     the GNU General Public License
#          <https://www.gnu.org/licenses/gpl-1.0.html> as published by the 
#          Free Software Foundation <http://www.fsf.org/>; either version 1
#          <https://www.gnu.org/licenses/gpl-1.0.html>, or any later version
#          <https://www.gnu.org/licenses/license-list.html#GNUGPL>, or
#   b)     the Artistic License 2.0
#          <https://opensource.org/licenses/Artistic-2.0>,
#
# subject to the following additional term:  No trademark rights to
# "Paranoid" have been or are conveyed under any of the above licenses.
# However, "Paranoid" may be used fairly to describe this unmodified
# software, in good faith, but not as a trademark.
#
# (c) 2005 - 2020, Arthur Corliss (corliss@digitalmages.com)
# (tm) 2008 - 2020, Paranoid Inc. (www.paranoid.com)
#
#####################################################################

#####################################################################
#
# Environment definitions
#
#####################################################################

package Paranoid::Glob;

use 5.008;

use strict;
use warnings;
use vars qw($VERSION);

use Carp;
use Errno qw(:POSIX);
use Fcntl qw(:mode);
use File::Glob qw(bsd_glob);
use Paranoid;
use Paranoid::Debug qw(:all);

($VERSION) = ( q$Revision: 2.08 $ =~ /(\d+(?:\.\d+)+)/s );

#####################################################################
#
# Module code follows
#
#####################################################################

sub _sanitize (\@) {

    # Purpose:  Detaints passed strings
    # Returns:  True if successful, false on any detaint errors
    # Usage:    $rv = _sanitize(@globs);

    my $aref = shift;
    my $rv   = 1;

    # Make sure all glob entries are sane
    foreach (@$aref) {
        if (/^([[:print:]]+)$/s) {
            $_ = $1;
            $_ =~ s#/{2,}#/#sg;
        } else {
            $Paranoid::ERROR =
                pdebug( 'invalid glob entry: %s', PDLEVEL1, $_ );
            $rv = 0;
            last;
        }
    }

    return $rv;
}

sub new {

    # Purpose:  Instantiates a new object of this class
    # Returns:  Object reference if successful, undef otherwise
    # Usage:    $obj = Paranoid::Glob->new(
    #                   globs       => [ qw(/lib/* /sbin/*) ],
    #                   literals    => [ qw(/lib/{sadfe-asda}) ],
    #                   );

    my ( $class, %args ) = splice @_;
    my $self = [];
    my $rv   = 1;

    # Validate arguments
    if ( exists $args{globs} ) {
        croak 'Optional key/value pair "globs" not properly defined'
            unless ref $args{globs} eq 'ARRAY';
    }
    if ( exists $args{literals} ) {
        croak 'Optional key/value pair "literals" not properly defined'
            unless ref $args{literals} eq 'ARRAY';
    }

    pdebug( 'entering w/keys %s', PDLEVEL1, keys %args );
    pIn();

    bless $self, $class;

    # Add any globs or literals if they were passed during inititation
    $rv = $self->addLiterals( @{ $args{literals} } )
        if exists $args{literals};
    if ($rv) {
        $rv = $self->addGlobs( @{ $args{globs} } ) if exists $args{globs};
    }

    if ($rv) {
        $rv = $self;
    } else {
        $rv   = 'undef';
        $self = undef;
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $self );

    return $self;
}

sub addGlobs {

    # Purpose:  Adds more globs to the object that need to be filtered through
    #           the bsd_glob
    # Returns:  True if all globs passed muster, false if not
    # Usage:    $rv = $obj->addGlobs(qw(/etc/* /root/*));

    my ( $self, @globs ) = splice @_;
    my $rv = 1;
    my @tmp;

    # Silently remove undefs and zero strings
    @globs = grep { defined $_ and length $_ } @globs;

    pdebug( 'entering w/%d globs', PDLEVEL1, scalar @globs );
    pIn();

    # Make sure all glob entries are sane
    $rv = _sanitize(@globs);

    if ($rv) {

        # Filter them through bsd_glob unless the file exists as named in the
        # literal string
        foreach (@globs) {
            push @tmp, -e $_ ? $_ : bsd_glob($_);
        }

        # Final detaint
        foreach (@tmp) { /^([[:print:]]+)$/s and $_ = $1 }

        pdebug( 'added %d entries', PDLEVEL2, scalar @tmp );

        # Add to ourself
        push @$self, splice @tmp;
    }

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub addLiterals {

    # Purpose:  Adds more globs to the object as literal strings
    # Returns:  True if all globs passed muster, false if not
    # Usage:    $rv = $obj->addLiterals(qw(/etc/* /root/*));

    my ( $self, @globs ) = splice @_;
    my $rv = 1;

    # Silently remove undefs and zero strings
    @globs = grep { defined $_ and length $_ } @globs;

    pdebug( 'entering w/%d literals', PDLEVEL1, scalar @globs );
    pIn();

    # Make sure all glob entries are sane
    $rv = _sanitize(@globs);

    push @$self, splice @globs if $rv;

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

sub consolidate {

    # Purpose:  Removes redundant entries and sorts alphabetically
    # Returns:  True
    # Usage:    $obj->consolidate;

    my ($self) = @_;
    my (%tmp);

    pdebug( 'entering w/%d entries', PDLEVEL1, scalar @$self );

    %tmp = map { $_ => 1 } @$self;
    @$self = sort keys %tmp;

    pdebug( 'leaving w/%d entries', PDLEVEL1, scalar @$self );

    return 1;
}

sub exists {

    # Purpose:  Returns a list of the entries that exist on the file system
    # Returns:  List of existing filesystem entries
    # Usage:    @entries = $obj->existing;

    my ($self) = @_;
    my @entries = grep { scalar lstat $_ } @$self;

    pdebug( 'leaving w/rv: %s', PDLEVEL1, @entries );

    return @entries;
}

sub readable {

    # Purpose:  Returns a list of the entries that are readable by the
    #           effective user
    # Returns:  List of readable entries
    # Usage:    @entries = $obj->readable;

    my ($self) = @_;
    my @entries = grep { -r $_ } $self->exists;

    pdebug( 'leaving w/rv: %s', PDLEVEL1, @entries );

    return @entries;
}

sub writable {

    # Purpose:  Returns a list of the entries that are writable by the
    #           effective user
    # Returns:  List of writable entries
    # Usage:    @entries = $obj->writable;

    my ($self) = @_;
    my @entries = grep { -w $_ } $self->exists;

    pdebug( 'leaving w/rv: %s', PDLEVEL1, @entries );

    return @entries;
}

sub executable {

    # Purpose:  Returns a list of the entries that are executable/traversable
    #           by the effective user
    # Returns:  List of executable/traversable entries
    # Usage:    @entries = $obj->executable;

    my ($self) = @_;
    my @entries = grep { -x $_ } $self->exists;

    pdebug( 'leaving w/rv: %s', PDLEVEL1, @entries );

    return @entries;
}

sub owned {

    # Purpose:  Returns a list of the entries that are owned by the
    #           effective user
    # Returns:  List of owned entries
    # Usage:    @entries = $obj->owned;

    my ($self) = @_;
    my @entries = grep { -o $_ } $self->exists;

    pdebug( 'leaving w/rv: %s', PDLEVEL1, @entries );

    return @entries;
}

sub directories {

    # Purpose:  Returns a list of existing directories
    # Returns:  List of directories
    # Usage:    @dirs = $obj->directories;

    my ($self) = @_;
    my @dirs = grep { -d $_ } $self->exists;

    pdebug( 'leaving w/rv: %s', PDLEVEL1, @dirs );

    return @dirs;
}

sub files {

    # Purpose:  Returns a list of existing files
    # Returns:  List of files
    # Usage:    @files = $obj->files;

    my ($self) = @_;
    my @files = grep { -f $_ } $self->exists;

    pdebug( 'leaving w/rv: %s', PDLEVEL1, @files );

    return @files;
}

sub symlinks {

    # Purpose:  Returns a list of existing symlinks
    # Returns:  List of symlinks
    # Usage:    @files = $obj->symlinks;

    my ($self) = @_;
    my @symlinks = grep { -l $_ } $self->exists;

    pdebug( 'leaving w/rv: %s', PDLEVEL1, @symlinks );

    return @symlinks;
}

sub pipes {

    # Purpose:  Returns a list of existing pipes
    # Returns:  List of pipes
    # Usage:    @files = $obj->pipes;

    my ($self) = @_;
    my @pipes = grep { -p $_ } $self->exists;

    pdebug( 'leaving w/rv: %s', PDLEVEL1, @pipes );

    return @pipes;
}

sub sockets {

    # Purpose:  Returns a list of existing sockets
    # Returns:  List of sockets
    # Usage:    @files = $obj->sockets;

    my ($self) = @_;
    my @sockets = grep { -S $_ } $self->exists;

    pdebug( 'leaving w/rv: %s', PDLEVEL1, @sockets );

    return @sockets;
}

sub blockDevs {

    # Purpose:  Returns a list of existing block nodes
    # Returns:  List of block devs
    # Usage:    @files = $obj->blockDevs;

    my ($self) = @_;
    my @bdevs = grep { -b $_ } $self->exists;

    pdebug( 'leaving w/rv: %s', PDLEVEL1, @bdevs );

    return @bdevs;
}

sub charDevs {

    # Purpose:  Returns a list of existing character nodes
    # Returns:  List of character devs
    # Usage:    @files = $obj->charDevs;

    my ($self) = @_;
    my @cdevs = grep { -c $_ } $self->exists;

    pdebug( 'leaving w/rv: %s', PDLEVEL1, @cdevs );

    return @cdevs;
}

sub recurse {

    # Purpose:  Recursively adds all subdirectories and their contents to the
    #           glob.  Passing an optional boolean argument will tell it
    #           whether or not to follow symlinks.  Defaults to not following
    #           symlinks (false).  Another optional boolean argument instructs
    #           this method whether or not to include hidden directories.  In
    #           accordance with the traditional behavior of shell globbing it
    #           defaults to false.
    # Returns:  True if successful, false on any errors (like permission
    #           denied, etc.)
    # Usage:    $rv = $obj->recurse;
    # Usage:    $rv = $obj->recurse(1);
    # Usage:    $rv = $obj->recurse(1, 1);

    my ( $self, $follow, $hidden ) = @_;
    my $rv = 1;
    my ( %seen, @crawl, $lindex, $slindex );

    pdebug( 'entering', PDLEVEL1 );
    pIn();

    # Define our dirFilter sub, who's sole purpose is to extract a list of
    # directories from the passed list of entries
    my $dirFilter = sub {
        my @entries = @_;
        my ( $entry, @fstat, @dirs );

        # Extract a list of directories from our current contents
        foreach $entry (@entries) {
            @fstat = lstat $entry;
            if (@fstat) {

                # Entry exists
                if ( S_ISDIR( $fstat[2] ) ) {

                    # Filter out sockets, etc.
                    next if $fstat[2] &

                            # Add the directory
                            push @dirs, $entry;

                } elsif ( $follow and S_ISLNK( $fstat[2] ) ) {

                    # Add symlinks pointing to directories if we're set
                    # to follow
                    push @dirs, $entry if -d $entry;
                }

            } else {

                # Report any errors for anything other than ENOENT
                unless ( $! == ENOENT ) {
                    Paranoid::ERROR = pdebug( 'couldn\'t access %s: %s',
                        PDLEVEL1, $entry, $! );
                    $rv = 0;
                }
            }
        }

        return @dirs;
    };

    # Define our addDir sub, whose purpose is to return the contents of the
    # passed directory
    my $addDir = sub {
        my $dir = shift;
        my ( $fh, @contents );

        if ( opendir $fh, $dir ) {

            # Get the list, filtering out '.' & '..'
            foreach ( readdir $fh ) {
                next if m/^\.\.?$/s;
                next if m/^\./s and not $hidden;
                push @contents, "$dir/$_";
            }
            closedir $fh;

        } else {
            Paranoid::ERROR =
                pdebug( 'error opening directory %s: %s', PDLEVEL1, $dir,
                $! );
            $rv = 0;
        }

        return @contents;
    };

    # Consolidate to reduce potential redundancies
    $self->consolidate;

    # Get our initial list of directories to crawl
    @crawl = &$dirFilter(@$self);

    # Start crawling
    $lindex  = 0;
    $slindex = $#$self;
    while ( $lindex <= $#crawl ) {

        # Skip the directory if we've already crawled it
        if ( exists $seen{ $crawl[$lindex] } ) {
            $lindex++;
            next;
        }

        # Add the directory's contents
        push @$self, ( &$addDir( $crawl[$lindex] ) );
        $seen{ $crawl[$lindex] } = 0;
        $lindex++;
        $slindex++;

        # Add any new directories to the crawl list
        push @crawl, ( &$dirFilter( @$self[ $slindex .. $#$self ] ) );
        $slindex = $#$self;
    }

    # Final consolidation
    $self->consolidate;

    pOut();
    pdebug( 'leaving w/rv: %s', PDLEVEL1, $rv );

    return $rv;
}

1;

__END__

=head1 NAME

Paranoid::Glob - Paranoid Glob objects

=head1 VERSION

$Id: lib/Paranoid/Glob.pm, 2.08 2020/12/31 12:10:06 acorliss Exp $

=head1 SYNOPSIS

    $obj = Paranoid::Glob->new(
           globs       => [ qw(/lib/* /sbin/* /etc/foo.conf) ],
           literals    => [ qw(/tmp/{sadssde-asdfak}) ],
           );

    print "Expanded globs:\n\t", join("\n\t", @$obj);

    $rv = $obj->addGlobs(qw(/etc/* /bin/*));
    $rv = $obj->addLiterals(qw(/etc/foo.conf));

    $obj->consolidate;

    @existing       = $obj->exists;
    @readable       = $obj->readable;
    @writable       = $obj->writable;
    @executable     = $obj->executable;
    @owned          = $obj->owned;
    @directories    = $obj->directories;
    @files          = $obj->files;
    @symlinks       = $obj->symlinks;
    @pipes          = $obj->pipes;
    @sockets        = $obj->sockets;
    @blockDevs      = $obj->blockDevs;
    @charDevs       = $obj->charDevs;

    $obj->recurse(1, 1);

=head1 DESCRIPTION

The primary purpose of these objects is to allow an easy way to detaint a list
of files and/or directories while performing shell expansion of names.  It 
does this with a caveat, however.  If a given file or directory name exists on 
the file system as a literal string (regardless of whether it has shell 
expansion characters in it) it will be added as such.  It is only filtered 
through B<bsd_glob> if it does not exist on the file system.

The objects can also be created with instructions to explicitly treat all
names as literal strings.

Any undef or zero-length strings passed in the files array are silently
removed.

As a convenience subsets of the expanded files can be returned based on the
common B<stat>/B<lstat> tests.  Please note the obvious caveats, however:
asking for a list of directories will fail to list directories if the
effective user does not have privileges to read the parent directory, etc.
This is no different than performing '-d', etc., directly.  If you care about
privilege/permission issues you shouldn't use these methods.

An additional method (B<recurse>) falls outside of what a globbing construct
should do, but it seemed too useful to leave out.

=head1 SUBROUTINES/METHODS

=head2 new

    $obj = Paranoid::Glob->new(
           globs       => [ qw(/lib/* /sbin/* /etc/foo.conf) ],
           literals    => [ qw(/tmp/{sadssde-asdfak}) ],
           );

This class method creates a B<Paranoid::Glob> object.  It can be constructed
with optional literal strings and/or globs to expand.  All are filtered 
through a [[:print:]] regex for detainting.  Any undefined or zero-length 
strings are silently removed from the arrays.

The object reference is a blessed array reference, which is populated with the
expanded (or literal) globs, making it easy to iterate over the final list.

If any entry in the globs array fails to detaint this method will return undef
instead of an object reference.

=head2 addGlobs

    $rv = $obj->addGlobs(qw(/etc/* /bin/*));

Adds more globs to the object that are detainted and filtered through
B<bsd_glob>.  Returns false if any strings fail to detaint.  All undefined or
zero-length strings are silently removed.

=head2 addLiterals

    $rv = $obj->addLiterals(qw(/etc/foo.conf));

Adds more literal strings to the object that are detainted.  Returns false if 
any strings fail to detaint.  All undefined or zero-length strings are 
silently removed.

=head2 consolidate

    $obj->consolidate;

This method removes redundant entries and lexically sorts the contents of
the glob.

=head2 exists

    @existing       = $obj->exists;

This object method returns a list of all entries that currently exist on the
filesystem.  In the case of a symlink that exists but links to a nonexistent
file it returns the symlink as well.

=head2 readable

    @readable       = $obj->readable;

This method returns a list of all entries that are currently readable by
the effective user.  In the case of a symlink it returns the symlink only if
the target of the symlink is readable, just as a normal B<stat> or B<-r>
function would.

=head2 writable

    @writable       = $obj->writable;

This method returns a list of all entries that are currently writable by
the effective user.  In the case of a symlink it returns the symlink only if
the target of the symlink is writable, just as a normal B<stat> or B<-w>
function would.

=head2 executable

    @executable     = $obj->executable;

This method returns a list of all entries that are currently executable by
the effective user.  In the case of a symlink it returns the symlink only if
the target of the symlink is executable, just as a normal B<stat> or B<-x>
function would.

=head2 owned

    @owned          = $obj->owned;

This method returns a list of all entries that are currently owned by
the effective user.  In the case of a symlink it returns the symlink only if
the target of the symlink is owned, just as a normal B<stat> or B<-o>
function would.

=head2 directories

    @directories    = $obj->directories;

This method returns a list of all the directories.  In the case of a
symlink it returns the symlink if the target of the symlink is a directory,
just as a normal B<stat> or B<-d> function would.

=head2 files

    @files          = $obj->files;

This method returns a list of all the files.  In the case of a
symlink it returns the symlink if the target of the symlink is a file,
just as a normal B<stat> or B<-f> function would.

=head2 symlinks

    @symlinks       = $obj->symlinks;

This method returns a list of all the symlinks.

=head2 pipes

    @pipes          = $obj->pipes;

This method returns a list of all the pipes.  In the case of a
symlink it returns the symlink if the target of the symlink is a pipe,
just as a normal B<stat> or B<-p> function would.

=head2 sockets

    @sockets        = $obj->sockets;

This method returns a list of all the sockets.  In the case of a
symlink it returns the symlink if the target of the symlink is a socket,
just as a normal B<stat> or B<-S> function would.

=head2 blockDevs

    @blockDevs      = $obj->blockDevs;

This method returns a list of all the block device nodes.  In the 
case of a symlink it returns the symlink if the target of the symlink is a 
block device node, just as a normal B<stat> or B<-b> function would.

=head2 charDevs

    @charDevs       = $obj->charDevs;

This method returns a list of all the character device nodes.  In the 
case of a symlink it returns the symlink if the target of the symlink is a 
character device node, just as a normal B<stat> or B<-c> function would.

=head2 recurse

    $obj->recurse;
    $obj->recurse(1);
    $obj->recurse(1, 1);

This method with recursively load all filesystem entries underneath any
directories already listed in the object.  It returns true upon completion, or
false if any errors occurred (such as Permission Denied).

Two optional boolean arguments can be passed to it:

  Option1:        Follow Symlinks
  Option2:        Include "Hidden" directories

Both options are false by default.  If Option1 (Follow Symlinks) is true any
symlinks pointing to directories will be recursed into as well.  Option2 in
its default false setting excludes dot files or directories just as normal
shell expansion would.  Setting it to true causes it to include (and recurse
into) hidden files and directories.

=head1 DEPENDENCIES

=over

=item o

L<Carp>

=item o

L<Errno>

=item o

L<Fcntl>

=item o

L<File::Glob>

=item o

L<Paranoid>

=item o

L<Paranoid::Debug>

=back

=head1 BUGS AND LIMITATIONS 

=head1 AUTHOR 

Arthur Corliss (corliss@digitalmages.com)

=head1 LICENSE AND COPYRIGHT

This software is free software.  Similar to Perl, you can redistribute it
and/or modify it under the terms of either:

  a)     the GNU General Public License
         <https://www.gnu.org/licenses/gpl-1.0.html> as published by the 
         Free Software Foundation <http://www.fsf.org/>; either version 1
         <https://www.gnu.org/licenses/gpl-1.0.html>, or any later version
         <https://www.gnu.org/licenses/license-list.html#GNUGPL>, or
  b)     the Artistic License 2.0
         <https://opensource.org/licenses/Artistic-2.0>,

subject to the following additional term:  No trademark rights to
"Paranoid" have been or are conveyed under any of the above licenses.
However, "Paranoid" may be used fairly to describe this unmodified
software, in good faith, but not as a trademark.

(c) 2005 - 2020, Arthur Corliss (corliss@digitalmages.com)
(tm) 2008 - 2020, Paranoid Inc. (www.paranoid.com)

