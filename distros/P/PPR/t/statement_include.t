use strict;
use warnings;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}


use PPR;

my $neg = 0;
while (my $str = <DATA>) {
           if ($str =~ /\A# TH[EI]SE? SHOULD MATCH/) { $neg = 0;       next; }
        elsif ($str =~ /\A# TH[EI]SE? SHOULD FAIL/)  { $neg = 1;       next; }
        elsif ($str !~ /^####\h*\Z/m)                { $str .= <DATA>; redo; }

        $str =~ s/\s*^####\h*\Z//m;

        if ($neg) {
            ok $str !~ m/\A (?&PerlOWS) (?&PerlStatement) (?&PerlOWS) \Z $PPR::GRAMMAR/xo => "FAIL: $str";
        }
        else {
            ok $str =~ m/\A (?&PerlOWS) (?&PerlStatement) (?&PerlOWS) \Z $PPR::GRAMMAR/xo => "MATCH: $str";
        }
}

done_testing();

__DATA__
# THESE SHOULD MATCH...
    use No::Version::With::Arguments 1, 2;
####
    use Foo qw< bar >, "baz";
####
    require 'Module.pm';
####
    require 5.014;
####
    require 5.14.0;
####
    require 5.014_000;
####
    require 5.14.0;
####
    require 5.14;
####
    require Module;
####
    require v5.14.0;
####
    use 5.014;
####
    use 5.014_000;
####
    use 5.14.0;
####
    use 5.14;
####
    use Float::Version 1.5;
####
    use Foo 'bar';   # One thing.
####
    use Foo 5 'bar'; # One thing.
####
    use Foo 5;       # Don't expect anything.
####
    use Foo;         # Don't expect anything.
####
    use Integer::Version 1;
####
    use Module 1.00;
####
    use Module;
####
    use No::Version::With::Argument 'x';
####
    use No::Version;
####
    use Test::More tests => 5 * 9;
####
    use Version::With::Argument 1 2;
####
    use v5.14.0;
####
    no 5.014;
####
    no 5.014_000;
####
    no 5.14.0;
####
    no 5.14;
####
    no Float::Version 1.5;
####
    no Foo 'bar';   # One thing.
####
    no Foo 5 'bar'; # One thing.
####
    no Foo 5;       # Don't expect anything.
####
    no Foo qw< bar >, "baz";
####
    no Foo;         # Don't expect anything.
####
    no Integer::Version 1;
####
    no Module 1.00;
####
    no Module;
####
    no No::Version::With::Argument 'x';
####
    no No::Version::With::Arguments 1, 2;
####
    no No::Version;
####
    no Test::More tests => 5 * 9;
####
    no Version::With::Argument 1 2;
####
    no v5.14.0;
####
