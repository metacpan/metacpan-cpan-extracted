package Net::APP;

use strict;
use vars qw($VERSION $APP_VERSION @ISA $AUTOLOAD);
use Carp;
use IO::Socket;
use Net::Cmd;
#use Text::CSV_XS;

$VERSION = '0.2'; # $Id: APP.pm,v 1.3 2001/11/09 21:58:40 ivan Exp $
$APP_VERSION = '3.3';

@ISA = qw(Net::Cmd IO::Socket::INET);

=head1 NAME

Net::APP - Critical Path Account Provisioning Protocol

=head1 SYNOPSIS

  use Net::APP;

  #constructor
  $app = new Net::APP ( 'host:port',
                        User     => $user,
                        Domain   => $domain,
                        Password => $password,
                        Timeout  => 60,
                        Debug    => 1,
                      ) or die $@;

  #commands
  $app->ver( 'ver' => $Net::APP::APP_VERSION );
  $app->login ( User     => $user,
                Domain   => $domain,
                Password => $password,
              );

  $app->create_domain ( Domain => $domain );
  $app->delete_domain ( Domain => $domain );
  #etc. (see the Account Provisioning Protocol Developer's Guide, section 3.3)

  #command status
  $message = $app->message;
  $code = $app->code;
  $bool = $app->ok();

  #destructor
  $app->close();

=head1 DESCRIPTION

This module implements a client interface to Critical Path's Account
Provisioning Protocol, enabling a perl application to talk to APP servers.
This documentation assumes that you are familiar with the APP protocol
documented in the Account Provisioning Protocol Developer's Guide.

A new Net::APP object must be created with the I<new> method.  Once this has
been done, all APP commands are accessed via method calls on the object.

=head1 METHODS

=over 4

=item new ( HOST:PORT [ , OPTIONS ] )

This is the constructor for a new Net::APP object.  C<HOST> and C<PORT>
specify the host and port to connect to in cleartext.  Typically this
connection is proxied via Safe Passage Secure Tunnel or Stunnel
http://www.stunnel.org/ using a command such as:

 stunnel -P none -c -d 8888 -r your.cp.address.and:port

This method will connect to the APP server and execute the I<ver> method.

I<OPTIONS> are passed in a hash like fastion, using key and value pairs.
Possible options are:

I<Timeout> - Set a timeout value (defaults to 120)

I<Debug> - Enable debugging information (see the debug method in L<Net::Cmd>)

I<User>, I<Domain>, I<Password> - if these exist, the I<new> method will also
execute the I<login> method automatically.

If the constructor fails I<undef> will be returned and an error message will be
in $@.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my ($host, $port) = split(/:/, shift);
  my %arg = @_;

  my $self = $class->SUPER::new( PeerAddr => $host,
                                PeerPort => $port,
                                Proto    => 'tcp',
                                Timeout  => defined $arg{Timeout}
                                                    ? $arg{Timeout}
                                                    : 120
                              ) or return undef;

  $self->autoflush(1);

  $self->debug(exists $arg{Debug} ? $arg{Debug} : undef);

  my $response = $self->_app_response;
  unless ( $self->message =~ /^HI APP/ ) {
    $@ = $self->code. " ". $self->message;
    $self->close();
    return undef;
  }

  $self->ver( 'ver' => $APP_VERSION );
  unless ( $self->ok ) {
    $@ = $self->code. " ". $self->message;
    $self->close();
    return undef;
  }

  if ( exists $arg{User} && exists $arg{Domain} && exists $arg{Password} ) {
    $self->login( User     => $arg{User},
                  Domain   => $arg{Domain},
                  Password => $arg{Password},
                );
    unless ( $self->ok ) {
      $@ = $self->code. " ". $self->message;
      $self->close();
      return undef;
    }
  }

  $self;
}

=item ver

=item login

=item create_domain

=item delete_domain

=item etc.

See the Account Provisioning Protocol Developer's Guide for details.  Commands
need not be in upper case, and options are passed in a hash-like fashion, as
a list of key-value pairs.

Unless noted below, all commands return a reference to a list containing the
lines of the reponse, or I<undef> upon failure.  The first line is parsed for
the status code and message.  You can check the status code and message using
the normal Net::Cmd I<message>, I<code>, I<ok>, and I<status> methods.

Some methods return additional response information, such as
get_num_domain_mailboxes, get_domain_mailboxes, get_mailbox_availability and
get_mailbox_status methods currently return any additional response
information.  Unless specifically noted below, no attempt is (yet) made to
parse this data.

=item get_domain_mailboxes

Returns an arrayref of arrayrefs, each with three elements: username, mailbox
type, and workgroup.  The protocol calls them: MAILBOX, TYPE, and WORKGROUP.

=cut

sub get_domain_mailboxes {
  my $self = shift;
#  my $command = $AUTOLOAD;
#  $command =~ s/.*://;
  my $command = 'get_domain_mailboxes';
#  my $csv = new Text::CSV_XS;
  $self->_app_command( $command, @_ );
  [ map { chomp; [ map { s/(^"|"$)//g; $_ }
                       split(/(?<=[^"]")\s+(?="[^"])/, $_)
                 ]
        }
        grep { $_ !~ /^,$/ }
             splice( @{$self->_app_response}, 2 ) 
  ];
}

=item get_mailbox_forward_only

Returns the forward email address.

=cut

sub get_mailbox_forward_only {
  my $self = shift;
#  my $command = $AUTOLOAD;
#  $command =~ s/.*://;
  my $command = 'get_mailbox_forward_only';
  $self->_app_command( $command, @_ );

  my $lines = $self->_app_response;

  unless ( $lines->[1] =~ /^FORWARD_EMAIL="([^"]+)"$/ ) {
    warn $lines->[1];
    $self->set_status ( -1, $lines->[0] );
    return undef;
  }

  $1;

}

=item message 

Returns the text message returned from the last command.

=item code

Returns the response code from the last command (see the Account Provisioning
Protcol Developer's Guide, chapter 4).  The code `-1' is used to represent
unparsable output from the APP server, in which case the entire first line
of the response is returned by the I<messsage> method.

=item ok

Returns true if the last response code was not an error.  Since the only
non-error code is 0, this is just the negation of the code method.

=cut

sub ok {
  my $self = shift;
  ! $self->code();
}

=item status

Since the APP protocol has no concept of a "most significant digit" (see
L<Net::Cmd/status>), this is a noisy synonym for I<code>.

=cut

sub status {
  carp "status method called (use code instead)";
  my $self = shift;
  $self->code();
}

sub AUTOLOAD {
  my $self = shift;
  my $command = $AUTOLOAD;
  $command =~ s/.*://;
  $self->_app_command( $command, @_ );
  $self->_app_response;
}

=back

=head1 INTERNAL METHODS

These methods are not intended to be called by the user.

=over 4

=item _app_command ( COMMAND [ , OPTIONS ] )

Sends I<COMMAND>, encoded as per the Account Provisioning Protocol Developer's
Guide, section 3.2.  I<OPTIONS> are passed in a hash like
fashion, using key and value pairs.

=cut

sub _app_command {
  my $self = shift;
  my $command = shift;
  my %arg = @_;

  $self->command ( uc($command),
                   map "\U$_\E=\"". _quote($arg{$_}). '"', keys %arg
                 );
  $self->command( '.' );
}

=item _app_response

Gets a response from the server.  Returns a reference to a list containing
the lines, or I<undef> upon failure.  You can check the status code and message
using the normal Net::Cmd I<message>, I<code>, I<ok>, and I<status> methods.

=cut

sub _app_response {
  my $self = shift;
  my $lines = $self->read_until_dot;
  if ( $self->debug ) {
    foreach ( @{$lines}, ".\n" ) { $self->debug_print('', $_ ) }
  }
  if ( $lines->[0] =~ /^(OK|ER)\s+(\d+)\s+(.*)$/ ) {
    warn 'OK response with non-zero status!' if $1 eq 'OK' && $2;
    warn 'ER response with zero status!' if $1 eq 'ER' && ! $2;
    $self->set_status ( $2, $3 );
  } else {
    $self->set_status ( -1, $lines->[0] );
  }
  $lines;
}

=back

=head1 INTERNAL SUBROUTINES

These subroutines are not intended to be called by the user.

=over 4

=item _quote

Doubles double quotes.

=cut

sub _quote {
  my $string = shift;
  $string =~ s/\"/\"\"/g; #consecutive quotes?
  $string;
}

=back

=head1 AUTHOR

Ivan Kohler <ivan-netapp_pod@420.am>.

This module is not sponsored or endorsed by Critical Path.

=head1 COPYRIGHT

Copyright (c) 2001 Ivan Kohler.
All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 PROTOCOL VERSION

This module currently implements APP v3.3, as documented in the Account
Provisioning Protocol Developers Guide v3.3.

=head1 BUGS

The Account Provisioning Protocol Developer's Guide is not publicly available.

It appears that Safe Passage Secure Tunnel and Stunnel establish standard SSL 
connections.  It should be possible to use Net::SSLeay and connect to the APP
server directly.  Initial prototyping with IO::Socket::SSL was not promising. :(

The get_num_domain_mailboxes, get_mailbox_availability and get_mailbox_status
methods currently return response information.  No attempt is (yet) made to
parse this data.

=head1 SEE ALSO

Critical Path <http://www.cp.net/>,
APP documentation <http://support.cp.net/products/email_messaging/documentation/index.jsp>,
Safe Passage Secure Tunnel <http://www.int.c2.net/external/?link=spst/index.php3>,
Stunnel <http://www.stunnel.org>,
L<IO::Socket>, L<Net::Cmd>, perl(1).

=cut

1;

