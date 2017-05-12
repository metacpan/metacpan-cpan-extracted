use strict;
use warnings;
package SMS::Send::AT::TMobile;
$SMS::Send::AT::TMobile::VERSION = '0.002';
# ABSTRACT: SMS::Send driver for the T-Mobile Austria SMSC service

use Carp;
use HTTP::Tiny;

use base 'SMS::Send::Driver';


sub new {
    my $class = shift;
    my $self = { @_ };

    $self->{$_}
        or croak "$_ missing"
            for qw( _login _password );

    return bless $self, $class;
}

sub send_sms {
    my ($self, %args) = @_;

    defined $args{_from}
        or croak "_from missing";

    my $http = HTTP::Tiny->new( timeout => 3 );

    # default to numeric sender id
    my $oa_ton = 1;
    my $oa_npi = 1;
    # alphanumerical sender id
    if ( $args{_from} !~ /^\d+$/ ) {
        $oa_ton = 5;
        $oa_npi = 0;
    }
    # the API expects the recipient without a leading +
    ( my $to = $args{to} ) =~ s/^\+//;

    my $response = $http->post_form(
        'http://213.162.67.5/cgi-bin/sendsms.fcgi',
        [
            id          => $self->{_login},
            passwd      => $self->{_password},
            rcpt_req    => 0,
            # sender
            oa          => $args{_from},
            oa_ton      => $oa_ton,
            oa_npi      => $oa_npi,
            # recipient
            da          => $to,
            da_ton      => 1,
            da_npi      => 1,
            text        => $args{text},
        ]
    );

    # for example a timeout error
    die $response->{content}
        unless $response->{success};

    # known response messages:
    # +OK 01  message(s) successfully sent to 43676012345678:msgid=0::
    # -ERR 04 Currently unavailable ::
    # -ERR 20 Unknown error ::
    return 1
        if $response->{content} =~ /^\+OK 01/;

    $@ = {
        as_string => $response->{content},
    };

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SMS::Send::AT::TMobile - SMS::Send driver for the T-Mobile Austria SMSC service

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use SMS::Send;
    my $sender = SMS::Send->new('AT::TMobile',
        _login    => 'foo',
        _password => 'bar',
    );

    my $sent = $sender->send_sms(
        '_from' => '43676123456789' || 'CUSTOMTEXT',
        'to'    => '43676012345678',
        'text'  => 'This is a test message',
    );

    # Did the send succeed.
    if ( $sent ) {
        print "Message sent ok\n";
    } else {
        print 'Failed to send message: ', $@->{as_string}, "\n";
    }

=head1 METHODS

=head2 send_sms

Is called by L<SMS::Send/send_sms> and takes the additional argument '_from'
which defines the sender phone number or text.

Returns true if the message was successfully sent.

Returns false if an error occurred and $@ is set to a hashref of the following info:

    {
        as_string  => '', # HTTP POST response as a string
    }

Throws an exception if a fatal error like a http timeout in the underlying
connection occurred.

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
