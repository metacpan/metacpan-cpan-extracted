package PgSQL;

# This perl module is Copyright (c) 1998 Göran Thyni, Sweden.
# All rights reserved.
# You may distribute under the terms of either 
# the GNU General Public License version 2 (or later)
# or the Artistic License, as specified in the Perl README file.
#
# $Id: PgSQL.pm,v 1.5 1998/08/15 15:08:39 goran Exp $

use strict;

use PgSQL::Cursor;

use IO::Socket::UNIX;
use IO::Select;

use vars qw (@ISA $VERSION);

$VERSION = '0.51';

@ISA = ('IO::Socket::UNIX');

sub PG_PROTOCOL_LATEST { 0x00020000; }

my $EnvironmentOptions =
  { 
   "PGDATESTYLE" => "datestyle",
   "PGTZ" => "timezone",
   "PGCLIENTENCODING" => "client_encoding",
   "PGCOSTHEAP" => "cost_heap",
   "PGCOSTINDEX" => "cost_index",
   "PGRPLANS" => "r_plans",
   "PGGEQO" => "geqo",
  };

sub STATUS_OK    {1}
sub STATUS_ERROR {0}

sub PGRES_EMPTY_QUERY {0}
sub PGRES_COMMAND_OK  {1}
sub PGRES_TUPLES_OK   {2}
sub PGRES_COPY_OUT    {'G'}
sub PGRES_COPY_IN     {'H'}
sub PGRES_BAD_RESPONSE {5}
sub PGRES_NONFATAL_ERROR {6}
sub PGRES_FATAL_ERROR {7}

sub DEF_PGPORT    { 5432; }
sub DEF_PGTTY     { ''; }
sub DEF_PGOPTIONS { ''; }

sub AUTH_REQ_OK       {0}
sub AUTH_REQ_PASSWORD {3}
sub AUTH_REQ_CRYPT    {4}

sub UNIXSOCK_PATH
  {
    my $href = shift;
    '/tmp/.s.PGSQL.' . $href->{Port};
  }


sub new
  {
    my ($class, %args) = @_;
    my $host = $args{Host} || $ENV{PGHOST};
    my $port = $args{Port} || $ENV{PGPORT} || &DEF_PGPORT;
    $args{Port} ||= DEF_PGPORT;
    if ($host)
      {
	$args{PeerAddr} = "${host}:${port}";
	@ISA = qw (IO::Socket::INET);
      }
    else
      {
	$args{Peer} ||= UNIXSOCK_PATH(\%args);
      }
    my $self = $class->SUPER::new(%args);
    if ($self)
      {
	${*$self}{DBNAME} = $args{DBName} || $ENV{PGDATABASE} || '';
	${*$self}{PGHOST} = $host;
	${*$self}{PGPORT} = $port;
	${*$self}{PGPORT} = $args{Tty} || $ENV{PGTTY} || &DEF_PGTTY;
	${*$self}{PGOPTIONS} =
	  $args{Options} || $ENV{PGOPTIONS} || &DEF_PGOPTIONS;
	${*$self}{PGUSER} = $args{User} || $ENV{PGUSER} || ${*$self}{DBNAME};
	${*$self}{PGPASS} = $args{Password} || $ENV{PGPASS} || '';
	$self->blocking(0);
	eval { $self->handshake; };
	if ($@) 
	  { 
	    $self->close;
	    warn $@;
	    return undef;
	  }
	$self->setenv();
      }
    $self;
  }


sub handshake
  {
    my $self = shift;
    unless ($self->packetSend($self->startup_packet))
      {
	die "handshake: couldn't send startup packet:errno=$!\n";
      }
    while (1)
      {
	last if $self->wait(1,0);
	my $resp = $self->getc;
	die $self->getline() if ($resp eq 'E');
	die "connectDB() -- expected authentication request\n" if $resp ne 'R';
	my $areq = $self->getint(4);
	my $salt = 0;
	if ($areq == AUTH_REQ_CRYPT)
	  {
	    next if $self->pqGetnchar($salt, 4);
	    # FIXME, this does not work, I think!
	  }
	$self->sendauth($areq);
	$self->flush;
	last if ($areq == AUTH_REQ_OK);
      }
}

sub setenv
  {
    my $self = shift;
    for my $eo (keys %$EnvironmentOptions)
      {
	my $val = $ENV{$eo};
	if ($val)
	  {
	    my $setQuery = sprintf("SET %s = '%.60s'", $eo->pgName, $val);
	    $setQuery = sprintf("SET %s = default", $eo->pgName)
	      if $val eq "default";
	    my $res = $self->do($setQuery);
	  }
      }
  }


sub close
{
  my $self = shift;
  if ($self->opened)
    {
      local $SIG{PIPE} = 'IGNORE';
      $self->print('X');
      $self->flush;
      $self->flush_input;
      $self->SUPER::close;
    }
}

sub packetSend
  {
    my ($self,$buf,$len) = @_;
    return STATUS_ERROR unless $self->putint(4 + $len, 4); # size
    return STATUS_ERROR unless $self->write($buf, $len);
    return STATUS_ERROR unless $self->flush;
    STATUS_OK;
  }

sub startup_packet
  {
    my $self = shift;
    my $len = 4 + 64 + 32 + 64 + 64 + 64;
    my $packet = pack('Na64a32a64a64a64',
		      $self->PG_PROTOCOL_LATEST,
		      ${*$self}{DBNAME},
		      ${*$self}{PGUSER},
		      ${*$self}{PGOPTIONS},
		      '',
		      ${*$self}{PGTTY});
    ($packet,$len);
  }

sub getint
{
  my ($self, $sz) = @_;
  my $value;
  $self->read($value,$sz);
  my @a = unpack($sz == 4 ? 'N' : 'n', $value);
  return $a[0];
}

sub putint
{
  my ($self, $value, $sz) = @_;
  $self->write(pack($sz == 4 ? 'N' : 'n', $value), $sz);
}

sub wait
  {
    my ($self,$forRead,$forWrite) = @_;
# loop in case select returns EINTR 
#  for (;;) 
    {
      my $sel = IO::Select->new;
      $sel->add($self) if ($forRead || $forWrite);
      last if (($forRead && $sel->can_read) || ($forWrite && $sel->can_write));
      # next if ($errno == EINTR);
      # return EOF;
    }
    return 0;
  }


sub sendauth
  {
  my ($self, $areq, $hostname, $password, $errmsg) = @_;
  return STATUS_OK if $areq == AUTH_REQ_OK;
  die "sendauth: no password supplied\n" if (!$password);
#  if (pg_password_sendauth(conn, password, areq) != STATUS_OK)
  {
    die "fe_sendauth: error sending password authentication\n";
  }
  return STATUS_OK;
}


sub do
  {
    my ($self, $query) = @_;
    my $is_select = $query =~ /^\s*select\s/i;
    my $sth = $self->prepare($query);
    my $stat = $sth->exec;
    undef $sth unless $stat;
    return $sth if $is_select;
    return $stat;
  }

sub prepare
  {
    my ($self, $query) = @_;
    ${*$self}{CURSOR} = PgSQL::Cursor->new($self, undef, $query);
    ${*$self}{CURSOR};
  }

sub sendQuery
{
  my ($self, $query) = @_;
  $self->flush_input;
  return 0 unless $self->print('Q' . $query . "\0");
  $self->flush;
  return 1;
}

sub flush_input
  {
    my $self = shift;
    while (1) { last unless $self->parseInput; }
  }


# parseInput: if appropriate, parse input data from backend
# until input is exhausted or a stopping state is reached.
# Note that this function will NOT attempt to read more data from the backend.

sub parseInput
  {
    my ($self) = @_;
# Loop to parse successive complete messages available in the buffer.
# OK to try to read a message type code.
    my $id = $self->getc;
    return unless defined $id;
    return if $id eq "\0";
    # NOTIFY and NOTICE messages can happen in any state besides COPY OUT;
    # always process them right away.
    return ($id, $self->getNotify) if $id eq 'A';
    return ($id, $self->getNotice) if $id eq 'N';
    return ($id, $self->getCompleted) if $id eq 'C';  
    return ($id, $self->getError) if $id eq 'E'; 
    return ($id) if $id eq 'Z'; 
    return ($id, $self->getc) if $id eq 'I'; 
    return ($id, $self->getint(4), $self->getint(4)) if $id eq 'K'; 
    return ($id, $self->getCursor) if $id eq 'P'; # cursor
    return ($id, $self->getRowDescr) if $id eq 'T'; 
    return ($id, $self->getTuple(0)) if $id eq 'D'; 
    return ($id, $self->getTuple(1)) if $id eq 'B'; 
    return ($id, $self->getCopyIn)   if $id eq 'G';
    return ($id, $self->getCopyOut)  if $id eq 'H';
    die "unknown protocol character '$id' (" . $id . 
      ") read from backend.  " .
	"(The protocol character is the first character the " .
	  "backend sends in response to a query it receives).\n";
  }

sub getNotify
  {
    my $self = shift;
    my $i = $self->getint(4);
    my $note = $self->gets;
    $self->trace("NOTIFY: $i / $note");
    $note;
  }

sub getNotice
  {
    my $self = shift;
    my $note = $self->gets;
    $self->trace("$note");
    $note;
  }

sub getCompleted
  {
#    local $/ = 0;
    my $self = shift;
    my $note = $self->xgets;
    $self->trace("COMPELETED: $note");
    $note;
  }

sub getError
  {
    my $self = shift;
    my $note = $self->gets;
    die $note;
  }

sub getCursor
  {
    my $self = shift;
    my $note = $self->xgets;
    $self->trace("CURSOR: $note");
#    ${*$self}{CURSOR} = PgSQL::Cursor->new($self,$note,undef);
#    ${*$self}{CURSOR};
    $note;
  }

sub getCopyIn
  {
    my $self = shift;
    $self->trace("COPY_IN");
  }

sub getCoyout
  {
    my $self = shift;
    $self->trace("COPY_OUT");
  }
    
sub getRowDescr
  {
    my $self = shift;
    my ($i,@s,@oids,@typs,@sz);
    my $nfields = $self->getint(2);
    $self->trace("ROWDESCR: $nfields fields");
    for ($i = 0; $i < $nfields; $i++)
      {
	my $s = $self->xgets;
	my $typ = $self->getint(4);
	my $sz = $self->getint(2);
	my $oid = $self->getint(4);
	push @s, $s;
	push @oids, $oid;
	push @typs, $typ;
	push @sz, unpack("s",pack("s", $sz));
	$self->trace(sprintf("\t%s SIZE:%d TYPE:%d MODIFER:%d",
                             $s, $sz, $typ, $oid));
      }
    my $sth = ${*$self}{CURSOR} || PgSQL::Cursor->new($self,undef,undef);
    $sth->{NAME} = \@s;
    $sth->{TYPE} = \@typs;
    $sth->{SIZE} = \@sz;
    $sth->nfields($nfields);
    $nfields;
  }

sub getTuple
  {
    my ($self, $binary) = @_;
    my ($nullbits, $i, $mapbytes);
    my $nfields = ${*$self}{CURSOR}->nfields;
    {
      use integer;
      $mapbytes = $nfields / 8;
      $mapbytes++ if $nfields % 8;
    }
    $self->read($nullbits, $mapbytes);
    $self->trace("ROW:");
    my $a = [];
    for ($i = 0; $i < $nfields; $i++)
      {
	use integer;
	my ($sz,$value) = (0,'NULL');
	my $bit = (ord(substr($nullbits, $i / 8, 1)) >> (7 - ($i % 8))) & 1;
	if ($bit) 
	  {
	    $sz = $self->getint(4) - 4;
	    $self->read($value, $sz);
	  }
	$self->trace("\tTUPLE ($sz):\t$value");
	push @$a, $value;
      }
    my $sth = ${*$self}{CURSOR};
    $sth->add($a);
  }

sub xgets
  {
    my $self = shift;
    my $s = '';
    while (1)
      {
	$_ = $self->getc;
	last if int($_) == 0 and $_ eq "\0";
	$s .= $_;
      }
    return $s;
  }

sub begin
  {
    shift->do("BEGIN");
  }

sub commit
  {
    shift->do("COMMIT");
  }

sub rollback
  {
    shift->do("ROLLBACK");
  }

sub ping
  {
    my $self = shift;
    $self->do(' ');
  }

sub errmsg
  {
    my $self = shift;
    my $msg = shift;
    if (defined $msg) { ${*$self}{ERRMSG} = $msg; }
    ${*$self}{ERRMSG};
  }

sub trace
{
  my ($self, @msgs) = @_;
  my $lvl = ${*$self}{TRACE};
  print STDERR @msgs,"\n" if $lvl;
}

sub debug
  {
  my ($self, $lvl) = @_;
  ${*$self}{TRACE} = $lvl;
}

1;


