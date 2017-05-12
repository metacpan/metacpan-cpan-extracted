# ====
#  SSL/STARTTLS extention for Graham Barr's Net::POP3.
#    plus, enable arbitrary POP auth mechanism selection.
#      IO::Socket::SSL (also Net::SSLeay openssl),
#      Authen::SASL, MIME::Base64 should be installed.
#
package Net::POP3S;

use vars qw ( $VERSION @ISA );

$VERSION = '0.07';

use strict;
use base qw ( Net::POP3 );
use Net::Cmd;  # import CMD_OK, CMD_MORE, ...
use Net::Config;

eval {
    require IO::Socket::IP
	and unshift @ISA, 'IO::Socket::IP';
} or eval {
    require IO::Socket::INET6
	and unshift @ISA, 'IO::Socket::INET6';
} or do {
    require IO::Socket::INET
	and unshift @ISA, 'IO::Socket::INET';
};

# Override to support SSL/TLS.
sub new {
  my $self = shift;
  my $type = ref($self) || $self;
  my ($host, %arg);
  if (@_ % 2) {
      $host = shift;
      %arg  = @_;
  }
  else {
      %arg  = @_;
      $host = delete $arg{Host};
  }
  my $ssl = delete $arg{doSSL};
  $ssl = 'ssl' if delete $arg{SSL};

  my $hosts = defined $host ? $host : $NetConfig{pop3_hosts};
  my $obj;

  # eliminate IO::Socket::SSL from @ISA for multiple call of new.
  @ISA = grep { !/IO::Socket::SSL/ } @ISA;

  my %_args = map { +"$_" => $arg{$_} } grep {! /^SSL/} keys %arg;

  my $h;
  $_args{PeerPort} = $_args{Port} || 'pop3(110)';
  $_args{Proto} = 'tcp';
  $_args{Timeout} = defined $_args{Timeout} ? $_args{Timeout} : 120;
  if (exists $_args{ResvPort}) {
      $_args{LocalPort} = delete $_args{ResvPort};
  }

  foreach $h (@{ref($hosts) ? $hosts : [$hosts]}) {
      $_args{PeerAddr} = ($host = $h);

      $obj = $type->SUPER::new(
	  %_args
      )
      and last;
  }

  return undef
    unless defined $obj;

  ${*$obj}{'net_pop3_host'} = $host;

  $obj->autoflush(1);
  $obj->debug(exists $arg{Debug} ? $arg{Debug} : undef);

# common in SSL
  my %ssl_args;
  if ($ssl) {
    eval {
      require IO::Socket::SSL;
    } or do {
      $obj->set_status(500, ["Need working IO::Socket::SSL"]);
      $obj->close;
      return undef;
    };
    %ssl_args = map { +"$_" => $arg{$_} } grep {/^SSL/} keys %arg;
    $IO::Socket::SSL::DEBUG = (exists $arg{Debug} ? $arg{Debug} : undef); 
  }

# OverSSL
  if (defined($ssl) && $ssl =~ /ssl/i) {
    $obj->ssl_start(\%ssl_args)
      or do {
	 $obj->set_status(500, ["Cannot start SSL"]);
	 $obj->close;
	 return undef;
      };
  }

  unless ($obj->response() == CMD_OK) {
    $obj->close();
    return undef;
  }

  ${*$obj}{'net_pop3_banner'} = $obj->message;

# STARTTLS
  if (defined($ssl) && $ssl =~ /starttls|stls/i ) {
     my $capa;
    ($capa = $obj->capa
     and exists $capa->{STLS}
     and ($obj->command('STLS')->response() == CMD_OK)
     and $obj->ssl_start(\%ssl_args))
       or do {
	 $obj->set_status(500, ["Cannot start SSL session"]);
	 $obj->close();
	 return undef;
       };
  }

  $obj;
}

sub ssl_start {
    my ($self, $args) = @_;
    my $type = ref($self);

    (unshift @ISA, 'IO::Socket::SSL'
     and IO::Socket::SSL->start_SSL($self, %$args)
     and $self->isa('IO::Socket::SSL')
     and bless $self, $type     # re-bless 'cause IO::Socket::SSL blesses himself.
    ) or return undef;
}


sub capa {
    my $this = shift;

    if (exists ${*$this}{'net_pop3e_capabilities'}) {
	return ${*$this}{'net_pop3e_capabilities'};
    }
    $this->SUPER::capa();
}

# Override to specify a certain auth mechanism.
sub auth {
  my ($self, $username, $password, $mech) = @_;

  if ($mech) {
      $self->debug_print(1, "my favorite: ". $mech . "\n") if $self->debug;

      my @cl_mech = split /\s+/, $mech;
      my @matched = ();
      my $sv = $self->capa->{SASL} || 'CRAM-MD5';

      foreach my $i (@cl_mech) {
	  if (index($sv, $i) >= 0 && grep(/$i/i, @matched) == () ) {
	      push @matched, uc($i);
	  }
      }
      if (@matched) {
      ## override AUTH mech as specified.
      ## if multiple mechs are specified, priority is still up to Authen::SASL module.
	  ${*$self}{'net_pop3e_capabilities'}->{'SASL'} = join " ", @matched;
      }
  }
  $self->SUPER::auth($username, $password);
}

# Fix #121006 no timeout issue.
sub getline {
  my $self = shift;
  $self->Net::Cmd::getline(@_);
}

1;

__END__

=head1 NAME

Net::POP3S - SSL/STARTTLS support for Net::POP3

=head1 SYNOPSYS

    use Net::POP3S;

    my $ssl = 'ssl';   # 'ssl' / 'starttls'|'stls' / undef

    my $pop3 = Net::POP3S->new("pop.example.com", Port => 995, doSSL => $ssl);

=head1 DESCRIPTION

This module implements a wrapper for Net::POP3, enabling over-SSL/STARTTLS support.
This module inherits all the methods from Net::POP3. You may use all the friendly
options that came bundled with Net::POP3.
You can control the SSL usage with the options of new() constructor method.
'doSSL' option is the switch, and, If you would like to control detailed SSL settings,
you can set SSL_* options that are brought from IO::Socket::SSL. Please see the
document of IO::Socket::SSL about these options detail.

Just one method difference from the Net::POP3, you may select POP AUTH mechanism
as the third option of auth() method.

=head1 METHODS

Most of all methods of Net::POP3 are inherited as is, except auth().


=over 4

=item auth ( USERNAME, PASSWORD [, AUTHMETHOD])

Attempt SASL authentication through Authen::SASL module. AUTHMETHOD is your required
method of authentication, like 'CRAM-MD5', 'LOGIN', ... etc. the default is 'CRAM-MD5'.

=back

=head1 SEE ALSO

L<Net::POP3>,
L<IO::Socket::SSL>,
L<Authen::SASL>

=head1 AUTHOR

Tomo.M E<lt>tomo at cpan orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Tomo.M

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
