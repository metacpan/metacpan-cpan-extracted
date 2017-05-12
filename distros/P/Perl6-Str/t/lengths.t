use strict;
use warnings;
use Test::More tests => 9;
use lib '../lib';
use lib 'lib';

use charnames qw(:full);

use Perl6::Str;

my @tests = (
    [ abc  => 3, 3, 3 ],
    [ chr(299), 2, 1, 1, 'chr(299)'],
    # XXX is the byte number correct here?
    [ "A\N{COMBINING DIAERESIS}", 2, 2, 1, 'A\N{COMBINING DIAERESIS}']
);

for my $test_spec (@tests){
    my ($subj, $bytes, $codes, $graphs, $desc) = @$test_spec;
    $desc ||= $subj;
    my $x = Perl6::Str->new($subj);

    is $x->bytes,  $bytes,  "$desc has $bytes bytes";
    is $x->codes,  $codes,  "$desc has $codes codepoints";
    is $x->graphs, $graphs, "$desc has $graphs graphemes";
};
