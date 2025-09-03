#!perl

# Verify behavior of @INC when it contains CODEREFs in different places (while using Module::Case).

use strict;
use warnings;

BEGIN {
    if (eval { require tEsT::mOrE }) {
        # Yey! This is very likely to be a case-insensitive file system
        import Test::More tests => 16;
        my $f = $INC{"Test/More.pm"} = delete $INC{"tEsT/mOrE.pm"};
        ok($f, "Case-ignorant file system detected");
        ok($INC{"Test/More.pm"}, "Test::More loaded with munged case: $f");
    }
    else {
         print "1..0 # SKIP Smells like case-sensitive file system so not a valid test: $^O\n";
         exit;
    }
}

BEGIN {
    # Special CODEREF entry to test at the beginning of @INC
    ok(!ref $INC[0], "TOP INC not code");
    my $mod = q{
package Fake::Mod::First;
use base qw(Exporter);
our @EXPORT_OK = qw(f);
sub f { "first inc" }
1;
};
    my $code = sub {
        my (undef, $file) = @_;
        if ($file eq "Fake/Mod/First.pm") {
            open my $fh, "<", \$mod;
            return $fh;
        }
        return;
    };
    unshift @INC, $code;
    is("CODE", ref $INC[0], "TOP INC is CODEREF");
}

BEGIN {
    # Special CODEREF entry to test in the middle of @INC
    my $i = int(@INC/2);
    ok(!ref $INC[$i], "MID INC not code");
    my $mod = q{
package Fake::Mod::Middle;
use base qw(Exporter);
our @EXPORT_OK = qw(c);
sub c { "middle inc" }
1;
};
    my $code = sub {
        my (undef, $file) = @_;
        if ($file eq "Fake/Mod/Middle.pm") {
            open my $fh, "<", \$mod;
            return $fh;
        }
        return;
    };
    splice @INC, $i, 0, $code;
    is("CODE", ref $INC[$i], "MID INC is CODEREF");
}

BEGIN {
    # Special CODEREF entry to test at the end of @INC
    ok(!ref $INC[-1], "END INC not code");
    my $mod = q{
package Fake::Mod::Last;
use base qw(Exporter);
our @EXPORT_OK = qw(l);
sub l { "last inc" }
1;
};
    my $code = sub {
        my (undef, $file) = @_;
        if ($file eq "Fake/Mod/Last.pm") {
            open my $fh, "<", \$mod;
            return $fh;
            #return (undef,\$mod);
        }
        return;
    };
    push @INC, $code;
    is("CODE", ref $INC[-1], "END INC is CODEREF");
}

use Module::Case qw(Fake::Mod::First);

BEGIN {
    ok(1, 'Syntax passed for @INC monkeys');
}

use Fake::Mod::First 'f';
BEGIN {
    ok(defined &f, 'Fake::Mod::First imported');
    is(f, "first inc", "Fake::Mod::First->f perfect");
}

use Fake::Mod::Middle 'c';
BEGIN {
    ok(defined &c, 'Fake::Mod::Middle imported');
    is(c, "middle inc", "Fake::Mod::Middle->c perfect");
}

use Fake::Mod::Last  'l';
BEGIN {
    ok(defined &l, 'Fake::Mod::First imported');
    is(l, "last inc", "Fake::Mod::Last->l perfect");
}

ok(1, "Runtime completed");
