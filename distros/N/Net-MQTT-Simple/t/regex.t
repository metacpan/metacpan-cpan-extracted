#!/usr/bin/perl -w
use strict;
use Test::More;
use Net::MQTT::Simple;

*far = \&Net::MQTT::Simple::filter_as_regex;

no warnings "qw";

# Boring spec tests, the "non normative comments" from the MQTT 3.1.1 draft

SECTION_4_7_1_2: {
    my ($regex, $filter, $topic);

    $regex = far($filter = "sport/tennis/player1/#");

    $topic = "sport/tennis/player1";
    like($topic, qr/$regex/, "4.7.1.2, '$topic' should match '$filter'");

    $topic = "sport/tennis/player1/ranking";
    like($topic, qr/$regex/, "4.7.1.2, '$topic' should match '$filter'");

    $topic = "sport/tennis/player1/wimbledon";
    like($topic, qr/$regex/, "4.7.1.2, '$topic' should match '$filter'");

    $regex = far($filter = "sport/#");

    $topic = "sport";
    like($topic, qr/$regex/, "4.7.1.2, '$topic' should match '$filter'");
}

SECTION_4_7_1_3: {
    my ($regex, $filter, $topic);

    $regex = far($filter = "sport/tennis/+");

    $topic = "sport/tennis/player1";
    like($topic, qr/$regex/, "4.7.1.3, '$topic' should match '$filter'");

    $topic = "sport/tennis/player2";
    like($topic, qr/$regex/, "4.7.1.3, '$topic' should match '$filter'");

    $topic = "sport/tennis/player1/ranking";
    unlike($topic, qr/$regex/, "4.7.1.3, '$topic' should not match '$filter'");

    $regex = far($filter = "sport/+");

    $topic = "sport";
    unlike($topic, qr/$regex/, "4.7.1.3, '$topic' should not match '$filter'");

    $topic = "sport/";
    like($topic, qr/$regex/, "4.7.1.3, '$topic' should match '$filter'");
}

SECTION_4_7_2_1: {
    my ($regex, $filter, $topic);

    $regex = far($filter = "#");
    $topic = "\$SYS/something";
    unlike($topic, qr/$regex/, "4.7.2.1, '$topic' should not match '$filter'");

    $regex = far($filter = "+/monitor/Clients");
    $topic = "\$SYS/monitor/Clients";
    unlike($topic, qr/$regex/, "4.7.2.1, '$topic' should not match '$filter'");

    $regex = far($filter = "\$SYS/#");
    $topic = "\$SYS/something";
    like($topic, qr/$regex/, "4.7.2.1, '$topic' should match '$filter'");

    $regex = far($filter = "\$SYS/monitor/+");
    $topic = "\$SYS/monitor/Clients";
    like($topic, qr/$regex/, "4.7.2.1, '$topic' should match '$filter'");
}

# Now, let's try a more systematic approach

my @matrix = (
    # Topic             Should match all of these, but none of the
    #                   other ones that are listed for other topics.
    [ "/",              qw(# /# +/+ /) ],
    [ "foo",            qw(# +   foo/# foo) ],
    [ "foo/bar",        qw(# +/+ foo/# foo/bar/# foo/+ +/bar foo/+/#) ],
    [ "foo//bar",       qw(# +/+/+ foo/# foo//bar foo/+/bar foo/+/#
                           foo//+) ],
    [ "/foo",           qw(# /# +/+ /foo /foo/#) ],
    [ "/\$foo",         qw(# /# +/+ /$foo /$foo/#) ],  # Not special
    [ "/foo/bar",       qw(# /# +/+/+ /foo/#)],
    [ "///",            qw(# /# +/+/+/+) ],
    [ "foo/bar/baz",    qw(# +/+/+ foo/# foo/bar/# foo/+/#
                           +/bar/baz foo/+/baz foo/bar/+ +/+/baz) ],
    [ "\$foo",          qw($foo $foo/#) ],  # Special because it begins with $
    [ "\$SYS/foo",      qw($SYS/# $SYS/+ $SYS/foo) ],
    [ "\$SYS/foo/bar",  qw($SYS/# $SYS/+/+ $SYS/foo/bar $SYS/+/bar $SYS/foo/+)],
    [ "fo2/bar/baz",    qw(# fo2/bar/baz +/+/+ +/+/baz +/bar/baz) ],
    [ "foo///baz",      qw(# foo/# foo/+/# foo/+/+/baz +/+/+/+) ],
    [ "foo/bar/",       qw(# foo/# foo/+/# foo/bar/+ foo/bar/# +/+/+)],
);

my %all_filters;
for (@matrix) {
    $all_filters{ $_ }++ for @{ $_ }[ 1.. $#$_ ];
}

for (@matrix) {
    my $topic = shift @$_;
    my @should_match = @$_;
    my %should_not_match = %all_filters;
    delete @should_not_match{ @should_match };

    for my $filter (@should_match) {
        my $regex = far( $filter );
        like($topic, qr/$regex/, "'$topic' should match '$filter'");
    }

    for my $filter (sort keys %should_not_match) {
        my $regex = far( $filter );
        unlike($topic, qr/$regex/, "'$topic' should not match '$filter'");
    }
}

# These are from mosquitto's 03-pattern-matching.py
my @mosquitto_tests = split "\n", <<'END';
pattern_test("#", "test/topic")
pattern_test("#", "/test/topic")
pattern_test("foo/#", "foo/bar/baz")
pattern_test("foo/+/baz", "foo/bar/baz")
pattern_test("foo/+/baz/#", "foo/bar/baz")
pattern_test("foo/+/baz/#", "foo/bar/baz/bar")
pattern_test("foo/foo/baz/#", "foo/foo/baz/bar")
pattern_test("foo/#", "foo")
pattern_test("/#", "/foo")
pattern_test("test/topic/", "test/topic/")
pattern_test("test/topic/+", "test/topic/")
pattern_test("+/+/+/+/+/+/+/+/+/+/test", "one/two/three/four/five/six/seven/eight/nine/ten/test")

pattern_test("#", "test////a//topic")
pattern_test("#", "/test////a//topic")
pattern_test("foo/#", "foo//bar///baz")
pattern_test("foo/+/baz", "foo//baz")
pattern_test("foo/+/baz//", "foo//baz//")
pattern_test("foo/+/baz/#", "foo//baz")
pattern_test("foo/+/baz/#", "foo//baz/bar")
pattern_test("foo//baz/#", "foo//baz/bar")
pattern_test("foo/foo/baz/#", "foo/foo/baz/bar")
pattern_test("/#", "////foo///bar")
END

sub pattern_test {
    my ($pattern, $match) = @_;
    my $regex = far($pattern);
    like($match, qr/$regex/, "mosquitto: '$match' should match '$pattern'");
}

eval for @mosquitto_tests;


done_testing;
