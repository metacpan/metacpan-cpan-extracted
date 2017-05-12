package SMS::Send::BR::Facilitamovel;

use strict;
use warnings;

$SMS::Send::BR::Facilitamovel::VERSION = '0.03';

# ABSTRACT: SMS::Send driver for the Facilita Movel SMS service

use Carp;
use HTTP::Tiny;
use URI::Escape qw( uri_escape );

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
        'https://www.facilitamovel.com.br/api/simpleSend.ft',
        {
            user         => $self->{_login},
            password     => $self->{_password},
            destinatario => $recipient,
            msg          => $message,
        },
    );

    # Fatal error
    croak $response->{content}
        unless $response->{success};

    # If the POST succeeds we get the status of the operation in the
    # response content as a numeric ID, a message, and optional
    # information. All fields are separated by semicolons.
    if (my ($sid, $sinfo) = split /;/, $response->{content}, 2) {
        if ($sid < 5) {
            # All sids less than 5 signal errors
            warn "send_sms failed: $sid;$sinfo" if $args{_verbose};
            return 0;
        } else {
            warn "send_sms succeeded: $sid;$sinfo" if $args{_verbose};
            return 1;
        }
    }

    croak "Can't parse response from Facilitamovel API";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SMS::Send::BR::Facilitamovel - SMS::Send driver for the Facilita Movel service

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use SMS::Send;
    my $sender = SMS::Send->new('BR::Facilitamovel',
        _login    => 'foo',
        _password => 'bar',
    );

    my $sent = $sender->send_sms(
        'text'    => 'This is a test message',
        'to'      => '19991913030',
    );

    # Did the send succeed.
    if ( $sent ) {
        print "Message sent ok\n";
    } else {
        print 'Failed to send message\n";
    }

=head1 DESCRIPTION

This module currently uses the L<HTTP API|https://www.facilitamovel.com.br>.

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
