use Regex::PreSuf;

print "1..32\n";

my $test = 1;

sub Tpresuf {
    my ($arg, $want) = @_;

    my ($got) = presuf(@$arg);
    my $ok = $got eq $want;
    shift @$arg if ref $arg->[0] eq 'HASH';
    $got =~ s/\n/\\n/g;
    $got =~ s/\t/\\t/g;
    print <<EOF;
# Test:  $test
# words: @$arg
EOF
    print "not " unless $ok;
    print "ok $test";
    $test++;
    print "\n";
    print <<EOF
# expected: '$want'
EOF
        unless $ok;
    print <<EOF;
# got:      '$got'
EOF
}

Tpresuf([qw(foobar)], 'foobar');
Tpresuf([qw(foopar fooqar)], 'foo[pq]ar');
Tpresuf([qw(foopar fooar)], 'foop?ar');
Tpresuf([qw(foopar fooqar fooar)], 'foo[pq]?ar');
Tpresuf([qw(foobar foozap)], 'foo(?:bar|zap)');
Tpresuf([qw(foobar foobarzap)], 'foobar(?:zap)?');
Tpresuf([qw(foobar barbar)], '(?:bar|foo)bar');
Tpresuf([qw(and at do end for in is not of or use)], '(?:a(?:nd|t)|do|end|for|i[ns]|not|o[fr]|use)');

Tpresuf([{anychar=>1}, qw(foobar foob.r)], 'foob.r');
Tpresuf([{anychar=>1}, qw(bar br .r)], '(?:ba|.)r');

Tpresuf([qw(abc abe adc bac)],'(?:a(?:b[ce]|dc)|bac)');
Tpresuf([{suffixes=>1},qw(abc abe adc bac)],'(?:(?:a[bd]|ba)c|abe)');
Tpresuf([{prefixes=>0},qw(abc abe adc bac)],'(?:(?:ba|ab|ad)c|abe)');

Tpresuf([
        qw(.perl p.erl pe.rl per.l perl. pel .erl erl per. per p.rl prl pe.l)],
        '(?:\.p?erl|erl|p(?:\.e?rl|e(?:\.r?l|r(?:\.l|l\.|\.)|[lr])|rl))');
Tpresuf([{anychar=>1},
        qw(.perl p.erl pe.rl per.l perl. pel .erl erl per. per p.rl prl pe.l)],
        '(?:.p?erl|erl|p(?:.e?rl|e(?:.r?l|r(?:.l|l.|.)|[lr])|rl))');

# The following tests suggested and inspired by Mark Kvale.
Tpresuf([qw(aba a)], 'a(?:ba)?');
Tpresuf([{suffixes=>1},qw(aba a)], '(?:ab)?a');
Tpresuf([qw(ababa aba)], 'aba(?:ba)?');
Tpresuf([qw(aabaa a)], 'a(?:abaa)?');
Tpresuf([qw(aabaa aa)], 'aa(?:baa)?');
Tpresuf([qw(aabaa aaa)], 'aa(?:ba)?a');
Tpresuf([qw(aabaa aaaa)], 'aab?aa');

# The following tests presented by Mike Giroux.
Tpresuf([qw(rattle rattlesnake)], 'rattle(?:snake)?');
Tpresuf([qw(rata ratepayer rater)], 'rat(?:e(?:paye)?r|a)');

# The following tests from Bart Lateur.
Tpresuf(["foo\tbar"], "foo\tbar");
Tpresuf(["foo\nbar"], "foo\nbar");
Tpresuf(["foo\tbar", "foo\nbar"], "foo[\t\n]bar");

# Test quoting.
Tpresuf(["foo\*bar"], "foo\\*bar");
Tpresuf(["foo\+bar"], "foo\\+bar");
Tpresuf(["foo\?bar"], "foo\\?bar");
Tpresuf(["foo\\bar"], "foo\\\\bar");

# From Sebastian Nagel.
Tpresuf([qw(blo bla bla blo blub)], "bl(?:ub|[ao])");
