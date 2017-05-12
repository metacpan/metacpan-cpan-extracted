#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use RTF::Parser;

SKIP: {
    eval { require IO::Scalar };
    skip "IO::Scalar not installed", 1 if $@;

    my $string = "asdf\n";

    my $fh = new IO::Scalar \$string;

    {
        no warnings 'redefine';
        *RTF::Parser::text =
            sub { my $self = shift; $self->{_TEST_BUFF} = shift; };
    }

    my $parser = RTF::Parser->new();

    $parser->parse_stream($fh);

    is( $parser->{_TEST_BUFF}, "asdf", 'Data read from stream' );

}
