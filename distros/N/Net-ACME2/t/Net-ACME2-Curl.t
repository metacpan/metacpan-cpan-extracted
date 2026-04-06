#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

# _imitate_http_tiny is not exported, so we call it via full package name.
# Net::ACME2::Curl requires Net::Curl::Easy (optional XS dep) at compile
# time, so skip the entire test when it is not installed.

use Net::ACME2::X;

BEGIN {
    eval { require Net::ACME2::Curl; 1 }
        or plan skip_all => 'Net::Curl::Easy not available';
}

# Minimal mock that stands in for a Net::Curl::Easy instance.
{
    package    # hide from PAUSE
      MockEasy;

    sub new {
        my ( $class, %opts ) = @_;
        return bless \%opts, $class;
    }

    sub getinfo {
        my ( $self, $key ) = @_;

        # Only two keys are used: RESPONSE_CODE and EFFECTIVE_URL.
        # We distinguish them by value rather than importing constants.
        return $self->{response_code} if $key == 0x00200002;    # CURLINFO_RESPONSE_CODE
        return $self->{effective_url} if $key == 0x00100001;    # CURLINFO_EFFECTIVE_URL
        die "MockEasy::getinfo: unknown key $key";
    }
}

# --- happy path: valid status line ----------------------------------------

{
    my $easy = MockEasy->new(
        response_code => 200,
        effective_url => 'https://example.com/acme',
    );

    my $head = "HTTP/1.1 200 OK\r\ncontent-type: application/json\r\n";
    my $body = '{"status":"valid"}';

    my $resp = Net::ACME2::Curl::_imitate_http_tiny( $easy, $head, $body );

    is $resp->{status},  200,   'status from valid response';
    is $resp->{reason},  'OK',  'reason parsed from status line';
    is $resp->{content}, $body, 'body passed through';
    is $resp->{headers}{'content-type'}, 'application/json', 'header parsed';
}

# --- unparseable status line: must throw, not silently continue ------------

sub test_unparseable_status_line_throws {
    my $easy = MockEasy->new(
        response_code => 200,
        effective_url => 'https://example.com/acme',
    );

    # A garbage first line that does not match "PROTO STATUS REASON".
    my $head = "GARBAGE\r\ncontent-type: text/plain\r\n";
    my $body = 'irrelevant';

    # Before the fix this would only warn and return a response with an
    # empty reason — silently corrupting the parsed result.  After the fix
    # it must die with a structured exception.
    throws_ok {
        Net::ACME2::Curl::_imitate_http_tiny( $easy, $head, $body );
    }
    qr/[Uu]nparsable.*header/i,
        'unparseable status line throws instead of warning';
}

test_unparseable_status_line_throws();

# --- empty header block: reason stays undef / does not crash ---------------

{
    my $easy = MockEasy->new(
        response_code => 0,
        effective_url => 'https://example.com/acme',
    );

    # Completely empty header — split produces no lines.
    my $resp = Net::ACME2::Curl::_imitate_http_tiny( $easy, q<>, 'body' );

    is $resp->{reason}, undef, 'empty header yields undef reason (no crash)';
}

done_testing();
