package POE::Component::LaDBI::Request;

use v5.6.0;
use strict;
use warnings;

use POE::Component::LaDBI::Commands; # imports @COMMANDS

our $VERSION = '1.0';


our @HANDLE_ID_REQUIRED =
  qw(
     DISCONNECT
     PREPARE
     FINISH
     EXECUTE
     ROWS
     FETCHROW
     FETCHROW_HASH
     FETCHALL
     PING
     DO
     BEGIN_WORK
     COMMIT
     ROLLBACK
     SELECTALL
     SELECTALL_HASH
     SELECTCOL
     SELECTROW
     QUOTE
    );

our @DATA_REQUIRED =
  qw(
     CONNECT
     PREPARE
     DO
     FETCHALL_HASH
     SELECTALL
     SELECTALL_HASH
     SELECTCOL
     SELECTROW
     QUOTE
    );

our @DATA_NOT_ALLOWED =
  qw(
     DISCONNECT
     ROWS
     FETCHROW
     FETCHROW_HASH
     BEGIN_WORK
     COMMIT
     ROLLBACK
    );

our $ID = 1;

# Preloaded methods go here.

sub new {
  my $o = shift;
  my $class = ref($o) || $o;
  my $self = bless {}, $class;

  # force args into hash
  my (%a) = @_;

  # force all keys lowercase
  my (%args) = map { lc($_), $a{$_} } keys %a;

  # force 'cmd' value uppercase; ignore if it doesn't exist
  $args{cmd} = uc($args{cmd}) if exists $args{cmd};

  return $self->_init(%args);
} #end: new()


sub _init {
  my $self = shift;
  my (%args) = @_;

  unless (defined $args{cmd}) {
    warn __PACKAGE__ . "->new() 'Cmd' argument required.";
    return;
  }

  return unless $self->_validate_cmd(%args);
  return unless $self->_validate_handle_id(%args);
  return unless $self->_validate_data(%args);

  $self->{cmd     } = delete $args{cmd     };
  $self->{handleid} = delete $args{handleid}; #might be undef
  $self->{data    } = delete $args{data    };


  $self->{id} = $ID++;

  if (keys %args) {
    warn __PACKAGE__ . "->new() unknown argument(s): ".join(',', keys %args);
  }

  return $self;
} #end: _init()

sub _validate_cmd() {
  my $self = shift;
  my (%args) = @_;

  unless (grep { $args{cmd} eq $_ } @COMMANDS) {
    warn __PACKAGE__ . "->new() value of 'Cmd' argument ($args{cmd}) not implemented.";
    return;
  }

  return $self;
} #end: _validate_cmd

sub _validate_handle_id {
  my $self = shift;
  my (%args) = @_;

  my $required = grep { $args{cmd} eq $_ } @HANDLE_ID_REQUIRED;

  if ($required and !defined $args{handleid}) {
    warn __PACKAGE__ . "->new() argument 'HandleId' required for 'Cmd' ($args{cmd}).";
    return;
  }

  return $self;
} #end: _validate_id

sub _validate_data {
  my $self = shift;
  my (%args) = @_;

  my $required = grep {$args{cmd} eq $_} @DATA_REQUIRED;

  if ($required and !defined $args{data}) {
    warn __PACKAGE__ . "->new() argument 'Data' required for 'Cmd' ($args{cmd}).";
    return;
  }

  my $not_allowed = grep {$args{cmd} eq $_} @DATA_NOT_ALLOWED;
  if ($not_allowed and defined $args{data}) {
    warn __PACKAGE__ . "->new() argument 'Data' not allowed for 'Cmd' ($args{cmd}).";
    return;
  }

  return $self;
} #end: _validate_data()



sub cmd       {my $k='cmd'     ; @_==2 and $_[0]->{$k} = $_[1]; $_[0]->{$k}; }
sub handle_id {my $k='handleid'; @_==2 and $_[0]->{$k} = $_[1]; $_[0]->{$k}; }
sub data      {my $k='data'    ; @_==2 and $_[0]->{$k} = $_[1]; $_[0]->{$k}; }

sub id { $_[0]->{id}; }


1;
__END__

=head1 NAME

POE::Component::LaDBI::Request - Class to encapsulate LaDBI requests to be
executed by POE::Component::LaDBI::Engine.

=head1 SYNOPSIS

Excuse the vulgarities, I was tired and maybe even a little drunk ;).

  use POE::Component::LaDBI::Request;

  $dsn = 'dbi:Sybase:server=biteme;hostname=sybdb.biteme.com;database=biteme',
  $user = 'pimple';
  $passwd = 'oNMyaSS';

  $req = POE::Component::LaDBI::Request->new(Cmd  => 'connect',
					     Data => [$dsn, $user, $passwd]);

  $eng = POE::Component::LaDBI::Engine->new();

  $resp = $eng->request( $req );

  die "connect failed" unless $resp->code eq 'OK';

  $dbh_id = $resp->handle_id;

  $sql = 'SELECT * FROM candidates WHERE jaws = ? AND willingness = ?'

  $req = POE::Component::LaDBI::Request->new(Cmd      => 'prepare',
					     HandleId => $dbh_id  ,
					     Data     => [$sql]   );

  $resp = $eng->request( $req );

  die "prepare failed" unless $resp->code eq 'OK';

  $sth_id = $resp->handle_id;

  $req = POE::Component::LaDBI::Request->new(Cmd      => 'execute',
					     HandleId => $sth_id  ,
					     Data     => ['WEAK','HIGH']);

  $resp = $eng->request( $req );

  die "execute failed" unless $resp->code eq 'OK';

  $req = POE::Component::LaDBI::Request->new(Cmd      => 'rows',
					     HandleId => $sth_id);

  $resp = $eng->request( $req );

  die "rows failed" unless $resp->code eq 'OK';

  $nr_rows = $resp->data();

  $req = POE::Component::LaDBI::Request->new(Cmd      => 'fetchrow',
					     HandleId => $sth_id);

  for ($i=0; $i < $nr_rows; $i++) {

     $resp = $eng->request( $resp );

     die "fetchrow failed" unless $resp->code eq 'OK';

     $row = $resp->data();

     print "row[$i]: ", join("\t", @$row), "\n";

  }

=head1 DESCRIPTION

=over 4

=item C<$req = POE::Component::LaDBI::Request-E<gt>new()>

Upon instantiation a request id is allocated to represent this request.
This cookie is available as C<$req->id>.

Args:

For the keys, capitalization does not matter. Internally the keys are
lowercased.

=over 4

=item C<Cmd>

Required.

The command to execute. Only a subset of DBI basic commands implemented.

The value must be in all uppercase.

So far they are:

   CONNECT     	    ->   DBI->connect
   DISCONNECT  	    ->   $dbh->disconnect
   PREPARE     	    ->   $sth->prepare
   FINISH      	    ->   $sth->finish
   EXECUTE     	    ->   $sth->execute
   ROWS        	    ->   $sth->rows
   FETCHROW    	    ->   $sth->fetchrow
   FETCHROW_HASH    ->   $sth->fetchrow_hash
   FETCHALL    	    ->   $sth->fetchall
   FETCHALL_HASH    ->   $sth->fetchall_hash
   PING        	    ->   $dbh->ping
   DO          	    ->   $dbh->do
   BEGIN_WORK       ->   $dbh->begin_work
   COMMIT      	    ->   $dbh->commit
   ROLLBACK    	    ->   $dbh->rollback
   SELECTALL        ->   $dbh->selectall
   SELECTALL_HASH   ->   $dbh->selectall_hash
   SELECTCOL        ->   $dbh->selectcol
   SELECTROW        ->   $dbh->selectrow
   QUOTE            ->   $dbh->quote

=item C<HandleId>

For some commands it is required. They are:

   DISCONNECT
   PREPARE
   FINISH
   EXECUTE
   ROWS
   FETCHROW
   FETCHROW_HASH
   FETCHALL
   PING
   DO
   BEGIN_WORK
   COMMIT
   ROLLBACK
   SELECTALL
   SELECTALL_HASH
   SELECTCOL
   SELECTROW
   QUOTE

=item C<Data>

For some commands it is required. They are:

   CONNECT
   PREPARE
   DO
   FETCHALL_HASH
   SELECTALL
   SELECTALL_HASH
   SELECTCOL
   SELECTROW
   QUOTE

No Data field is allowed for:

   DISCONNECT
   ROWS
   FETCHROW
   FETCHROW_HASH
   BEGIN_WORK
   COMMIT
   ROLLBACK

=back

=item C<$req-E<gt>cmd>

Set/Get accessor function.

=item C<$req-E<gt>data>

Set/Get accessor function.

=item C<$req-E<gt>handle_id>

Set/Get accessor function.

=item C<$req-E<gt>id>

Get accessor function.

=back


=head2 EXPORT

None by default.

=head1 AUTHOR

Sean Egan, E<lt>seanegan:bigfoot_comE<gt>

=head1 SEE ALSO

L<perl>, L<POE::Component::LaDBI::Response>,
L<POE::Component::LaDBI::Engine>.

=cut
