package SMS::Send::BulkSMS;

use strict;
use warnings;

$SMS::Send::BulkSMS::VERSION = '0.02';

# ABSTRACT: SMS::Send driver for the International BulkSMS service

use Carp;
use HTTP::Tiny;

use base 'SMS::Send::Driver';

sub new {
    my ($class, %args) = @_;
    my $self = \%args;

    $self->{$_}
        or croak "$_ missing"
            for qw( _login _password );

    $self->{_http} = HTTP::Tiny->new();

    $self->{_verbose} = 0 unless exists $self->{_verbose};

    return bless $self, $class;
}

sub send_sms {
    my ($self, %args) = @_;

    # remove leading +
    ( my $recipient = $args{to} ) =~ s/^\+//;

    my $message = $args{text};

    my $response = $self->{_http}->post_form(
        'https://bulksms.vsms.net/eapi/submission/send_sms/2/2.0',
        {
            username     => $self->{_login},
            password     => $self->{_password},
            msisdn       => $recipient,
            message      => $message,
        },
    );

    # Fatal error
    croak $response->{content}
        unless $response->{success};
        
    my ($result_code, $result_string, $batch_id) = split(/\|/, $response->{content});

    if ($result_code eq '0') {
        warn "send_sms succeeded: $batch_id" if $args{_verbose};
        return 1;
    }
    else {
        warn "send_sms failed: $result_code, $result_string" if $args{_verbose};
        return 0;
    }
    print "\n";

    croak "Can't parse response from BulkSMS API";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SMS::Send::BulkSMS - SMS::Send driver for the International BulkSMS service

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use SMS::Send;
    my $sender = SMS::Send->new('BulkSMS',
        _login    => 'foo',
        _password => 'bar',
    );

    my $sent = $sender->send_sms(
        'text'    => 'This is a test message',
        'to'      => '+55 (19) 1234 5678',
    );

    # Did the send succeed.
    if ( $sent ) {
        print "Message sent ok\n";
    } else {
        print 'Failed to send message\n";
    }

=head1 DESCRIPTION

This module currently uses the L<HTTP API|http://www.bulksms.com/>.

=head1 METHODS

=head2 send_sms

It is called by L<SMS::Send/send_sms> and passes all arguments starting with an
underscore to the request having the first underscore removed as shown in the
SYNOPSIS above.

It returns a boolean value telling if the message was successfully sent or not.

It throws an exception if a fatal error like a http timeout in the underlying
connection occurred.

=head1 AUTHOR

Mario Celso Teixeira <marioct37@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) CPqD 2016 by Mario Celso Teixeira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
