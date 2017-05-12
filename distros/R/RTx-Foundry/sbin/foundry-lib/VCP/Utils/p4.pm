package VCP::Utils::p4 ;

=head1 NAME

VCP::Utils::p4 - utilities for dealing with the p4 command

=head1 SYNOPSIS

   use base qw( ... VCP::Utils::p4 ) ;

=head1 DESCRIPTION

A mix-in class providing methods shared by VCP::Source::p4 and VCP::Dest::p4,
mostly wrappers for calling the p4 command.

=cut

@EXPORT_OK = qw( underscorify_name );
@ISA = qw( Exporter );
use Exporter;

use strict ;
use Carp;

use IPC::Run;
use VCP::Debug qw( :debug :profile ) ;
use VCP::Logger qw( lg pr );
use VCP::Utils qw( empty shell_quote xchdir );

use constant use_p4_api_if_present => $ENV{VCPP4API} ? 1 : 0;
use constant have_p4_api => use_p4_api_if_present && eval "require P4::Client; require P4::UI";


=head1 METHODS

=over

=item repo_client

The p4 client name. This is an accessor for a data member in each class.
The data member should be part of VCP::Utils::p4, but the fields pragma
does not support multiple inheritance, so the accessor is here but all
derived classes supporting this accessor must provide for a key named
"P4_REPO_CLIENT".

=cut

sub repo_client {
   my $self = shift ;

   $self->{P4_REPO_CLIENT} = shift if @_ ;
   return $self->{P4_REPO_CLIENT} ;
}


=item p4

   $self->p4( [ "edit", $fn ] );
   $self->p4( [ "change", "-i" ], \$info_for_p4_stdin );

Calls the p4 command with the appropriate user, client, port, and password.

=cut

## NOTE: hacking in p4 API stuff for now, will need to refactor and
## clean it all up a lot when it works.
my $client;
my $ui;
my $input_data;
my $output_data;
my $error_data;
{
   package VCP::P4::UI;

   use VCP::Logger qw( lg );

   @VCP::P4::UI::ISA = qw( P4::UI );

   sub InputData {
      return $$input_data;
   }

   sub OutputText {
      lg "P4 out: ", $_[1];
      $$output_data .= $_[1] if defined $output_data;
   }

   sub OutputStat {
# use BFD;d"STAT!!", $_[1];
   }

   sub OutputInfo {
      $$output_data .= $_[2] . "\n" if defined $output_data;
   }

   sub OutputError {
      lg "p4 error: ", $_[1];
      $$error_data .= $_[1] if defined $error_data;
   }
}


sub p4 {
   my $self = shift ;

   my $p4_command = "";
   if ( profiling ) {
      profile_group ref( $self ) . " p4 ";
      for( @{$_[0]} ) {
         unless ( /^-/ ) {
            $p4_command = $_;
            last;
         }
      }
   }
   local $VCP::Debug::profile_category = ref( $self ) . " p4 $p4_command"
      if profiling;


   unless ( have_p4_api ) {
       local $ENV{P4PASSWD} = $self->repo_password if defined $self->repo_password ;
       unshift @{$_[0]}, '-p', $self->repo_server  if defined $self->repo_server ;
       unshift @{$_[0]}, '-c', $self->repo_client  if defined $self->repo_client ;
       unshift @{$_[0]}, '-u', $self->repo_user    if defined $self->repo_user ;

       ## localizing this was giving me some grief.  Can't recall what.
       ## PWD must be cleared because, unlike all other Unix utilities I
       ## know of, p4 looks at it and bases it's path calculations on it.
       my $tmp = $ENV{PWD} ;
       delete $ENV{PWD} ;

       my $args = shift ;

       $self->run_safely( [ "p4", @$args ], @_ ) ;
       $ENV{PWD} = $tmp if defined $tmp ;
    }
    else {
       unless ( $client ) {
          pr "using p4 binary API";
          $client = P4::Client->new;

          $client->DebugLevel( debugging );
          $client->SetPort  ( $self->repo_server )
             if defined $self->repo_server;
          $client->Init() or die( "Failed to connect to Perforce Server" );

          $ui     = VCP::P4::UI->new;
       }

       my @cmd = @{shift()};

       profile_group ref( $self ) . " p4api " if profiling;
       profile_start ref( $self ) . " p4api " . $cmd[0] if profiling;

       $client->SetPassword( $self->repo_password ) if defined $self->repo_password;
       $client->SetClient( $self->repo_client ) if defined $self->repo_client;
       $client->SetUser  ( $self->repo_user   ) if defined $self->repo_user;

       lg "\$ p4api ", join " ", shell_quote( @cmd );
       ( $input_data, $output_data, $error_data ) = @_;
       $client->Run( $ui, @cmd );
       profile_end ref( $self ) . " p4api " . $cmd[0] if profiling;
    }
}


=item p4_x

Run p4 -x, feeding args to STDIN.

=cut

sub p4_x {
   my $self = shift;
   my @cmd = @{shift()};
   unless ( have_p4_api ) {
      $self->p4( [ "-x", "-", @cmd ], @_ );
   }
   else {

      if ( ref $_[0] eq "ARRAY" ) {
         my $in = $_[0];
         $_[0] = undef;
         push @cmd, map { my $s = $_; chomp $s; $self->command_chdir . "/" . $s } @{$in};
      }
else{
}

      $self->p4( \@cmd, @_ );
   }
}


=item parse_p4_form

   my %form = $self->parse_p4_form( $form );
   my %form = $self->parse_p4_form( \@command_to_emit_form );

Parses a p4 form and returns a list containing the form's data elements
in the order that they were accumulated.  This is suitable for initializing
a hash if order's not important, or an array if it is.

You can pass the form in verbatim, or a reference to a command to run
to get the form.  If the first parameter is an ARRAY reference, all
parameters will be passed to C<$self->p4> with stdout redirected to
a temporary variable.

Multiline fields will have trailing C<\n>s in the data, single-line fields
won't.  All fields have leading spaces on each line removed.

Comments are tagged with a field name of "#", blank (containing only spaces
if that) are tagged with a " ".  This is to allow accurate reproduction
of the file if reemitted.

NOTE: This does not implement 100% compatible p4 forms parsing; it should
be upwards compatible and one day we should implement full forms parsing.

=cut

## this simulates the real C++ tokenizer built in to p4.  That tokenizes
## p4 forms with a state machine that knows about quoting, text blocks,
## etc.  Some layer above the parser informs the parser about whether or
## not the current field is a text block.  This parser tries to emulate that
## tokenizer's behavior without implementing a low level state machine.

sub parse_p4_form {
   my $self = shift;

   my $form;
   
   if ( ref $_[0] eq "ARRAY" ) {
      $self->p4( $_[0], undef, \$form, @_[1..$#_] )
   }
   else {
      $form = shift;
   }

   my @lines = split /\r?\n/, $form;

   my @entries;
   my $cat;  ## Set when catenating lines together in a comment or value
   my $blanks = 0;

   for ( @lines ) {
      ++$blanks, next if /^$/;
      next if /^#/;

#      if ( s/^\s*#\s*(.*)/$1/ ) {
#         $blanks = 0;
#         unless ( @entries && $entries[-2] eq "#" ) {
#            chomp $entries[-1] if $cat;
#            push @entries, ( "#", "" );
#            $cat = 1;
#         }
#      }
#      elsif ( /^([A-Za-z]+):[ \t]*(?:(\S.*))?\z/ ) {
      if ( /^([A-Za-z]+):[ \t]*(?:(\S.*))?\z/ ) {
         chomp $entries[-1] if $cat;
         $cat = undef;
         $blanks = 0;

         push @entries, $1;
         if ( defined $2 ) {
            local $_ = $2;
            s/(^|[ \t]+)#.*//;
            push @entries, length $_ ? "$_\n" : "";
         }
         else {
            push @entries, "";
         }
         $cat = 1;
         next;
      }

      if ( $cat ) {
         s/^\s//;  ## This may be too general.  May need to trim the same
                    ## number of characters from each line.
         $entries[-1] .= "\n" x $blanks;
         $blanks = 0;
         s/(^|[ \t]+)#.*//;
         $entries[-1] .= $_ . "\n";
      }
      elsif ( ! length ) {
         next;
      }
      else {
         ## We warn instead of dieing in case p4 can output things we don't
         ## expect.  TODO: This could be bad, change to die() with a
         ## syntax error.
         pr "ignoring '$_' from p4 output\n";
      }
   }
   chomp $entries[-1] if $cat;

   return @entries;
}


=item build_p4_form

   my $form = $self->build_p4_form( @form_fields );
   my $form = $self->build_p4_form( %form_fields );
   $self->build_p4_form( ..., \@command_to_emit_form );

Builds a p4 form and either returns it or submits it to the indicated command.

=cut

sub build_p4_form {
   my $self = shift;

   my @form;
   
   while ( @_ ) {
      last if ref $_[0] eq "ARRAY";  ## rest is a command.
      my ( $name, $value ) = ( shift, shift );

      if ( $name eq "#" ) {
         $value =~ s/^/# /mg;
         chomp $value;
         push @form, $value, "\n\n";
         next;
      }

      push @form, ( $name, ":" );

      if ( $value =~ tr/\n// ) {
         push @form, "\n";
         $value =~ s/^(?!$)/\t/gm;
         chomp $value;
         push @form, $value, "\n\n";
      }
      else {
         push @form, ( " ", $value, "\n\n" );
      }
   }

   my $form = join "", @form;
   @form = ();

   $self->p4( $_[0], undef, \$form, @_[1..$#_] ) if @_;

   return $form;
}


=item parse_p4_repo_spec

Calls $self->parse_repo_spec, the post-processes the repo_user in to a user
name and a client view. If the user specified no client name, then a client
name of "vcp_tmp_$$" is used by default.

This also initializes the client to have a mapping to a working directory
under /tmp, and arranges for the current client definition to be restored
or deleted on exit.

=cut

sub parse_p4_repo_spec {
   my $self = shift ;
   my ( $spec ) = @_ ;

   $self->parse_repo_spec( $spec ) ;

   $self->repo_id( "p4:" . $self->repo_server );
};


sub set_up_p4_user_and_client {
   my $self = shift ;

   my ( $user, $client ) ;
   ( $user, $client ) = $self->repo_user =~ m/([^()]*)(?:\((.*)\))?/
      if defined $self->repo_user ;
   $client = "vcp_tmp_$$" if empty $client ;

   $self->repo_user( $user ) ;
   $self->repo_client( $client ) ;

   if ( $self->can( "min" ) ) {
      my $filespec = $self->repo_filespec ;

      ## If a change range was specified, we need to list the files in
      ## each change.  p4 doesn't allow an @ range in the filelog command,
      ## for wataver reason, so we must parse it ourselves and call lots
      ## of filelog commands.  Even if it did, we need to chunk the list
      ## so that we don't consume too much memory or need a temporary file
      ## to contain one line per revision per file for an entire large
      ## repo.
      my ( $name, $min, $comma, $max ) ;
      ( $name, $min, $comma, $max ) =
	 $filespec =~ m/^([^@]*)(?:@(-?\d+)(?:(\D|\.\.)((?:\d+|#head)))?)?$/i
	 or die "Unable to parse p4 filespec '$filespec'\n";

      die "'$comma' should be ',' in change_id range in '$filespec'\n"
	 if defined $comma && $comma ne ',' ;

      if ( ! defined $min ) {
	 $min = 1 ;
	 $max = '#head' ;
      }

      if ( ! defined $max ) {
	 $max = $min ;
      }
      elsif ( lc( $max ) eq '#head' ) {
	 $self->p4( [qw( counter change )], undef, \$max ) ;
	 chomp $max ;
      }

      if ( $max == 0 ) {
         ## TODO: make this a "normal exit"
         die "Current change number is 0, no work to do\n";
      }

      if ( $min < 0 ) {
	 $min = $max + $min ;
      }

      $self->repo_filespec( $name ) ;
      $self->min( $min ) ;
      $self->max( $max ) ;
   }
}


=item init_p4_view

   $self->init_p4_view

Borrows or creates a client with the right view.  Only called from
VCP::Dest::p4, since VCP::Source::p4 uses non-view oriented commands.

=cut

sub init_p4_view {
   my $self = shift ;

   my $client = $self->repo_client ;

   $self->repo_client( undef ) ;
   my $client_exists = grep $_ eq $client, $self->p4_clients ;
   debug "client '$client' exists" if debugging && $client_exists;
   $self->repo_client( $client ) ;
   my $client_spec = $self->p4_get_client_spec ;
## work around a wierd intermittant failure on Win32.  The
## Options: line *should* end in nomodtime normdir
## instead it looks like:
##
## Options:	noallwrite noclobber nocompress unlocked nomÔ+
##
## but only occasionally!
$client_spec = $self->p4_get_client_spec
    if $^O =~ /Win32/ && $client_spec =~ /[\x80-\xFF]/;

   $self->queue_p4_restore_client_spec( $client_exists ? $client_spec : undef );

   my $p4_spec = $self->repo_filespec ;
   $p4_spec = "//..." if empty $p4_spec;
   $p4_spec =~ s{(/(\.\.\.)?)?$}{/...} ;
   my $work_dir = $self->work_root ;

   $client_spec =~ s{^Root.*}{Root:\t$work_dir}m ;
   $client_spec =~ s{^View.*}{View:\n\t$p4_spec\t//$client/...\n}ms ;
   debug "using client spec", $client_spec if debugging ;
   $client_spec =~ s{^(Options:.*)}{$1 nocrlf}m 
      if $^O =~ /Win32/ ;
   $client_spec =~ s{^LineEnd.*}{LineEnd:\tunix}mi ;

   debug "using client spec", $client_spec if debugging ;

   $self->p4_set_client_spec( $client_spec ) ;

}

=item p4_clients

Returns a list of known clients.

=cut

sub p4_clients {
   my $self = shift ;

   my $clients ;
   $self->p4( [ "clients", ], undef, \$clients ) ;
   return map { /^Client (\S*)/ ; $1 } split /\n/m, $clients ;
}

=item p4_get_client_spec

Returns the current client spec for the named client. The client may or may not
exist first, grep the results from L</p4_clients> to see if it already exists.

=cut

sub p4_get_client_spec {
   my $self = shift ;
   my $client_spec ;
   $self->p4( [ "client", "-o" ], undef, \$client_spec ) ;
   return $client_spec ;
}


=item queue_p4_restore_client_spec

   $self->queue_p4_restore_client_spec( $client_spec ) ;

Saves a copy of the named p4 client and arranges for it's restoral on exit
(assuming END blocks run). Used when altering a user-specified client that
already exists.

If $client_spec is undefined, then the named client will be deleted on
exit.

Note that END blocks may be skipped in certain cases, like coredumps,
kill -9, or a call to POSIX::exit().  None of these should happen except
in debugging, but...

=cut

my @client_backups ;
my @p4ds_to_kill;

END {
   my $child_exit;
   {
      local $?;  ## Protect this; we're about to run a child process and
                 ## we want to exit with the appropriate value.
      for ( @client_backups ) {
         my ( $object, $name, $spec ) = @$_ ;
         my $tmp_name = $object->repo_client ;
         $object->repo_client( $name ) ;
         if ( defined $spec ) {
            $object->p4_set_client_spec( $spec ) ;
         }
         else {
            my $out ;
            $object->p4( [ "client", "-df", $object->repo_client ], undef, \$out);
            pr "unexpected stdout from p4:\np4: ", $out
               unless $out =~ /^Client\s.*\sdeleted./ ;
            $child_exit = $?;
         }
         $object->repo_client( $tmp_name ) ;
         $_ = undef ;
      }
      @client_backups = () ;
   }
   $? = $child_exit if $child_exit && ! $?;
   __PACKAGE__->kill_all_vcp_p4ds;
}


sub queue_p4_restore_client_spec {
   my $self = shift ;
   my ( $client_spec ) = @_ ;
   push @client_backups, [ $self, $self->repo_client, $client_spec ] ;
}

=item p4_set_client_spec

   $self->p4_set_client_spec( $client_spec ) ;

Writes a client spec to the repository.

=cut


sub p4_set_client_spec {
   my $self = shift ;
   my ( $client_spec ) = @_ ;

   ## Capture stdout so it doesn't show through to user.
   $self->p4( [ "client", "-i" ], \$client_spec, \my $out ) ;

   die "unexpected stdout from p4:\np4: ", $out
      unless $out =~ /^Client\s.*\ssaved.$/ ;
}

=item run_p4d

Runs a p4d instance in the directory indicated by repo_server (use a directory
path in place of a host name).  If repo_server contains a port, that port
will be used, otherwise a random port will be used (and placed back in to
repo_server so the p4 client can find it).

Dies unless the directory exists and contains files matching db.* (to
help prevent unexpected initting of empty directories).

=cut
   

sub run_p4d {
   my $self = shift;

   my ( $dir, $port ) = split ":", $self->repo_server, 2;

   die "Can't run p4d in non-existant directory '$dir'\n"
      unless -e $dir;

   die "Can't run p4d in non-directory '$dir'\n"
      unless -d $dir;

    my @files;

   @files =  glob "$dir/db.*" if -d $dir;

   die "cannot --run-p4d on dir '$dir' with no 'db.*' files\n"
      unless @files;

   $port = $self->launch_p4d( $dir, $port );
   $self->repo_server( "localhost:$port" );
}



=item launch_p4d

VCP can use its own p4d, this sub is used to launch it and queue its
demise when the program exits.

The $p4root argument is required.  The $p4port is optional; if
undefined, a random p4 port is chosen (if the random port is already in
use, successive random ports will be chosen up to 10 times until an
unused port is found)

The return value is the p4 port.

TODO: Make VCP.pm kill things when the transfer is over and only use
END{} subs if that fails.

=cut

sub launch_p4d {
   { my $self = shift; }
   my ( $p4root, $p4port ) = @_;

   require VCP::Utils;
   require IPC::Run;

   my $h ;
   my $pick_a_port = ! defined $p4port;
   my $launch_attempts = 0;
   my $p4d_detected;

   while (1) {
      ++$launch_attempts;

      # use a random port if the caller hasn't provided one
      while ( ! defined $p4port ) {
         ## 30_000 is because I vaguely recall some TCP stack that had
         ## problems with listening on really high ports.
         ## 2048 is because I vaguely recall
         ## that some OS required root privs up to 2047 instead of 1023.
         $p4port = ( rand( 65536 ) % 30_000 ) + 2048 ;
         $p4port = undef if $p4port == 1666;
      }

      my @p4d = ( "p4d", "-f", "-r", $p4root, "-p", $p4port ) ;
      pr shell_quote @p4d;

      ## Ok, this is wierd: we need to fork & run p4d in foreground mode so that
      ## we can capture it and kill it later.  There doesn't seem to be
      ## the equivalent of a 'p4d.pid' file. If we let it daemonize, then I
      ## don't know how to get it's PID.

      $h = IPC::Run::start( \@p4d, \undef, \my $p4d_output, '2>&1' );

      ## Wait for at least one line to come in so that we don't run
      ## the p4d detector prematurely.
      $h->pump while $h->pumpable && $p4d_output !~ /\n/;

      ## Wait for p4d to start.  'twould be better to wait for P4PORT to
      ## be seen or some .pid file to appear.
      my $timeout = 1;
      my @p4d_detector = ( "p4", "-p", $p4port, "info" );

      while ( $h->pumpable ) {
         $h->pump_nb;  ## Gather any p4d output available
         last if $p4d_output =~ /listen.*failed/i;

         IPC::Run::run \@p4d_detector, \undef, \my $out, \my $err;

         $p4d_detected = 1, last if $out =~ /^Server version/m;

         die $out, $err unless $err =~ /Connect to server failed/;

         if ( $timeout > 10 ) {
            eval { $h->finish; 1 } or pr $@;
            confess "p4d failed to start:\n", $p4d_output;
         }

         select undef, undef, undef, $timeout;

         $timeout *= 2;
      }
    
      last if $p4d_detected;

      ## The child process will have died if the port is taken or due
      ## to other errors.
      $h->finish;

      unless (
             $pick_a_port
             && $p4d_output =~ /listen.*failed/
             && $launch_attempts < 10
      ) {
         $p4d_output =~ s/^/    /mg;
         die 
            "p4d failed to start (made $launch_attempts attempts):\n",
            "    \$ ", VCP::Utils::shell_quote( @p4d ), "\n",
            $p4d_output;
      }
      lg $p4d_output;
      undef $p4port;
   }

   push @{p4ds_to_kill}, $h;

   return $p4port;
}


=item kill_all_vcp_p4ds

Kills all p4ds that have been started by this VCP process.

=cut

sub kill_all_vcp_p4ds {
   local $?;
   while ( @p4ds_to_kill ) {
      my $h = shift @p4ds_to_kill;
      pr "shutting down p4d\n";
      eval { $h->kill_kill; 1 } or pr "$@ killing p4d\n";
   }
}


=item underscorify_name

Converts special characters ('#', '@', whitespace and non-printing character
codes) in branch, label, and client names in to other symbols.

   "a " => "a_20_"

NOTE: I have not been able to find a description of the set of legal p4
names (namelength, character set, etc).  This is purely a first attempt,
if you have details on this, please let me know.

=cut

sub underscorify_name {
   my @out = @_;
   for ( @out ) {
      s/([#\@[:^graph:]])/sprintf( "_%02x_", ord $1 )/ge;
   }

   wantarray ? @out : @out > 1 ? confess "Returning multiple tags in scalar context" : $out[0];
}


=back

=head1 COPYRIGHT

Copyright 2000, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=cut

1 ;
