use strict;
use warnings;
use Test::More;
use Test::More::Diagnostic;
plan tests => 17;

use HTML::Tiny;
use TAP::Parser;
use TAP::Parser::Aggregator;
use TAP::Formatter::TextMate;
use TAP::Formatter::TextMate::Session;

package TFT::Capture;

our @ISA = qw( TAP::Formatter::TextMate );

sub _raw_output {
    my $self = shift;
    push @{ $self->{_out} ||= [] }, join '', @_;
}

sub get_output {
    my $self = shift;
    my @out  = @{ $self->{_out} };
    @{ $self->{_out} } = ();
    return @out;
}

package main;

sub unquery {
    my $qs = shift;
    my %q  = ();

    my $h = HTML::Tiny->new;

    for my $part ( split /&/, $qs ) {
        my ( $n, $v ) = split /=/, $part, 2;
        $q{ $h->url_decode( $n ) } = $h->url_decode( $v );
    }

    return \%q;
}

my $tap = do { local $/; <DATA> };
my @tests = ( 't/quark.t' );

{
    my $formatter = TFT::Capture->new();
    isa_ok $formatter, 'TAP::Formatter::TextMate';
    isa_ok $formatter, 'TAP::Formatter::Console';
}

{
    my $aggregate = TAP::Parser::Aggregator->new;
    isa_ok $aggregate, 'TAP::Parser::Aggregator';

    my $formatter = TFT::Capture->new;
    $formatter->prepare( @tests );
    $aggregate->start;

    my $parser = TAP::Parser->new( { tap => $tap } );
    isa_ok $parser, 'TAP::Parser';

    my $session = $formatter->open_test( $tests[0], $parser );

    while ( defined( my $result = $parser->next ) ) {
        $session->result( $result );
    }

    $session->close_test;

    $aggregate->add( $tests[0], $parser );

    my @got  = $formatter->get_output;
    my @want = (
        [ 'not ok 2 Oops', { line => 123, url => 'file:///path/t/quark.t' } ],
        [
            'not ok 4 Oops again',
            { line => 129, url => 'file:///path/t/quark.t' }
        ],
        [ 'not ok 5 No YAML on this one', { url => 'file:///path/t/quark.t' } ]
    );

    my $like = qr{^<span\s+class="fail"> (.+?)
       \s+ \( <a\s+href="txmt://open\? 
       (.+?) ">go</a>\)</span><br\s+/>}x;

    for my $span ( grep { /^<span\s+class=\"fail\">/ } @got ) {
        like $span, $like, "Output matches";
        $span =~ $like;
        my ( $msg, $qs ) = ( $1, $2 );
        ok my $spec = shift @want, "more input";
        is $msg, $spec->[0], "message matches";
        $qs =~ s/&amp;/&/g;
        my $query = unquery( $qs );
        $query->{url} =~ s{^(file://)/.*?(t/quark.t)$}{$1/path/$2};
        is_deeply $query, $spec->[1], "query string matches";
        # use Data::Dumper;
        # diag Dumper( $query );
    }

    ok !@want, "all expected input seen";

    # use Data::Dumper;
    # diag Dumper( \@got );
}

__DATA__
TAP version 13
1..5
ok 1 This is fine
not ok 2 Oops
# Just to confuse things
  ---
  file: t/quark.t
  line: 123
  ...
ok 3 This is OK too
not ok 4 Oops again
  ---
  file: t/quark.t
  line: 129
  ...
not ok 5 No YAML on this one
EOT
