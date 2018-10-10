package Net::SMTP::Verify;

use Moose;

our $VERSION = '1.04'; # VERSION
# ABSTRACT: verify SMTP recipient addresses

use Net::SMTP::Verify::ResultSet;

use Net::DNS::Resolver;
use Net::SMTP;
use Net::Cmd qw( CMD_OK );
use Sys::Hostname;
use Digest::SHA qw(sha224_hex);


has 'host' => ( is => 'rw', isa => 'Maybe[Str]' );
has 'port' => ( is => 'rw', isa => 'Int', default => 25 );

has 'helo_name' => (
  is => 'rw', isa => 'Str', lazy => 1,
  default => sub { Sys::Hostname::hostname },
);
has 'timeout' => ( is => 'rw', isa => 'Int', default => 30 );

has 'resolver' => (
  is => 'rw', isa => 'Net::DNS::Resolver', lazy => 1,
  default => sub {
    Net::DNS::Resolver->new(
      dnssec => 1,
      adflag => 1,
    );
  },
);

has 'tlsa' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'openpgpkey' => ( is => 'rw', isa => 'Bool', default => 0 );

has 'logging_callback' => (
  is => 'rw', isa => 'CodeRef', lazy => 1,
  traits => [ 'Code' ],
  handles => {
    log => 'execute',
  },
  default => sub { sub {} },
);

has 'debug' => ( is => 'ro', isa => 'Bool', default => 0 );

sub BUILD {
  my $self = shift;
  if( $self->debug ) {
    $self->logging_callback( sub {
      print STDERR shift."\n";
    } );
  }
}

has '_known_hosts' => (
  is => 'ro', isa => 'ArrayRef', lazy => 1,
  default => sub { [] },
  traits => [ 'Array' ],
  handles => {
    '_reset_known_hosts' => 'clear',
    '_add_known_host' => 'push',
  }
);

sub _is_known_host {
  my ( $self, $host ) = @_;
  if( grep { $_ eq $host } @{$self->_known_hosts} ) {
    return 1;
  }
  return 0;
}


sub resolve {
  my ( $self, $domain ) = @_;

  if( defined $self->host ) {
    return $self->host;
  } else {
    $self->log('looking up MX for '.$domain.'...');
    my $reply = $self->resolver->query( $domain, 'MX' );
    if( $reply->answer ) {
      my @mx = grep { $_->type eq 'MX' } $reply->answer;
      @mx = sort { $a->preference <=> $b->preference } @mx;
      my @known_hosts = grep { $self->_is_known_host($_->exchange) } @mx;

      my $ex;
      if( @known_hosts ) {
        $ex = $known_hosts[0]->exchange;
      } else {
        $ex = $mx[0]->exchange;
        $self->_add_known_host( $ex );
      }
      $self->log('found '.scalar(@mx).' records. using: '.$ex.
        ( @known_hosts ? ' (reuse)' : '') );
      return $ex;
    }
    $self->log('looking up AAAA,A for '.$domain.'...');
    $reply = $self->resolver->query( $domain, 'AAAA', 'A' );
    if( my @rr = $reply->answer ) {
      $self->log('found '.scalar(@rr).' address records');
      return $domain;
    }
    $self->log('unable to resolve domain '.$domain);
    return; # lookup failed
  }

  die('unknown mode: '.$self->mode);
  return;
}


sub check_tlsa {
  my ( $self, $host, $port ) = @_;
  if( ! defined $port ) {
    $port = 25;
  }
  my $tlsa_name = '_'.$port.'._tcp.'.$host;
  $self->log('looking up TLSA for '.$tlsa_name.'...');
  my $reply = $self->resolver->send( $tlsa_name, 'TLSA' );

  if( ! $reply->header->ad ) {
    $self->log('no adflag set in response');
    return 0;
  }

  if( ! $reply->answer ) {
    $self->log('no TLSA record published');
    return 0;
  }

  return 1;
}

sub check_openpgpkey {
  my ( $self, $rs, @rcpts ) = @_;

  foreach my $rcpt ( @rcpts ) {
    my ( $local, $domain ) = split('@', $rcpt, 2);
    my $name = join('.', sha224_hex($local), '_openpgpkey', $domain);
    $self->log('looking up OPENPGPKEY: '.$name.'...');
    my $reply = $self->resolver->send( $name, 'TYPE61' );
    if( ! $reply->header->ad ) {
      $self->log('no adflag set in response');
      $rs->set( $rcpt, 'has_openpgpkey', 0 );
    } elsif( ! $reply->answer ) {
      $self->log('no OPENPGPKEY record found');
      $rs->set( $rcpt, 'has_openpgpkey', 0 );
    } else {
      $self->log('OPENPGPKEY record found');
      $rs->set( $rcpt, 'has_openpgpkey', 1 );
    }
  }

  return;
}

sub check_smtp {
  my ( $self, $rs, $host, $size, $sender, @rcpts ) = @_;

  $self->log('connecting to '.$host.' on port '.$self->port.'...');
  my $smtp = Net::SMTP->new( $host,
    Port => $self->port,
    Hello => $self->helo_name,
    Timeout => $self->timeout,
  );
  if( ! defined $smtp ) {
    $self->log('connection failed: '.$@);
    $rs->set( \@rcpts, 'error', 'connection failed: '.$@ );
    return;
  }

  $rs->set( \@rcpts, 'has_starttls',
    defined $smtp->supports('STARTTLS') ? 1 : 0 );

  if( defined $smtp->supports('PIPELINING') ) {
    $self->check_smtp_addresses_pipelining( $rs, $smtp, $size, $sender, @rcpts );
  } else {
    $self->check_smtp_addresses( $rs, $smtp, $size, $sender, @rcpts );
  }

  $self->log('sending QUIT...');
  $smtp->quit;
  return;
}

sub check_smtp_addresses {
  my ( $self, $rs, $smtp, $size, $sender, @rcpts ) = @_;
  $self->log('sending MAIL '.$sender.'...');
  my $mail_ok = $smtp->mail( $sender,
    defined $size && $smtp->supports('SIZE') ? ( Size => $size ):()
  );
  my $msg = $smtp->message; chomp($msg);
  $self->log('server said: '.$msg);
  if( ! $mail_ok ) {
    $rs->set( \@rcpts, 'smtp_message', $msg );
    $rs->set( \@rcpts, 'smtp_code', $smtp->code );
    return;
  }

  foreach my $rcpt ( @rcpts ) {
    $self->log('sending RCPT '.$rcpt.'...');
    my $rcpt_ok = $smtp->recipient( $rcpt );
    my $msg = $smtp->message; chomp( $msg );
    $self->log( 'server said: '.$msg );
    $rs->set( $rcpt, 'smtp_message', $msg );
    $rs->set( $rcpt, 'smtp_code', $smtp->code );
  }
  return;
}

has 'rcpt_bulk_size' => ( is => 'ro', isa => 'Int', default => 10 );

sub check_smtp_addresses_pipelining {
  my ( $self, $rs, $smtp, $size, $sender, @rcpts ) = @_;
  my $mail_sent = 0;

  while( my @bulk_rcpts = splice(@rcpts, 0, $self->rcpt_bulk_size) ) {
    $self->log('sending pipelined bulk...');
    my $bulk = '';
    if( ! $mail_sent ) {
    $bulk .= 'MAIL FROM: <'.$sender.'>'
        .( defined $size && $smtp->supports('SIZE') ? ' SIZE='.$size : '' )
        ."\n"
    }
    $bulk .= join("\n",
      map { 'RCPT TO: <'.$_.'>' } @bulk_rcpts,
    )."\n";

    $smtp->datasend( $bulk );

    if( ! $mail_sent ) {
      my $resp = $smtp->response;
      my $msg = $smtp->message; chomp( $msg );
      $self->log("server response to MAIL: ".$msg );
      if( $resp != CMD_OK ) {
        $rs->set( [ @bulk_rcpts, @rcpts ], 'smtp_code', $smtp->code );
        $rs->set( [ @bulk_rcpts, @rcpts ], 'smtp_message', $msg );
        return;
      }
      $mail_sent = 1;
    }

    foreach my $rcpt ( @bulk_rcpts ) {
      $smtp->response;
      my $msg = $smtp->message; chomp( $msg );
      $self->log("server response to RCPT $rcpt: ".$msg );
      $rs->set( $rcpt, 'smtp_code', $smtp->code );
      $rs->set( $rcpt, 'smtp_message', $msg );
    }
  }
  return;
}


sub check {
  my ( $self, $size, $sender, @rcpts ) = @_;
  my $rs = Net::SMTP::Verify::ResultSet->new;

  my $by_domain = {};
  foreach my $rcpt ( @rcpts ) {
    my ( $user, $domain ) = split('@', $rcpt, 2);
    if( ! defined $by_domain->{$domain} ) {
      $by_domain->{$domain} = [];
    }
    push( @{$by_domain->{$domain}}, $rcpt );
  }

  my $by_host = {};
  $self->_reset_known_hosts;
  foreach my $domain ( keys %$by_domain ) {
    my $host = $self->resolve( $domain );
    if( ! defined $host ) {
      $rs->set( $by_domain->{$domain},
        'error', 'unable to lookup '.$domain );
      return;
    }
    if( ! defined $by_host->{$host} ) {
      $by_host->{$host} = [];
    }
    push( @{$by_host->{$host}}, @{$by_domain->{$domain}} );
  }

  foreach my $host ( keys %$by_host ) {
    if( $self->tlsa ) {
      $rs->set( $by_host->{$host},
        'has_tlsa', $self->check_tlsa( $host ) );
    }
    $self->check_smtp( $rs, $host, $size, $sender, @{$by_host->{$host}} );
  }

  if( $self->openpgpkey ) {
    $self->check_openpgpkey( $rs, @rcpts );
  }

  return $rs;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SMTP::Verify - verify SMTP recipient addresses

=head1 VERSION

version 1.04

=head1 SYNOPSIS

  use Net::SMTP::Verify;

  my $v = Net::SMTP::Verify->new;
  my $resultset = $v->check(
    100000, # size
    'karl@senderdomain.de', # sender
    'rcpt1@rcptdomain.de', # 1 or more recipients...
    'rcpt2@rcptdomain.de', 
    'rcpt3@rcptdomain.de',
  );

  # check overall status
  $resultset->is_all_success;

  # check a single result
  $resultset->rcpt('rcpt1@rcptdomain.de')->is_success;
  $resultset->rcpt('rcpt1@rcptdomain.de')->smtp_code;
  $resultset->rcpt('rcpt1@rcptdomain.de')->smtp_message;
  $resultset->rcpt('rcpt1@rcptdomain.de')->has_starttls;
  $resultset->rcpt('rcpt1@rcptdomain.de')->has_tlsa;

  # more ways to retrieve results by status...
  $resultset->successfull_rcpts;
  $resultset->error_rcpts;
  $resultset->temp_error_rcpts;
  $resultset->perm_error_rcpts;

=head1 DESCRIPTION

This class implements checks for verifying SMTP addresses.

It implements the following checks:

=over

=item check addresses with SMTP MAIL FROM and RCPT TO commands

Check if the MX would accept mail for test addresses.

=item check of message size

If the mail exchanger (MX) supports the SIZE extension and a size is given the
module will pass the message size with the MAIL FROM command.

This will check if the message would exceed message size limits or recipients
quotas on the target MX.

=item check if MX could handle TLS connections

It will check if the STARTTLS extension required to enstablish encrypted TLS
connections is supported by the target MX.

=item check if TLSA record is available

The module could check if a TLSA record has been published for the target MX
server.

If such a record has been published the target MX SSL certificate could be
verified with DANE.

=back

=head1 ATTRIBUTES

=head2 host (default: undef)

Query this smtp server instead of the MX records.

=head2 port (default: 25)

Use a different port.

=head2 helo_name (default: hostname() )

Use a helo_name other than the hostname of the system.

=head2 timeout (default: 30)

Use this timeout for the SMTP connection.

=head2 resolver (default: system resolver)

Use a custom Net::DNS::Resolver object.

The default is:

  Net::DNS::Resolver->new(
    dnssec => 1,
    adflag => 1,
  );

The dnssec and adflag is required for the TLSA check.

=head2 tlsa (default: 0)

Set to 1 to activate TLSA lookup.

=head2 openpgpkey (default: 0)

Set to 1 to activate OPENPGPKEY lookup.

=head2 logging_callback (default: sub {})

Set a callback to retrieve log messages.

=head2 debug (default: 0)

If set to 1 it will set a logging_callback method to output
logs to STDERR.

=head1 METHODS

=head2 resolve( $domain )

Tries to resolve a MX to an hostname.

It will choose the first record with the highest priority listed as MX.

When a host is MX for multiple domains it will try to reuse the same
host for checks.

=head2 check_tlsa( $host, $port )

Check if a TLSA record is available.

=head2 check( $size, $sender, $rcpt1, $rcpts...)

Performs check and returns a Net::SMTP::Verify::ResultSet.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
