package SMS::MessageBird;

use 5.006;
use strict;
use warnings;

use LWP::UserAgent;
use JSON;

use SMS::MessageBird::API::SMS;
use SMS::MessageBird::API::Voice;
use SMS::MessageBird::API::Verify;
use SMS::MessageBird::API::HLR;
use SMS::MessageBird::API::Balance;
use SMS::MessageBird::API::Lookup;

=head1 NAME

SMS::MessageBird - SMS sending module that uses the MessageBird gateway.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

This module is a Perl interface for interacting with the MessageBird SMS
Gateway API.

    use SMS::MessageBird;

    my $messagebird = SMS::MessageBird->new(
        api_key    => 'test_abcdefghijklmnopqrstuvwxyz',
        originator => 'Me!', # Specify here, or use the originator() method.
    );

    # Optional. This can be updated at any time, but only needs to be set once.
    $messagebird->originator('Me!');

    my $result = $messagebird->sms->send(
        recipients => qw( 07123456789 ),
        message    => 'This is my SMS text', # synonym for 'body'
    );

=head1 DESCRIPTION

This module provides a simple Perl interface to the MessageBird JSON API. It
deals with the JSON stuff allowing you to get back useful Perl data.

To use this module you'll need an account with
L<MessageBird|https://www.messagebird.com/>. Once you have that,
you can create an API key on your account and feed it to this module which will
authenticate with their API using that key.

The methods implmented acceept the paramteres as named in the MessageBird API
documentation which can be found at the L<MessageBird Developer Documentation|https://www.messagebird.com/en-gb/developers>.
If you're using this distribution you should be familiar with the API
documentation.

=head2 API Modules

This distribution provides several modules which are used by the
SMS::MessageBird object. Each module implements a section of the api.

Use of the functionality of a given module, is done via the accessor for that
module, thus:

    my $result = $messagebird->sms->send(...);
    my $balance = $messagebird->balance->get();
    ...

=head3 Available Modules

=over

=item sms

This is the accessor for the L<SMS::MessageBird::API::SMS> module. Used for
sending/receiving SMS messages.

=item voice

This is the accessor for the L<SMS::MessageBird::API::Voice> module. Used for
sending/receiving Text-to-Voice messages.

=item verify

This is the accessor for the L<SMS::MessageBird::API::Verify> module. Used to
implement the MessageBird number verification API.

=item hlr

This is the accessor for the L<SMS::MessageBird::API::HLR> module. Used to send
Network Queries to mobile numbers.

=item balance

This is the accessor for the L<SMS::MessageBird::API::Balance> module. Used to
retrieve your MessageBird account balance.

=item lookup

This is the accessor for the L<SMS::MessageBird::API::Lookup> module. Used to
validate phone numbers, and provide optional formats for that number.

=back


=head1 METHODS

=head2 new (contructor)

 In: %params - Various parameters for the API interface.

Creates a new instance of SMS::MessageBird.

=head3 Parameters

Parmeters are passed to the contructor as a hash. Required / acceptable keys
are as follows:

=over

=item api_key

Required. The MessageBird account API key used for authentication with
MessageBird's API.

=item originator

As per the MessageBird documentation, all sending functionality requires an
originator. This can be set once on the SMS::MessageBird object and passed to
all the module methods. This can be set later using the originator() mutator.

=item api_url

If for some reason you need to use some form of local HTTP proxy / forwarder
this parameter can be used to specifiy the alternate address. If it is omittied
the default is MessageBird's URL I<https://rest.messagebird.com>.

=back

=cut

sub new {
    my ($package, %params) = @_;

    if (!%params || !exists $params{api_key} || !$params{api_key}) {
        warn 'No API key suppied to SMS::MessageBird contructor';
        return undef;
    }

    my $self = bless {
        module_data => {
            api_key => $params{api_key},
            api_url => 'https://rest.messagebird.com',
        },
    } => ($package || 'SMS::MessageBird');


    for my $param (qw( originator api_url )) {
        $self->{module_data}{$param}
            = $params{$param} if defined $params{$param};
    }

    # Make sure the api_url doesn't have a trailing slash.
    $self->{module_data}{api_url} =~ s{/$}{};

    $self->_load_modules();

    return $self;
}


=head2 originator

 In: $originator (optional) - New originator to set.
 Out: The currently set originator.

Mutator for the originator parameter. This parameter is the displayed
"From" in the SMS. It can be a phone number (including country code) or an
alphanumeric string of up to 11 characters.

This can be set for the lifetime of the object and used for all messages sent
using the instance or passed individually to each call.

You can pass the originator param to the constructor rather than use this
mutator, but it's here in case you want to send 2 batches of SMS from differing
originiators using the same object.

=cut

sub originator {
    my ($self, $originator) = @_;

    # Set the new originator if one was supplied and reload all the modules
    # with the new data.
    if ($originator) {
        $self->{module_data}{originator} = $originator;
        $self->_load_modules();
    }

    return $self->{module_data}{originator};
}


=head2 api_url

 In: $api_url (optional) - New api_url to set.
 Out: The currently set api_url.

Mutator for the api_ul parameter. Should some form of network relay be required
this can be used to override the default I<https://rest.messagebird.com>.

=cut

sub api_url {
    my ($self, $api_url) = @_;

    # Set the new api_url if one was supplied and reload all the modules
    # with the new data.
    if ($api_url) {
        $api_url =~ s{/$}{};
        $self->{module_data}{api_url} = $api_url;
        $self->_load_modules();
    }

    return $self->{module_data}{api_url};
}



# Internal method to load/reload the associated API modules.

sub _load_modules {
    my ($self) = @_;

    $self->{loaded_modules} = undef;

    my %modules = (
        sms     => 'SMS::MessageBird::API::SMS',
        voice   => 'SMS::MessageBird::API::Voice',
        verify  => 'SMS::MessageBird::API::Verify',
        hlr     => 'SMS::MessageBird::API::HLR',
        balance => 'SMS::MessageBird::API::Balance',
        lookup  => 'SMS::MessageBird::API::Lookup',
    );

    no strict 'refs';
    no warnings 'redefine';

    while (my ($module_name, $module) = each %modules) {
        *{"SMS::MessageBird::$module_name"} = sub {
            $module->new( %{ $self->{module_data} } );
        };
        push @{ $self->{loaded_modules} }, $module;
    }

    use warnings 'redefine';
    use strict 'refs';
}


=head1 AUTHOR

James Ronan, C<< <james at ronanweb.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sms-messagebird at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-MessageBird>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

Alternatively you can raise an issue on the source code which is available on
L<GitHub|https://github.com/jamesronan/SMS-MessageBird>.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 James Ronan.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1; # End of SMS::MessageBird
