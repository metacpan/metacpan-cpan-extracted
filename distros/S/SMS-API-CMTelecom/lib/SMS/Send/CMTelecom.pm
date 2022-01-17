package SMS::Send::CMTelecom;

use strict;
use warnings;
use Carp;
use SMS::API::CMTelecom;

use base 'SMS::Send::Driver';

$SMS::Send::CMTelecom::VERSION = '0.05';

sub new {
    my ($class, %args) = @_;
    my $self = \%args;

    croak '_producttoken missing' if not exists $self->{_producttoken};

    $self->{_sms} = SMS::API::CMTelecom->new(
        product_token => $self->{_producttoken},
    );

    $self->{_verbose} = 0 unless exists $self->{_verbose};

    return bless $self, $class;
}

sub send_sms {
    my ($self, %args) = @_;

    # remove leading +
    ( my $recipient = $args{to} ) =~ s/^\+//;

    my $response = $self->{_sms}->send(
        message    => $args{text},
        recipients => $recipient,
        exists $args{reference} ? (reference => $args{reference}) : (),
        exists $args{_from}     ? (sender    => $args{_from})     : (),
    );

    if (defined $response) {
        warn "send_sms succeeded: ".$response->{messages}->[0]->{parts} if $args{_verbose};
        return 1;
    }
    warn "send_sms failed: ".$self->{_sms}->error_message if $args{_verbose};
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SMS::Send::CMTelecom - SMS::Send driver for the CMTelecom SMS gateway

=head1 SYNOPSIS

    use SMS::Send;
    my $sender = SMS::Send->new('CMTelecom',
        _producttoken => '00000000-0000-0000-0000-000000000000',
    );

    my $sent = $sender->send_sms(
        'text'    => 'This is a test message',
        'to'      => '+55 (19) 1234 5678',
        '_from'   => '+55 (18) 1234 5678',
    );

    # Did the send succeed.
    if ( $sent ) {
        print "Message sent ok\n";
    } else {
        print 'Failed to send message\n";
    }

=head1 DESCRIPTION

This module currently uses the L<HTTPS JSON API|https://gw.cmtelecom.com/>.

=head1 METHODS

=head2 new

    # Create new sender using this driver.
    my $sender = SMS::Send::->new('CMTelecom',
        _producttoken => '00000000-0000-0000-0000-000000000000',
    );

=over

=item _producttoken

The C<_producttoken> param is a mandatory parameter which is needed to authenticate
against the CMTelecom messaging gateway.

=back

=cut

=head2 send_sms

It is called by L<SMS::Send/send_sms> and passes all arguments starting with an
underscore to the request having the first underscore removed as shown in the
SYNOPSIS above.

It returns a boolean value telling if the message was successfully sent or not.

It throws an exception if a fatal error like a http timeout in the underlying
connection occurred.

=head1 BUGS AND SUPPORT

Please report any bugs or feature requests on Github: L<https://github.com/sonntagd/SMS-API-CMTelecom/issues>


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Dominic Sonntag.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut
