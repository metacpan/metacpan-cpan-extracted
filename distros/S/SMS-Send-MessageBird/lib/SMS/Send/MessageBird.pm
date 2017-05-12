package SMS::Send::MessageBird;

use 5.006;
use strict;
use warnings;

use parent 'SMS::Send::Driver';

use SMS::MessageBird;

=head1 NAME

SMS::Send::MessageBird - SMS::Send driver for the SMS::MessageBird distribution.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

Enables sending of SMS messages with the SMS::Send distribution using
MessageBird's API as the providing gateway via the SMS::MessageBird
distribution.

    use SMS::Send;
    use SMS::Send::MessageBird;

    my $messagebird = SMS::Send->new(
        'SMS::Send::MessageBird',
        _api_key    => 'test_ABCDEF123456',
        _originator => 'James Ronan',
    );
    $messagebird->send_sms(
        text => 'Hi, How are you?',
        to   => '+441234567890',
    );


=head1 DESCRIPTION

SMS::Send Driver for the SMS::MessageBird distribution - provides a simple
interface for SMS sending via MessageBird.

This module isn't designed to be used on its own. Please see L<SMS::Send>
for more information.


=head1 METHODS


=head2 new (constructor)

=cut

sub new {
    my ($class, %params) = @_;

    my $self = bless {
        api_key     => $params{_api_key},
    }, $class || 'SMS::Send::MessageBird';

    $self->{messagebird} = SMS::MessageBird->new(
        api_key => $self->{api_key},
    );

    # For the optional accepted constructor params for SMS::MessageBird - if
    # we've been passed them, give them to SMS::MessageBird.
    for my $messagebird_param (qw( originator api_url )) {
        if (exists $params{ "_$messagebird_param" }) {
            $self->{messagebird}->$messagebird_param(
                $params{ "_$messagebird_param" }
            );
        }
    }

    return $self;
}


=head2 send_sms

Sends an SMS via MessageBird.

As there are a whole host of optional parameters that can be passed to the
MessageBird API, along with the required parameters, an additional '_parameters'
key can be passed containing a hash of those options.

=over

=item to

Required. This is mapped to SMS::MessageBird's recipients parameter. Due to the
way SMS::Send works, it will accept only a single recipient.

=item text

Required. This is mapped to SMS::MessageBird's body parameter. It should contain
the content of the message you wish to send.

=item _parameters

Optional. This should be a hashref of the extra parameters you wish to pass to
SMS::MessageBird.

The one exception to the "optional" status is be the originator parameter, If
you don't pass _originator to the SMS::Send constructor then you must provide
it via the _parameters hashref.

=back

=cut

sub send_sms {
    my ($self, %params) = @_;

    my %messagebird_params = (
        recipients => $params{to},
        body       => $params{text},
    );

    if (exists $params{_parameters}) {
        %messagebird_params = (
            %messagebird_params,
            %{ $params{_parameters} },
        );
    }

    my $response = $self->{messagebird}->sms->send(%messagebird_params);

    return $response->{ok};
}


=head1 AUTHOR

James Ronan, C<< <james at ronanweb.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sms-send-messagebird at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Send-MessageBird>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

Alternatively you can raise an issue on the source code which is available on
L<GitHub|https://github.com/jamesronan/SMS-Send-MessageBird>.


=head1 LICENSE AND COPYRIGHT

Copyright 2016 James Ronan.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1; # End of SMS::Send::MessageBird

