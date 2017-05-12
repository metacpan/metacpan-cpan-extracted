package Net::SPOCP::Protocol;

use 5.006;
use strict;
use warnings;

@Net::SPOCP::Protocol::ISA = qw(Net::SPOCP);

use Carp;
use IO::Socket::INET;
use IO::Socket::SSL;
use Authen::SASL;
use MIME::Base64;

sub init
  {
    $_[0]->connect();
  }

sub connect
  {
    my $self = shift;

    $self->disconnect() if ref $self->{_sock};
    $self->{_sock} = IO::Socket::INET->new(PeerAddr=>$self->{server},
					   Proto=>'tcp',
					   Timeout=>$self->{timeout} || 300);

    croak "Net::SPOCP::connect failed: $!\n"
       unless $self->{_sock} && $self->{_sock}->connected;
  }

sub DESTROY
  {
    my $self = shift;
    $self->disconnect() if $self->{_sock} && $self->{_sock}->connected;
  }

sub disconnect
  {
    my $self = shift;
    eval
      {
  $self->logout();
	$self->{_sock}->close(SSL_no_shutdown=>1) if $self->{_tls};
	$self->{_sock}->shutdown(2);
      };
    if ($@) { carp "Net::SPOCP::disconnect: $@\n"; }
    $self->{_sock} = undef;
  }

sub starttls
  {
    my $self = shift;
    my $res = $self->send(Net::SPOCP::Request::Starttls->new())->recv;
    if($res->code() == 205)
    {
      $self->{_sock} = IO::Socket::SSL->start_SSL($self->{_sock},
        SSL_verify_mode => 0x01,
        SSL_ca_file => $self->{ssl_ca_file});
    }
    if($res->code() != 205)
    {
      croak("Net::SPOCP: Failed starting tls, probably forbidden by server.")
    }
    $res;
  }

  sub query
  {
    my $self = shift;

    my $rule = $_[0];
    unless (UNIVERSAL::isa('Net::SPOCP::SExpr',$_[0]))
    {
      $rule = Net::SPOCP::SExpr->new($_[0]);
    }

    $self->send(Net::SPOCP::Request::Query->new(rule=>$rule,path=>'/'))->recv();
  }

sub capa
  {
    my $self = shift;
    $self->send(Net::SPOCP::Request::Capa->new())->recv();
  }

sub auth
  {
    my $self = shift;
    my $mech = shift;
    my $callbacks = shift;
    my $res;

    $mech =~ m/(\w+):(\w+)/;

    $callbacks = "" unless $callbacks;

    my $sasl = Authen::SASL->new(
      mechanism => "$2",
      callback => "$callbacks",
    );

    $self->{server} =~ m/([\w\d\.-]+):(\d+)/;
    my $server = $1;

    my $conn = $sasl->client_new("spocp", "$server");
    die($conn->code()) if $conn->code() < 0;

    {
      my $data = encode_base64($conn->client_start(), '');

      $res = $self->send(Net::SPOCP::Request::Auth->new(
          mech => $mech,
          data => $data))->recv();
    }

    while($res->code == 301)
    {
      my $dec_data = decode_base64($res->[0]->data);
      my $raw_data = $conn->client_step($dec_data);
      my $data = encode_base64($raw_data, '') if $raw_data;
      $data = "" unless $data;
      $res = $self->send(Net::SPOCP::Request::Auth->new(
          data => $data))->recv();
    }
    if($res->code == 200)
    {
      $self->{sasl} = $conn;
    }
    else
    {
      croak("Net::SPOCP: Sasl auth failed.")
    }
    $res;
  }

sub logout
  {
    my $self = shift;
    my $res = $self->send(Net::SPOCP::Request::Logout->new())->recv();
    $self->{sasl} = undef;
    $self->{rest_buf} = undef;
    $res;
  }

sub noop
  {
    my $self = shift;
    $self->send(Net::SPOCP::Request::Noop->new())->recv();
  }

sub send
  {
    my $self = shift;
    my $msg = shift;
    my $tosend;

    carp "Net::SPOCP::send disconnected\n" unless
      $self->{_sock} && $self->{_sock}->connected;

      if($self->{sasl})
      {
        $tosend = $self->{sasl}->encode($msg->toString());
      }
      else
      {
        $tosend = $msg->toString();
      }
    $self->{_sock}->print($tosend);
    $self;
  }


sub read
  {
    my $self = shift;

    carp "Net::SPOCP::send disconnected\n" unless
      $self->{_sock} && $self->{_sock}->connected;

    my $buf = '';

    if(!$self->{rest_buf})
    {
      my $nread = 0;
      my $tbuf = '';
      my $maxread = 1024;
      while($nread = sysread($self->{_sock}, $tbuf, $maxread))
      {
        last if $nread == 0; # EOF
        $buf .= $tbuf;
        last if ($maxread - $nread) != 0;
      }
      croak "Net::SPOCP::recv read error: $!\n" unless defined $nread;

      if($self->{sasl})
      {
        $buf = $self->{sasl}->decode($buf);
      }
    }
    else
    {
      $buf = $self->{rest_buf};
    }

    $buf =~ m/^(\d+):/;
    my $len = $1 if $1;
    carp("couldn't get len in buf at Net::SPOCP::recv read") unless $len;
    $buf =~ m/^(\d+):(.{$len})(.*)$/;
    $buf = $2 if $2;
    carp("couldn't get buf in of $len at Net::SPOCP::recv read") unless $buf;
    # there is a second message after the first one. we store this in
    #  $self->{rest_buf} and take it out on the next read.
    $self->{rest_buf} = $3;
    $buf;
  }

sub recv
  {
    my $self = shift;

    my $res = Net::SPOCP::Response->new();
    my $r;
    do
      {
	$r = Net::SPOCP::Reply->parse($self->read());
	$res->add_reply($r);
      } while ($r->code == 201 || $r->code == 301);

    $res;
  }

package Net::SPOCP::Client;
@Net::SPOCP::Client::ISA = qw(Net::SPOCP::Protocol);

package Net::SPOCP::Request;
@Net::SPOCP::Request::ISA = qw(Net::SPOCP);

sub toString
  {
    $_[0]->l_encode($_[0]->l_encode($_[0]->type).$_[0]->encode());
  }

sub init { }

sub type {
  die "Implementation error calling type: ".join(',',caller())."\n";
}

sub encode
  {
    die $_[0]->type . " not implemented yet"
  }

package Net::SPOCP::Request::Query;
@Net::SPOCP::Request::Query::ISA = qw(Net::SPOCP::Request);

sub type { 'QUERY' }

sub encode
  {
    $_[0]->l_encode($_[0]->{path}).$_[0]->l_encode($_[0]->{rule}->toString()).$_[0]->l_encode($_[0]->{data});
  }

package Net::SPOCP::Request::List;
@Net::SPOCP::Request::List::ISA = qw(Net::SPOCP::Request);

sub type { 'LIST' }

package Net::SPOCP::Request::BSearch;
@Net::SPOCP::Request::BSearch::ISA = qw(Net::SPOCP::Request);

sub type { 'BSEARCH' }

package Net::SPOCP::Request::Add;
@Net::SPOCP::Request::Add::ISA = qw(Net::SPOCP::Request);

sub type { 'ADD' }

package Net::SPOCP::Request::Capa;
@Net::SPOCP::Request::Capa::ISA = qw(Net::SPOCP::Request);

sub type { 'CAPA' }

sub encode
  {
    return("")
  }

package Net::SPOCP::Request::Auth;
@Net::SPOCP::Request::Auth::ISA = qw(Net::SPOCP::Request);

sub type { 'AUTH' }

sub encode
  {
    my $mech = "";
    $mech = $_[0]->l_encode($_[0]->{mech}) if $_[0]->{mech};
    $mech.$_[0]->l_encode($_[0]->{data});
  }

package Net::SPOCP::Request::Logout;
@Net::SPOCP::Request::Logout::ISA = qw(Net::SPOCP::Request);

sub type { 'LOGOUT' }

sub encode
  {
    return("");
  }

package Net::SPOCP::Request::Noop;
@Net::SPOCP::Request::Noop::ISA = qw(Net::SPOCP::Request);

sub type { 'NOOP' }

sub encode
  {
    return("");
  }

package Net::SPOCP::Request::Starttls;
@Net::SPOCP::Request::Starttls::ISA = qw(Net::SPOCP::Request);

sub type { 'STARTTLS' }

sub encode
  {
    return("");
  }

package Net::SPOCP::Response;
@Net::SPOCP::Response::ISA = qw(Net::SPOCP);

use Carp;

sub new
  {
    my $class = shift;

    bless \@_,$class;
  }

sub add_reply
  {
    push(@{$_[0]},$_[1]);
  }

sub replies
  {
    @{$_[0]};
  }

sub reply
  {
    $_[0]->[$_[1]];
  }

sub is_error
  {
    my $code = $_[0]->reply(0)->code;
    # multi-part, ok, authdata, auth ok
    $code != 201 && $code != 200 && $code != 301 && $code != 300
  }

sub error
  {
    $_[0]->reply(0)->error;
  }

sub code
  {
    $_[0]->reply(0)->code;
  }

package Net::SPOCP::Reply;
@Net::SPOCP::Reply::ISA = qw(Net::SPOCP);

sub init {}

use Carp;

my %CODE = (
	    200 => 'Ok',
	    201 => 'Multiline',
	    202 => 'Denied',
	    203 => 'Bye',
	    204 => 'Transaction complete',
      205 => 'Ready to start TLS',
      300 => 'Authentication in progress',
      301 => 'Authentication Data',
	    401 => 'Service not available',
	    402 => 'Information unavailable',
	    500 => 'Syntax error',
	    501 => 'Operations error',
	    502 => 'Not supported',
	    503 => 'Already in operation',
	    504 => 'Line too long',
	    505 => 'Unknown ID',
	    506 => 'Already exists',
	    507 => 'Line too long',
	    508 => 'Unknown command',
	    509 => 'Access denied',
	    510 => 'Argument error',
	    511 => 'Already active',
	    512 => 'Internal error',
	    513 => 'Input error',
	    514 => 'Timelimit exceeded',
	    515 => 'Sizelimit exceeded',
	    516 => 'Other'
	   );

sub parse
  {
    my $self = shift;
    my $str = shift;

    my $me = Net::SPOCP::Reply->new();

    carp "Net::SPOCP::Reply::parse format error: missing error code\n" unless
      $str =~ s/^3:([0-9]{3})//o;

    $me->{code} = $1;

    carp "Net::SPOCP::Reply::parse format error: format error\n" unless
      $str =~ s/^([0-9]+):(.*)//o;

    $me->{length} = $1;
    $me->{data} = $2;

    $me;
  }

sub code
  {
    $_[0]->{code};
  }

sub length
  {
    $_[0]->{length};
  }

sub data
  {
    $_[0]->{data};
  }

sub error
  {
    my $code = $_[0]->{code};

    return "Unknown error" unless exists $CODE{$code};
    $CODE{$code};
  }

package Net::SPOCP;

1;
