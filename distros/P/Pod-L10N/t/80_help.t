#!/usr/bin/perl -w                                         # -*- perl -*-
use strict;
use warnings;
use Pod::L10N::Html;
use Test::More tests => 3;

my $warn;
$SIG{__WARN__} = sub { $warn .= $_[0] };

eval {
    Pod::L10N::Html::pod2htmll10n(
        "--help",
    );
};

like($@,
    qr(\AUsage:)x,
    "misc pod-html --help");

eval {
    Pod::L10N::Html::pod2htmll10n(
        "--invalidparameter",
    );
};

like($@,
    qr(\AUsage:)x,
    "misc invalid parameter");

like($warn,
    qr(\AUnknown)x,
    "misc invalid parameter");
