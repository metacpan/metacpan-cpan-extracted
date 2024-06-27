use 5.036;
use warnings;

use Test2::V0;

plan tests => 71;

use Switch::Right;
no warnings 'shadow';
use builtin qw< true false >;
use experimental 'builtin';

# Utility subs and values...
sub   verify ($arg) { return $arg == 0 }
sub unverify ($arg) { return $arg != 0 }

my @incl_zero = -3..3;
my @excl_zero = (-3..-1, 1..3);
my @zeroes    = (0, 0.0, '0', qr/0/, sub { $_ == 0 });
my %zero      = ( 0 => 1 );
my $fh        = *DATA;

{
    my $ok;
    sub clear  () { $ok = false }
    sub passed () { $ok = true  }
    sub should_pass () { my $line = (caller())[2];
                         if ($ok) { pass "\\___ passed as expected\n" }
                         else     { fail "Test at line $line unexpectedly failed!\n" }
                        }
    sub should_fail () { my $line = (caller())[2];
                         if ($ok) { fail "Test at line $line unexpectedly passed!\n" }
                         else     { pass "Test at line $line failed as expected\n" }
                        }
}

given (0) {
    # Distinguished booleans...
    clear; when (true)  { pass 'true';  passed; continue } should_pass;
    clear; when (false) { fail 'false'; passed; continue } should_fail;

    # Integers...
    clear; when (0)     { pass 0;       passed; continue } should_pass;
    clear; when (1)     { fail 1;       passed; continue } should_fail;

    # Numbers...
    clear; when (0.0)   { pass 0.0;     passed; continue } should_pass;
    clear; when (1.1)   { fail 1.1;     passed; continue } should_fail;

    # Strings...
    clear; when ('0')   { pass "'0'";   passed; continue } should_pass;
    clear; when ('0.0') { fail "'0.0'"; passed; continue } should_fail;
    clear; when ('str') { fail "'str'"; passed; continue } should_fail;

    # Any of...
    clear; when (any=>\@incl_zero)  { pass '@incl_zero';   passed; continue } should_pass;
    clear; when (any=>\@excl_zero)  { fail '@excl_zero';   passed; continue } should_fail;
    clear; when (any=>[3,2,1,0,-1]) { pass '[3,2,1,0,-1]'; passed; continue } should_pass;
    clear; when (any=>[3,2,1,  -1]) { fail '[3,2,1,  -1]'; passed; continue } should_fail;

    # All of...
    clear; when (all=>[3,2,1,0,-1])   { fail '(3,2,1,0,-1)'; passed; continue } should_fail;
    clear; when (all=>[0,'0',qr/0/,/0/,$_==0,sub($x){$x==0}])
                        { pass q{(0,'0',qr/0/,/0/,$_==0,sub($x){$x==0})}; passed; continue }
                                                                         should_pass;

    # Boolean expressions...
    # 1. Immediate regex matches...
    clear; when ( /0/)  { pass '  /0/'; passed; continue } should_pass;
    clear; when (m/0/)  { pass '  /0/'; passed; continue } should_pass;
    clear; when ( /1/)  { fail '  /1/'; passed; continue } should_fail;
    clear; when (m/1/)  { fail ' m/1/'; passed; continue } should_fail;

    # 2. Immediate negated expressions...
    clear; when (! /0/)       { fail '! /0/';       passed; continue } should_fail;
    clear; when (!m/0/)       { fail '! /0/';       passed; continue } should_fail;
    clear; when (! /1/)       { pass '! /1/';       passed; continue } should_pass;
    clear; when (!m/1/)       { pass '!m/1/';       passed; continue } should_pass;
    clear; when (!$_)         { pass '!$_';         passed; continue } should_pass;
    clear; when (not $_ eq 1) { pass 'not $_ eq 1'; passed; continue } should_pass;

    # 2. Immediate expressions...
    clear; when ($_ =~ m/0/) { pass '$_ =~ m/0/'; passed; continue } should_pass;
    clear; when ($_ !~ m/0/) { fail '$_ !~ m/0/'; passed; continue } should_fail;
    clear; when ($_ =~ m/1/) { fail '$_ =~ m/1/'; passed; continue } should_fail;
    clear; when ($_ !~ m/1/) { pass '$_ !~ m/1/'; passed; continue } should_pass;
    clear; when ($_ == 0)    { pass '$_ == 0';    passed; continue } should_pass;
    clear; when ($_ != 0)    { fail '$_ != 0';    passed; continue } should_fail;

    # 3. Immediate function and sub calls...
    clear; when (exists $zero{$_}) { pass 'exists $zero{$_}'; passed; continue } should_pass;
    clear; when (defined)          { pass 'defined';          passed; continue } should_pass;
    clear; when (eof *DATA)        { pass 'eof *DATA';        passed; continue } should_pass;
    clear; when (verify($_))       { pass 'verify($_)';       passed; continue } should_pass;
    clear; when (verify(0))        { pass 'verify(0)';        passed; continue } should_pass;
    clear; when (verify(1))        { fail 'verify(1)';        passed; continue } should_fail;
    clear; when (-r $0)            { pass '-r $0';            passed; continue } should_pass;
    clear; when (-r -e $0)         { pass '-r -e $0';         passed; continue } should_pass;
    clear; when (-r -e $0)         { pass '-r -e $0';         passed; continue } should_pass;

    # Function refs...
    clear; when (\&verify)         { pass '\&verify';        passed; continue } should_pass;
    clear; when (sub($x){$x?0:1})  { pass 'sub($x){$x?0:1}'; passed; continue } should_pass;
    clear; when (sub    {$_?0:1})  { pass 'sub{$_?0:1}';     passed; continue } should_pass;
    clear; when (\&unverify)       { fail '\&unverify';      passed; continue } should_fail;
}

done_testing();

