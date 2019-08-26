# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

use strict;
use Sjis;
print "1..8\n";

my $__FILE__ = __FILE__;

# Test::Harness::runtests() and reset() make "Error: Runtime exception".
#
# t/303_m_once_reset........Error: Runtime exception
# Error: Runtime exception
# Can't spawn "cmd.exe": No such file or directory at Foo.pm line NNN.
# Callback called exit at t/303_m_once_reset.t line NNN.
# BEGIN failed--compilation aborted at t/303_m_once_reset.t line NNN.
# dubious
#         Test returned status 2 (wstat 512, 0x200)
# DIED. FAILED tests 1-8
#         Failed 8/8 tests, 0.00% okay

if ($] =~ /^5\.005/) {
    for my $tno (1 .. 8) {
        print qq{ok - $tno # SKIP $^X/$] $^O $__FILE__\n};
    }
    exit;
}

my @m_once = ();

@m_once = ();
for (qw(あああ あああ あああ)) {
    if ($_ =~ ?あああ?) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
    reset;
}
if (join(',',@m_once) eq '1,1,1') {
    print qq{ok - 1 ?あああ?; reset $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 ?あああ?; reset $^X $__FILE__\n};
}

@m_once = ();
my $re = '';
for (qw(あああ いいい ううう)) {
    $re = $_;
    if ($_ =~ ?$re?o) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
    reset;
}
if (join(',',@m_once) eq '1,0,0') {
    print qq{ok - 2 ?\$re?o; reset $^X $__FILE__\n};
}
else {
    if (($^O eq 'MSWin32') and ($] eq '5.006001')) {
        print qq{ok - 2 # SKIP ?\$re?o; reset $^X/$] $^O $__FILE__\n};
    }
    else {
        print qq{not ok - 2 ?\$re?o; reset $^X $__FILE__\n};
    }
}

@m_once = ();
for (qw(あああ あああ あああ)) {
    if ($_ =~ ? あ あ あ ?x) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
    reset;
}
if (join(',',@m_once) eq '1,1,1') {
    print qq{ok - 3 ? あ あ あ ?x; reset $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 ? あ あ あ ?x; reset $^X $__FILE__\n};
}

@m_once = ();
for ("あああ\nいいい","あああ\nいいい","あああ\nいいい") {
    if ($_ =~ ?^いいい?m) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
    reset;
}
if (join(',',@m_once) eq '1,1,1') {
    print qq{ok - 4 ?^いいい?m; reset $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 ?^いいい?m; reset $^X $__FILE__\n};
}

@m_once = ();
for ("あ\nい","あ\nい","あ\nい") {
    if ($_ =~ ?あ.い?s) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
    reset;
}
if (join(',',@m_once) eq '1,1,1') {
    print qq{ok - 5 ?あ.い?s; reset $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 ?あ.い?s; reset $^X $__FILE__\n};
}

@m_once = ();
for (qw(AAA AAA AAA)) {
    if ($_ =~ ?aaa?i) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
    reset;
}
if (join(',',@m_once) eq '1,1,1') {
    print qq{ok - 6 ?aaa?i; reset $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 ?aaa?i; reset $^X $__FILE__\n};
}

@m_once = ();
for (qw(あああ あああ あああ)) {
    if ($_ =~ ?あああ?g) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
    reset;
}
if (join(',',@m_once) eq '1,1,1') {
    print qq{ok - 7 ?あああ?g; reset $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 ?あああ?g; reset $^X $__FILE__\n};
}

@m_once = ();
for (qw(あああ あああ あああ)) {
    if ($_ =~ ?あああ?gc) {
        push @m_once, 1;
    }
    else {
        push @m_once, 0;
    }
    reset;
}
if (join(',',@m_once) eq '1,1,1') {
    print qq{ok - 8 ?あああ?gc; reset $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 ?あああ?gc; reset $^X $__FILE__\n};
}

__END__

