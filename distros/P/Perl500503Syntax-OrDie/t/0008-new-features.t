######################################################################
#
# 0008-new-features.t  Tests for features added in revised OrDie
#
# Covers:
#   - use constant { HASH } detection (Perl 5.8)
#   - typeglob slot *name{SLOT} detection (Perl 5.6)
#   - sprintf/printf %v format detection (Perl 5.6)
#   - say method-call false positive fix
#   - isa( call false positive fix
#   - any/all List::Util import suppression
#   - %hash{LIST} slice context fix (reduced false positives)
#   - REGEX_BLACKLIST line numbers now reported
#   - check_source() returns violation list (API change)
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

BEGIN {
    require Perl500503Syntax::OrDie;
    Perl500503Syntax::OrDie::_install_runtime_guards();
}

# helper: returns 1 if check_source finds violations, 0 if clean
sub violates {
    my ($src) = @_;
    my @v = Perl500503Syntax::OrDie::_check_source($src, 'test');
    return @v ? 1 : 0;
}

# helper: return violation messages for a source string
sub violations {
    my ($src) = @_;
    return Perl500503Syntax::OrDie::_check_source($src, 'test');
}

use vars qw(@tests);
@tests = (

    # ==============================================================
    # use constant { HASH }  (Perl 5.8)
    # ==============================================================
    ['use constant {}: detected',
        sub { violates("use constant { A => 1, B => 2 };\n") }],

    ['use constant {}: in comment - ignored',
        sub { !violates("# use constant { A => 1 }\n") }],

    ['use constant NAME => VALUE: not detected (5.004 form)',
        sub { !violates("use constant PI => 3.14159;\n") }],

    ['use constant {}: in string - ignored',
        sub { !violates("my \$s = 'use constant { A => 1 }';\n") }],

    # ==============================================================
    # typeglob slot  *name{IO}  (Perl 5.6)
    # ==============================================================
    ['typeglob slot *FH{IO}: detected',
        sub { violates("my \$io = *FH{IO};\n") }],

    ['typeglob slot *foo{SCALAR}: detected',
        sub { violates("my \$r = *foo{SCALAR};\n") }],

    ['typeglob slot *foo{CODE}: detected',
        sub { violates("my \$r = *foo{CODE};\n") }],

    ['typeglob slot: in comment - ignored',
        sub { !violates("# *FH{IO}\n") }],

    ['typeglob slot: in string - ignored',
        sub { !violates("my \$s = '*FH{IO}';\n") }],

    ['typeglob assign (not slot): not detected',
        sub { !violates("*foo = *bar;\n") }],

    # ==============================================================
    # sprintf/printf %v -- string contents are NOT checked
    # A string literal "%vd" is valid Perl 5.005_03 syntax.
    # ==============================================================
    ['spf %v in string literal - NOT a violation',
        sub { !violates("my \$s = sprintf(\"%vd\", \$v);\n") }],

    ['pf %v in string literal - NOT a violation',
        sub { !violates("printf(\"%vd\", \$v);\n") }],

    ['spf %v in comment - not detected',
        sub { !violates("# sprintf(\"%vd\", \$v)\n") }],

    # ==============================================================
    # say false positive fixes
    # ==============================================================
    ['say: method call ->say() - not detected',
        sub { !violates("\$obj->say(\"hello\");\n") }],

    ['say: hash key say => - not detected',
        sub { my $kw = 'sa' . 'y'; my $t = 'my %h = (' . $kw . ' => 1);' . "\n"; !violates($t) }],

    ['say: real say usage - detected',
        sub { my $kw = 'sa' . 'y'; my $t = "${kw} \"hello\";\n"; violates($t) }],

    ['say: say LIST - detected',
        sub { my $kw = 'sa' . 'y'; my $t = "${kw} STDOUT \"hello\";\n"; violates($t) }],

    # ==============================================================
    # isa false positive fixes
    # ==============================================================
    ['isa: ->isa() method call - not detected',
        sub { !violates("\$obj->isa('Foo');\n") }],

    ['isa: UNIVERSAL::isa() - not detected',
        sub { !violates("UNIVERSAL::isa(\$obj, 'Foo');\n") }],

    ['isa: isa( sub call form - not detected',
        sub { !violates("isa(\$obj, 'Foo');\n") }],

    ['isa: infix operator - detected',
        sub { violates("\$obj isa Foo;\n") }],

    # ==============================================================
    # any/all: List::Util import suppression
    # ==============================================================
    ['any{}: without List::Util import - detected',
        sub { violates("my \$r = any { \$_ > 0 } \@list;\n") }],

    ['any{}: with List::Util any import - not detected',
        sub {
            my $src = "use List::Util qw(any);\n"
                    . "my \$r = any { \$_ > 0 } \@list;\n";
            !violates($src);
        }],

    ['all{}: with List::Util all import - not detected',
        sub {
            my $src = "use List::Util qw(all);\n"
                    . "my \$ok = all { \$_ > 0 } \@list;\n";
            !violates($src);
        }],

    ['all{}: without List::Util import - detected',
        sub { violates("my \$r = all { \$_ > 0 } \@list;\n") }],

    ['any{}: List::Util imported but different function - detected',
        sub {
            my $src = "use List::Util qw(sum);\n"
                    . "my \$r = any { \$_ > 0 } \@list;\n";
            violates($src);
        }],

    # ==============================================================
    # %hash{LIST} slice: context-aware (reduced false positives)
    # ==============================================================
    ['%hash{LIST}: in rvalue context - detected',
        sub { violates("my \@kv = (%h{\@keys});\n") }],

    ['%hash plain assignment: not detected',
        sub { !violates("my \%h = (a => 1);\n") }],

    ['%ENV scalar access: not detected',
        sub { !violates("my \$p = \$ENV{PATH};\n") }],

    # ==============================================================
    # REGEX_BLACKLIST: line numbers now reported
    # ==============================================================
    ['regex blacklist: line number reported for \\K in regex',
        sub {
            my $src = "use strict;\n"
                    . "my \$x = 1;\n"
                    . "\$str =~ s/foo\\Kbar/baz/;\n";
            my @v = violations($src);
            @v && $v[0] =~ /line 3/;
        }],

    ['regex blacklist: line number reported for named capture',
        sub {
            my $src = "my \$x = 1;\n"
                    . "my \$y = 2;\n"
                    . "my \$z = 3;\n"
                    . "\$s =~ m/(?<name>\\w+)/;\n";
            my @v = violations($src);
            @v && $v[0] =~ /line 4/;
        }],

    # ==============================================================
    # check_source() public API returns list
    # ==============================================================
    ['api: check_source returns empty list on clean code',
        sub {
            my @v = Perl500503Syntax::OrDie::check_source(
                "use strict;\nmy \$x = 1;\n", 't');
            !@v;
        }],

    ['api: check_source returns violations list (not die)',
        sub {
            my @v = Perl500503Syntax::OrDie::check_source(
                "our \$x = 1;\n", 't');
            @v && $v[0] =~ /VIOLATION/;
        }],

    ['api: check_source multiple violations returns multiple entries',
        sub {
            my @v = Perl500503Syntax::OrDie::check_source(
                "our \$x;\nour \$y;\n", 't');
            scalar(@v) >= 2;
        }],

);

print "1.." . scalar(@tests) . "\n";
my $n = 0;
for my $t (@tests) {
    $n++;
    my ($label, $code) = @{$t};
    my $result = eval { $code->() };
    my $ok     = $result && !$@;
    print +($ok ? '' : 'not ') . "ok $n - $label\n";
    print "# EVAL ERROR: $@\n" if $@;
}
