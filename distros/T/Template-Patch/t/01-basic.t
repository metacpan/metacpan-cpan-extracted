#!perl -T

use strict;
use warnings;

use File::Spec;
use Test::Exception;

use Test::More tests => 9;

our $FS = "File::Spec";

BEGIN {
    use_ok( 'Template::Patch' );
}

dies_ok { Template::Patch->new_from_file("no_such_file") }
        "can't read from metapatch file that doesn't exist";

{
    my $tp;

    lives_ok { $tp = Template::Patch->new_from_file($FS->catfile(qw/t basic1.mp/)); }
            "construct patch object with .mp file";

    isa_ok $tp, "Template::Patch", "has correct type";

    my $doc = <<'.';
I went to the doctor and guess what he told me.

Say AAAHHH!
.

    lives_ok { $tp->extract($doc) } "patch extraction lives";
    lives_ok { $tp->patch($doc) }   "patch application lives";

    (my $expected = $doc) =~ s/AAA/BBB/;

    is ${$tp->routput}, $expected, "patch applied correctly";
}


{
    my $tp = Template::Patch->new_from_file($FS->catfile(qw/t basic1.mp/));
    isa_ok $tp, "Template::Patch", "has correct type - 2";

    my $doc = my $expected = <<'.';
This document contains no triple As.

The patch application should not change anything in it.
.

    $tp->extract($doc);
    $tp->patch($doc);

    is ${$tp->routput}, $expected, "patch applied correctly (did not ruin original)";
}


# vim: ts=4 et ft=perl :
