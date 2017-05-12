#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2008-2013 -- leonerd@leonerd.org.uk

package Net::Async::FTP;

use strict;
use warnings;
use base qw( IO::Async::Stream );
IO::Async::Stream->VERSION( '0.59' );

use Carp;

our $VERSION = '0.08';

use Socket qw( AF_INET SOCK_STREAM inet_aton pack_sockaddr_in );

my $CRLF = "\x0d\x0a";

=head1 NAME

C<Net::Async::FTP> - use FTP with C<IO::Async>

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::FTP;

 my $loop = IO::Async::Loop->new();

 my $ftp = Net::Async::FTP->new();
 $loop->add( $ftp );

 $ftp->connect(
    host => "ftp.example.com",
 )->then( sub {
    $ftp->login(
       user => "username",
       pass => "password",
    )
 })->then( sub {
    $ftp->retr(
       path => "README.txt",
    )
 })->then( sub {
    my ( $data ) = @_;
    print "README.txt says:\n";
    print $data;
 })->get;

=head1 DESCRIPTION

This object class implements an asynchronous FTP client, for use in
L<IO::Async>-based programs.

The code in this module is not particularly complete. It contains a minimal
implementation of a few FTP commands, not even the full minimal set the RFC
suggests all clients should support. I am releasing it anyway, because it is
still useful as it stands, and could easily support extra commands being added
if anyone would find it useful.

The (undocumented) C<do_command()> method provides a generic base for the
currently-implemented commands, and would be the basis for new commands.

As they say so often in the open-source world; Patches Welcome.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $ftp = Net::Async::FTP->new( %args )

This function returns a new instance of a C<Net::Async::FTP> object. As it is
a subclass of C<IO::Async::Stream> its constructor takes any arguments for
that class.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   $self->{req_queue} = [];

   return $self;
}

sub on_read
{
   my $self = shift;
   my ( $buffref, $closed ) = @_;

   $self->_do_req_queue;

   if( my $item = shift @{ $self->{req_queue} } ) {
      return $item->{on_read};
   }

   return 0 unless $$buffref =~ s/^(.*)$CRLF//;
   print STDERR "Unexpected incoming line $1\n";
   return 1;
}

=head1 METHODS

=cut

=head2 $ftp->connect( %args ) ==> ()

Connects to the FTP server. Takes the following arguments:

=over 8

=item host => STRING

Hostname of the server

=item service => STRING or INT

Optional. Service name or port number to connect to. If not supplied, will use
C<ftp>.

=item family => INT

Optional. Socket family to use. Will default to whatever C<getaddrinfo()>
returns if not supplied.

=item on_connected => CODE

Optional when returning a Future. Continuation to call when connection is
successful.

 $on_connected->()

=item on_error => CODE

Optional when returning a Future. Continuation to call on an error.

 $on_error->( $message )

=back

=cut

sub connect
{
   my $self = shift;
   my %args = @_;

   my $on_connected = $args{on_connected} or defined wantarray or croak "Expected 'on_connected'";
   my $on_error     = $args{on_error}     or defined wantarray or croak "Expected 'on_error'";

   my $f = $self->SUPER::connect(
      service => "ftp",
      %args,
   )->then( sub {
      # TODO: This is a bit messy. Install an initial on_read handler for
      # the connect messages, by sending an "empty string" command
      $self->do_command( undef, [ 220 ] );
   });

   $f->on_done( $on_connected ) if $on_connected;
   $f->on_fail( $on_error )     if $on_error;

   return $f if defined wantarray;
   $f->on_ready( sub { undef $f } ); # Intentional cycle
}

my %NUMTYPES = (
   1 => "info",
   2 => "ok",
   3 => "more",
   4 => "err",
   5 => "err",
);

sub _build_future_onread
{
   my $self = shift;
   my ( $command, $f, $accept, %continue ) = @_;

   my @extralines;
   my %accept = map { $_ => 1 } @$accept;

   sub {
      my ( $self, $buffref, $closed ) = @_;

      return 0 unless $$buffref =~ s/^(.*)$CRLF//;
      my $line = $1;

      if( $line =~ m/^(\d{3}) +(.*)$/ ) {
         my ( $number, $message ) = ( $1, $2 );
         my $numtype = $NUMTYPES{substr($number, 0, 1)};

         if( $accept{$number} || $accept{$numtype} ) {
            if( $numtype eq "info" ) {
               print STDERR "TODO: info $number\n";
            }
            else {
               $f->done( $number, $message, @extralines );
               return undef;
            }
         }
         elsif( my $cb = $continue{$number} ) {
            return $cb->( $f, $number, $message );
         }
         elsif( $numtype eq "err" ) {
            $f->fail( $message, ftp => $number );
         }
         else {
            print STDERR "Unexpected incoming $number\n";
         }
      }
      elsif( $line =~ m/^(\d{3})-(.*)$/ ) {
         push @extralines, $2;
      }
      else {
         print STDERR "Unparseable incoming line $line\n";
      }

      return 1;
   };
}

sub do_command
{
   my $self = shift;
   my ( $command, $accept, %continue ) = @_;

   my $f = $self->loop->new_future;
   my $on_read = $self->_build_future_onread( $command, $f, $accept, %continue );

   my $queue = $self->{req_queue};
   push @$queue, { command => $command, on_read => $on_read };

   $self->_do_req_queue;

   return $f;
}

sub _do_req_queue
{
   my $self = shift;

   my $queue = $self->{req_queue};
   return unless @$queue;

   my $item = $queue->[0];

   if( defined $item->{command} ) {
      $self->write( "$item->{command}$CRLF" );
      undef $item->{command};
   }
}

sub _connect_dataconn
{
   my $self = shift;
   my ( $on_conn ) = @_;

   $self->do_command( "PASV", [],
      227 => sub {
         my ( $f, $num, $message ) = @_;
         $message =~ m/\((\d+,\d+,\d+,\d+,\d+,\d+)\)/ or
            return $f->fail( "Did not find (ip,port) in message $message", ftp => $num, $message );

         my ( $ipA, $ipB, $ipC, $ipD, $portHI, $portLO ) = split( m/,/, $1 );
         my $ip   = "$ipA.$ipB.$ipC.$ipD";
         my $port = $portHI*256 + $portLO;

         my $sinaddr = pack_sockaddr_in( $port, inet_aton( $ip ) );

         my $loop = $self->get_loop;
         my $connect_f = $loop->connect(
            addr => [ AF_INET, SOCK_STREAM, 0, $sinaddr ],
         );
         $connect_f->on_fail( $f );

         return $on_conn->( $f, $connect_f );
      },
   );
}

# Now some convenient wrappers for classes of command

sub _do_command_collect_dataconn
{
   my $self = shift;
   my ( $command ) = @_;

   $self->_connect_dataconn(
      sub {
         my ( $f, $connect_f ) = @_;

         my $data;
         my $dataconn = IO::Async::Stream->new(
            on_read => sub {
               my ( $self, $buffref, $closed ) = @_;
               return 0 unless $closed;
               $data = $$buffref;
               $self->close;
               return 0;
            },
         );
         $self->add_child( $dataconn );

         $connect_f->on_done( sub {
            $dataconn->configure( read_handle => $_[0] );
         });
         $connect_f->on_ready( sub { undef $connect_f } ); # Intentional cycle

         $self->write( "$command$CRLF" );

         my $cmd_f = $f->new;
         my $on_read = $self->_build_future_onread( $command, $cmd_f, [ 226 ] );

         my $done_f = Future->needs_all( $dataconn->new_close_future, $cmd_f )
            ->on_done( sub { $f->done( $data ) })
            ->on_fail( $f );
         $f->on_cancel( $done_f );

         return $on_read;
      },
   );
}

sub _do_command_send_dataconn
{
   my $self = shift;
   my ( $command, $data ) = @_;

   $self->_connect_dataconn(
      sub {
         my ( $f, $connect_f ) = @_;

         my $dataconn = IO::Async::Stream->new;
         $self->add_child( $dataconn );

         $connect_f->on_done( sub {
            $dataconn->configure( write_handle => $_[0] );
         });
         $connect_f->on_ready( sub { undef $connect_f } ); # Intentional cycle

         $self->write( "$command$CRLF" );

         my $cmd_f = $f->new;
         my $on_read = $self->_build_future_onread( $command, $cmd_f, [ 226 ],
            150 => sub {
               $dataconn->write( $data );
               $dataconn->close_when_empty;
               return 1;
            },
         );

         my $done_f = Future->needs_all( $dataconn->new_close_future, $cmd_f )
            ->on_done( sub { $f->done } )
            ->on_fail( $f );
         $f->on_cancel( $done_f );

         return $on_read;
      },
   );
}

=head2 $ftp->login( %args ) ==> ()

Sends a C<USER> and optionally C<PASS> command. Takes the following arguments:

=over 8

=item user => STRING

Username for the C<USER> command

=item pass => STRING

Password for the C<PASS> command if required

=item on_login => CODE

Optional when returning a future. Continuation to invoke on successful login.

 $on_login->()

=item on_error => CODE

Optional when returning a future. Continuation to invoke on an error.

 $on_error->( $message )

=back

=cut

sub login
{
   my $self = shift;
   my %args = @_;

   my $user = $args{user} or croak "Expected 'user'";

   my $on_login = $args{on_login} or defined wantarray or croak "Expected 'on_login'";
   my $on_error = $args{on_error} or defined wantarray or croak "Expected 'on_error'";

   my $f = $self->do_command( "USER $user", [ 331 ] )
      ->then( sub {
         exists $args{pass} or return $on_error->( "No password" );
         $self->do_command( "PASS $args{pass}", [ 230 ] )
      });

   $f->on_done( $on_login ) if $on_login;
   $f->on_fail( $on_error ) if $on_error;

   return $f if defined wantarray;
   $f->on_ready( sub { undef $f } ); # Intentional cycle
}

=head2 $ftp->rename( %args ) ==> ()

Renames a file on the remote server. Takes the following arguments

=over 8

=item oldpath => STRING

Path to file to rename

=item newpath => STRING

Desired new path for the file

=item on_done => CODE

Optional when returning a future. Continuation to invoke on success.

 $on_done->()

=item on_error => CODE

Optional. Continuation to invoke on an error.

 $on_error->( $message )

=back

=cut

sub rename
{
   my $self = shift;
   my %args = @_;

   my $oldpath = $args{oldpath};
   defined $oldpath or croak "Expected 'oldpath'";

   my $newpath = $args{newpath};
   defined $newpath or croak "Expected 'newpath'";

   my $on_done = $args{on_done} or defined wantarray or croak "Expected 'on_done'";

   my $on_error = $args{on_error};
   $on_error ||= sub { die "Error $_[0] during rename" } if !defined wantarray;

   my $f = $self->do_command( "RNFR $oldpath", [ 350 ] )
      ->then( sub {
         $self->do_command( "RNTO $newpath", [ 'ok' ] )
      });

   $f->on_done( $on_done  ) if $on_done;
   $f->on_fail( $on_error ) if $on_error;

   return $f if defined wantarray;
   $f->on_ready( sub { undef $f } ); # Intentional cycle
}

=head2 $ftp->dele( %args ) ==> ()

Deletes a file on the remote server. Takes the following arguments

=over 8

=item path => STRING

Path to file to delete

=item on_done => CODE

Optional when returning a future. Continuation to invoke on success.

 $on_done->()

=item on_error => CODE

Optional. Continuation to invoke on an error.

 $on_error->( $message )

=back

=cut

sub dele
{
   my $self = shift;
   my %args = @_;

   my $path = $args{path};
   defined $path or croak "Expected 'path'";

   my $on_done = $args{on_done} or defined wantarray or croak "Expected 'on_done'";

   my $on_error = $args{on_error};
   $on_error ||= sub { die "Error $_[0] during RETR" } if !defined wantarray;

   my $f = $self->do_command( "DELE $path", [ 'ok' ] );

   $f->on_done( $on_done  ) if $on_done;
   $f->on_fail( $on_error ) if $on_error;

   return $f;
}

=head2 $ftp->list( %args ) ==> $list

Runs a C<LIST> command on a path on the remote server; which requests details
on the file, or contents of the directory. Takes the following arguments

=over 8

=item path => STRING

Path to C<LIST>

=item on_list => CODE

Optional when returning a future. Continuation to invoke on success. Is passed
a list of lines from the C<LIST> result in a single string.

 $on_list->( $list )

=item on_error => CODE

Optional. Continuation to invoke on an error.

 $on_error->( $message )

=back

The C<list_parsed> method may be easier to use as it parses the lines.

=cut

sub list
{
   my $self = shift;
   my %args = @_;

   my $path = $args{path};

   my $on_list = $args{on_list} or defined wantarray or croak "Expected 'on_list'";

   my $on_error = $args{on_error};
   $on_error ||= sub { die "Error $_[0] during LIST" } if !defined wantarray;

   my $f = $self->_do_command_collect_dataconn(
      "LIST" . ( defined $path ? " $path" : "" ),
   );

   $f->on_done( $on_list  ) if $on_list;
   $f->on_fail( $on_error ) if $on_error;

   return $f;
}

=head2 $ftp->list_parsed( %args ) ==> @list

Runs a C<LIST> command on a path on the remote server; and parse the result
lines. Takes the following arguments

=over 8

=item path => STRING

Path to C<LIST>

=item on_list => CODE

Optional when returning a future. Continuation to invoke on success. Is passed
a list of files from the C<LIST> result, one line per element.

 $on_list->( @list )

=item on_error => CODE

Optional. Continuation to invoke on an error.

 $on_error->( $message )

=back

The C<@list> array will be passed a list of C<HASH> references, each formed
like

=over 8

=item name => STRING

The filename

=item type => STRING

A single character; C<f> for files, C<d> for directories

=item size => INT

The size in bytes

=item mtime => INT

The item's last modify timestamp, as a UNIX epoch time

=item mode => INT

The access mode, as a number

=back

=cut

sub list_parsed
{
   my $self = shift;
   my %args = @_;

   my $on_list = $args{on_list} or defined wantarray or croak "Expected 'on_list'";

   my $on_error = $args{on_error};
   $on_error ||= sub { die "Error $_[0] during LIST" } if !defined wantarray;

   require File::Listing;

   my $f = $self->list(
      path => $args{path},
   )->then( sub {
      my ( $list ) = @_;
      my @files = File::Listing::parse_dir( $list );

      # We want to present a list of HASH refs, as they're nicer to work with
      @files = map { my %h; @h{qw( name type size mtime mode )} = @$_; \%h } @files;

      return Future->new->done( @files );
   });

   $f->on_done( $on_list  ) if $on_list;
   $f->on_fail( $on_error ) if $on_error;

   return $f if defined wantarray;
   $f->on_ready( sub { undef $f } ); # Intentional cycle
}

=head2 $ftp->nlist( %args ) ==> $list

Runs a C<NLST> command on a path on the remote server; which requests a list
of filenames in a directory. Takes the following arguments

=over 8

=item path => STRING

Path to C<NLST>

=item on_list => CODE

Optional when returning a future. Continuation to invoke on success. Is passed
a list of names from the C<NLST> result in a single string.

 $on_list->( $list )

=item on_error => CODE

Optional. Continuation to invoke on an error.

 $on_error->( $message )

=back

The C<namelist> method may be easier to use as it splits the lines.

=cut

sub nlst
{
   my $self = shift;
   my %args = @_;

   my $path = $args{path};

   my $on_list = $args{on_list} or defined wantarray or croak "Expected 'on_list'";

   my $on_error = $args{on_error};
   $on_error ||= sub { die "Error $_[0] during NLST" } if !defined wantarray;

   my $f = $self->_do_command_collect_dataconn(
      "NLST" . ( defined $path ? " $path" : "" ),
   );

   $f->on_done( $on_list  ) if $on_list;
   $f->on_fail( $on_error ) if $on_error;

   return $f;
}

=head2 $ftp->namelist( %args ) ==> @names

Runs a C<NLST> command on a path on the remote server; which requests a list
of filenames in a directory. Takes the following arguments

=over 8

=item path => STRING

Path to C<NLST>

=item on_names => CODE

Optional when returning a future. Continuation to invoke on success. Is passed
a list of names from the C<NLST> result in a list, one name per entry

 $on_name->( @names )

=item on_error => CODE

Optional. Continuation to invoke on an error.

 $on_error->( $message )

=back

=cut

sub namelist
{
   my $self = shift;
   my %args = @_;

   my $on_names = $args{on_names} or defined wantarray or croak "Expected 'on_names'";

   my $on_error = $args{on_error};
   $on_error ||= sub { die "Error $_[0] during NLST" } if !defined wantarray;

   my $f = $self->nlst(
      path => $args{path},
   )->then( sub {
      my ( $list ) = @_;
      return Future->new->done( split( m/\r?\n/, $list ) );
   });

   $f->on_done( $on_names ) if $on_names;
   $f->on_fail( $on_error ) if $on_error;

   return $f if defined wantarray;
   $f->on_ready( sub { undef $f } ); # Intentional cycle
}

=head2 $ftp->retr( %args ) ==> $content

Retrieves a file on the remote server. Takes the following arguments

=over 8

=item path => STRING

Path to file to retrieve

=item on_data => CODE

Optional when returning a future. Continuation to invoke on success. Is
passed the contents of the file as a single string.

 $on_data->( $content )

=item on_error => CODE

Optional. Continuation to invoke on an error.

 $on_error->( $message )

=back

=cut

sub retr
{
   my $self = shift;
   my %args = @_;

   my $path = $args{path};
   defined $path or croak "Expected 'path'";

   my $on_data = $args{on_data} or defined wantarray or croak "Expected 'on_data' as CODE reference";

   my $on_error = $args{on_error};
   $on_error ||= sub { die "Error $_[0] during RETR" } if !defined wantarray;

   my $f = $self->_do_command_collect_dataconn(
      "RETR $path",
   );

   $f->on_done( $on_data  ) if $on_data;
   $f->on_fail( $on_error ) if $on_error;

   return $f;
}

=head2 $ftp->stat( %args ) ==> @stat

Runs a C<STAT> command on a path on the remote server; which requests details
on the file, or contents of the directory. Takes the following arguments

=over 8

=item path => STRING

Path to C<STAT>

=item on_stat => CODE

Optional when not returning a future. Continuation to invoke on success. Is
passed a list of lines from the C<STAT> result, one line per element.

 $on_stat->( @stat )

=item on_error => CODE

Optional. Continuation to invoke on an error.

 $on_error->( $message )

=back

The C<stat_parsed> method may be easier to use as it parses the lines.

=cut

sub stat
{
   my $self = shift;
   my %args = @_;

   my $path = $args{path}; # optional

   my $on_stat = $args{on_stat} or defined wantarray or croak "Expected 'on_stat'";

   my $on_error = $args{on_error};
   $on_error ||= sub { die "Error $_[0] during STAT" } if !defined wantarray;

   my $f = $self->do_command( defined $path ? "STAT $path" : "STAT", [ 211 ] )
      ->then( sub {
         my ( $num, $message, $headline, @statlines ) = @_;
         return Future->new->done( @statlines );
      });

   $f->on_done( $on_stat  ) if $on_stat;
   $f->on_fail( $on_error ) if $on_error;

   return $f if defined wantarray;
   $f->on_ready( sub { undef $f } ); # Intentional cycle
}

=head2 $ftp->stat_parsed( %args ) ==> @stat

Runs a C<STAT> command on a path on the remote server; and parse the result
lines. Takes the following arguments

=over 8

=item path => STRING

Path to C<STAT>

=item on_stat => CODE

Optional when returning a future. Continuation to invoke on success. Is passed
a list of lines from the C<STAT> result, one line per element.

 $on_stat->( @stat )

=item on_error => CODE

Optional. Continuation to invoke on an error.

 $on_error->( $message )

=back

The C<@stat> array will be passed a list of C<HASH> references, each formed
like

=over 8

=item name => STRING

The filename

=item type => STRING

A single character; C<f> for files, C<d> for directories

=item size => INT

The size in bytes

=item mtime => INT

The item's last modify timestamp, as a UNIX epoch time

=item mode => INT

The access mode, as a number

=back

If C<STAT> is invoked on a file, then C<@stat> will contain a single reference
to represent it. If invoked on a directory, the C<@stat> will start with a
reference about the directory itself (whose name will be C<.>), then one per
item in the directory, in the order the server returned the lines.

=cut

sub stat_parsed
{
   my $self = shift;
   my %args = @_;

   defined $args{path} or croak "Expected 'path'";

   my $on_stat = $args{on_stat} or defined wantarray or croak "Expected 'on_stat'";

   require File::Listing;

   my $on_error = $args{on_error};
   $on_error ||= sub { die "Error $_[0] during stat_parsed" } if !defined wantarray;

   my $f = $self->stat(
      path => $args{path},
   )->then( sub {
      my @statlines = @_;

      my @pstats;

      if( @statlines > 1 ) {
         # path is a directory. In that case, look for the . item
         # This would be easy only File::Listing::parse_dir WILL
         # ignore it and we don't get a say in the matter.
         # In this case, we'll do a bit of cheating. We'll look for the
         # "." line ourselves, mangle its name to "DIR", and mangle it
         # back on the other end.

         my @lines_with_cwd;
         my @lines_without_cwd;

         foreach ( @statlines ) {
            m/ \.$/ ? ( push @lines_with_cwd, $_ ) : ( push @lines_without_cwd, $_ );
         }

         @lines_with_cwd == 1 or
            return $on_error->( "Did not find '.' in LIST output on directory $args{path}" );

         my $l = $lines_with_cwd[0];
         $l =~ s/ \.$/ DIR/;

         ( my $cwdstat ) = File::Listing::parse_dir( $l );

         $cwdstat->[0] eq "DIR" or
            return $on_error->( "Parsed listing did not contain DIR as the name like we expected for $args{path}" );

         $cwdstat->[0] = ".";

         @pstats = ( $cwdstat, File::Listing::parse_dir( \@lines_without_cwd ) );
      }
      else {
         @pstats = File::Listing::parse_dir( $statlines[0] );
      }

      # We want to present a HASH refs, as they're nicer to work with
      foreach ( @pstats ) {
         my %h;
         @h{qw( name type size mtime mode )} = @$_;
         $_ = \%h;
      }

      return Future->new->done( @pstats );
   });

   $f->on_done( $on_stat  ) if $on_stat;
   $f->on_fail( $on_error ) if $on_error;

   return $f if defined wantarray;
   $f->on_ready( sub { undef $f } ); # Intentional cycle
}

=head2 $ftp->stor( %args ) ==> ()

Stores a file on the remote server. Takes the following arguments

=over 8

=item path => STRING

Path to file to store

=item data => STRING

New contents for the file

=item on_stored => CODE

Optional when returning a future. Continuation to invoke on success.

 $on_stored->()

=item on_error => CODE

Optional. Continuation to invoke on an error.

 $on_error->( $message )

=back

=cut

sub stor
{
   my $self = shift;
   my %args = @_;

   my $path = $args{path};
   defined $path or croak "Expected 'path'";

   my $data = $args{data};
   defined $data or croak "Expected 'data'";

   my $on_stored = $args{on_stored} or defined wantarray or croak "Expected 'on_stored'";

   my $on_error = $args{on_error};
   $on_error ||= sub { die "Error $_[0] during STOR" } if !defined wantarray;

   my $f = $self->_do_command_send_dataconn(
      "STOR $path",
      $data,
   );

   $f->on_done( $on_stored ) if $on_stored;
   $f->on_fail( $on_error  ) if $on_error;

   return $f;
}

=head1 SEE ALSO

=over 4

=item *

L<http://tools.ieft.org/html/rfc959> - FILE TRANSFER PROTOCOL (FTP)

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
