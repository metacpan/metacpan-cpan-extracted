package SMS::Send::BudgetSMS;

use strict;
use warnings FATAL => 'all';

use LWP::UserAgent;
use Number::Phone::Normalize;

use base 'SMS::Send::Driver';

our $VERSION = '0.05';

sub new {
    my ( $class, %args ) = @_;

    unless ( $args{'_login'} && $args{'_password'} && $args{'_userid'} ) {
        die '_login, _password and _userid are required';
    }

    my $self = bless {
        _endpoint  => 'https://api.budgetsms.net/sendsms/',
        _timeout   => 20,
        %args
    }, $class;

    $self->{_ua} = LWP::UserAgent->new(
        agent => join( '/', $class, $VERSION ),
        timeout => $self->{_timeout}
    );

    return $self;
}

sub send_sms {
    my ( $self, %args ) = @_;

    unless ( $args{'to'} && $args{'text'} ) {
        die 'to and text are required';
    }

    if ( !$args{'_from'} && !$self->{'_from'} ) {
        die 'SMS::Send::BudgetSMS->new() or send_sms() requires parameter _from';
    }

    my $to_number = Number::Phone::Normalize->new(
        IntlPrefix => '+'
    )->intl( $args{'to'} );
    $to_number =~ s/^\+//;

    my $res = $self->{_ua}->post(
        $self->{'_endpoint'},
        Content => {
            username => $self->{'_login'}, # field 'username' in HTTP API
            userid   => $self->{'_userid'},
            handle   => $self->{'_password'}, # field 'handle'   in HTTP API
            msg      => $args{'text'},
            from     => $args{'_from'} || $self->{'_from'},
            to       => $to_number,
        },
    );

    return $res->decoded_content if ($res->decoded_content =~ m/^OK \d*$/);

    return 0;
}

1;

=pod

=for stopwords ACKNOWLEDGEMENTS CPAN Centre Unicode homepage

=head1 NAME

SMS::Send::BudgetSMS - SMS::Send driver to send messages via BudgetSMS, L<https://www.budgetsms.net/>

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  use SMS::Send;

  # Create a sender
  my $sender = SMS::Send->new(
      'BudgetSMS',
      _login    => 'budgetsms_username',
      _userid   => 'budgetsms_userid',
      _password => 'budgetsms_handle',
  );

  # Send a message
  my $sent = $sender->send_sms(
      text => 'This is a test message',
      to   => '+61 (4) 1234 5678',
  );

  if ($sent) {
      print "Message sent ok\n";
  }
  else {
      print "Failed to send message\n";
  }

=head1 DESCRIPTION

SMS::Send driver for BudgetSMS - L<https://www.budgetsms.net/>

This is not intended to be used directly, but instead called by SMS::Send (see
synopsis above for a basic illustration, and see SMS::Send's documentation for
further information).

The driver uses the BudgetSMS HTTP API mechanism.  This is documented at
L<https://www.budgetsms.net/sms-http-api/send-sms/>

=head1 METHODS

=head2 new

Constructor, takes argument pairs passed by SMS::Send, returns an
SMS::Send::BudgetSMS object.  See usage synopsis for example, and see SMS::Send
documentation for further info on using SMS::Send drivers.

Additional arguments that may be passed include:-

=over 3

=item _userid

BudgetSMS userid

=item _endpoint

The HTTP API endpoint. Defaults to
C<https://api.budgetsms.net/sendsms/>

For development purposes, you may also use test API
C<https://api.budgetsms.net/testsms/>

=item _timeout

The timeout in seconds for HTTP operations. Defaults to 20 seconds.

=back

=head2 send_sms

Send the message - see SMS::Send for details.  Additionally the following
options can be given - these have the same meaning as they do in the C<new>
method:-

=over 1

=item _from

Alphanumeric or Numeric senderid (shown as the sender of SMS)

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through GitHub
 at L<https://github.com/Hypernova-Oy/SMS-Send-BudgetSMS/issues>.

=head1 AVAILABILITY

The project homepage is L<https://github.com/Hypernova-Oy/SMS-Send-BudgetSMS>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/SMS::Send::BudgetSMS/>.

=head1 AUTHOR

Lari Taskula <lari.taskula@hypernova.fi>
Hypernova Oy, L<https://www.hypernova.fi>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Hypernova Oy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
