#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most tests => 5;
use Pod::Parser::Groffmom;

my $parser;

subtest 'constructor' => sub {
    plan tests => 2;
    can_ok 'Pod::Parser::Groffmom', 'new';
    $parser = Pod::Parser::Groffmom->new;
    isa_ok $parser, 'Pod::Parser::Groffmom', '... and the object it returns';
};

subtest 'trim' => sub {
    plan tests => 2;
    can_ok $parser, '_trim';
    my $text = <<'    END';

this is
 text

    END
    is $parser->_trim($text), "this is\n text",
      '... and it should remove leading and trailing whitespace';
};

subtest 'escape' => sub {
    plan tests => 2;
    can_ok $parser, '_escape';
    is $parser->_escape('Curtis "Ovid" Poe'), 'Curtis \\[dq]Ovid\\[dq] Poe',
      '... and it should properly escape our data';
};

subtest 'interior sequences' => sub {
    plan tests => 6;
    my $seq = Pod::InteriorSequence->new(
        -name   => 'unknown',
        -ldelim => '<'
    );
    can_ok $parser, 'interior_sequence';

    is $parser->interior_sequence( 'I', 'italics', $seq ),
      '\\f[I]italics\\f[P]', '... and it should render italics correctly';
    is $parser->interior_sequence( 'B', 'bold', $seq ),
      '\\f[B]bold\\f[P]', '... and it should render bold correctly';
    is $parser->interior_sequence( 'C', 'code', $seq ),
      '\\f[C]code\\f[P]', '... and it should render code correctly';
    my $result;
    warning_like {
        $result = $parser->interior_sequence( '?', 'unknown', $seq );
    }
    qr/^Unknown sequence \Q(?<unknown>)\E/,
      'Unknown sequences should warn correctly';
    is $result, 'unknown', '... but still return the sequence interior';
};

subtest 'textblock' => sub {
    plan tests => 2;
    my $text = <<'    END';
This is some text with
  an embedded C<code> block.
    END
    my $expected = <<'    END';
This is some text with   an embedded \f[C]code\f[P] block.

    END
    can_ok $parser, 'textblock';
    eq_or_diff $parser->textblock( $text, 2, 3 ), $expected,
      '... and it should parse textblocks correctly';
};
