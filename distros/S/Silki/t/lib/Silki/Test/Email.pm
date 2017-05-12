package Silki::Test::Email;

use strict;
use warnings;

use Exporter qw( import );

our @EXPORT = qw( clear_emails test_email );

use List::AllUtils qw( first );
use Test::More;

$ENV{EMAIL_SENDER_TRANSPORT} = 'Test';

sub clear_emails {
    Email::Sender::Simple->default_transport()->clear_deliveries();
}

sub test_email {
    my $headers = shift;
    my $html_re = shift;
    my $text_re = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @deliveries = Email::Sender::Simple->default_transport()->deliveries();

    is( scalar @deliveries, 1, 'one email was sent' );

    my $email = $deliveries[0]{email}->cast('Email::MIME');

    for my $header ( sort keys %{$headers} ) {

        my $expect = $headers->{$header};

        if ( ref $expect ) {
            like(
                scalar $email->header($header),
                $expect,
                "$header matches regex"
            );
        }
        else {
            is(
                scalar $email->header($header),
                $expect,
                "$header header is correct"
            );
        }
    }

    my @parts = $email->parts();

    my $html = first { $_->content_type() =~ m{^text/html} } @parts;

    ok( $html, 'found an HTML part' );
    is(
        $html->content_type(),
        'text/html; charset=utf-8',
        'html content type is text/html and includes charset'
    );

    like(
        $html->body(),
        $html_re,
        'html body matches regex'
    );

    my $text = first { $_->content_type() =~ m{^text/plain} } @parts;

    ok( $text, 'found plain text part' );
    is(
        $text->content_type(),
        'text/plain; charset=utf-8',
        'text content type is text/plain and includes charset'
    );

    like(
        $text->body,
        $text_re,
        'plain text body matches regex'
    );
}

1;
