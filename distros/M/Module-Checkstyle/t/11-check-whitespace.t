#!perl
use Test::More tests => 37;

use strict;
use PPI;
use Module::Checkstyle::Config;

BEGIN { use_ok('Module::Checkstyle::Check::Whitespace'); } # 2

# after-comma
{
    my $checker = Module::Checkstyle::Check::Whitespace->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Whitespace]
after-comma = true
END_OF_CONFIG
    
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
my ($x, $y, $z);
call($x, $y, $z);
END_OF_CODE

    my $tokens = $doc->find('PPI::Token::Operator');
    is(scalar @$tokens, 4); # 2
    foreach my $token (@$tokens) {
        my @problems = $checker->handle_operator($token);
        is(scalar @problems, 0); # 3, 4, 5, 6
    }

    $doc = PPI::Document->new(\<<'END_OF_CODE');
my ($x,$y,$z);
call($x,$y,$z);
END_OF_CODE

    $tokens = $doc->find('PPI::Token::Operator');
    is(scalar @$tokens, 4); # 7
    foreach my $token (@$tokens) {
        my @problems = $checker->handle_operator($token);
        is(scalar @problems, 1); # 8, 9, 10, 11
    }
}

# after-comma
{
    my $checker = Module::Checkstyle::Check::Whitespace->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Whitespace]
before-comma = true
END_OF_CONFIG
    
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
my ($x ,$y ,$z);
call($x ,$y ,$z);
END_OF_CODE

    my $tokens = $doc->find('PPI::Token::Operator');
    is(scalar @$tokens, 4); # 12
    foreach my $token (@$tokens) {
        my @problems = $checker->handle_operator($token);
        is(scalar @problems, 0); # 13, 14, 15, 16
    }

    $doc = PPI::Document->new(\<<'END_OF_CODE');
my ($x,$y,$z);
call($x,$y,$z);
END_OF_CODE

    $tokens = $doc->find('PPI::Token::Operator');
    is(scalar @$tokens, 4); # 17
    foreach my $token (@$tokens) {
        my @problems = $checker->handle_operator($token);
        is(scalar @problems, 1); # 18, 19, 20, 21
    }
}

# after-fat-comma
{
    my $checker = Module::Checkstyle::Check::Whitespace->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Whitespace]
after-fat-comma = true
END_OF_CONFIG
    
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
my %args = (foo=> 1, bar=> 2);
call(foo=> $bar, bar=> $baz);
END_OF_CODE

    my $tokens = $doc->find('PPI::Token::Operator');
    @$tokens = grep { $_->content eq '=>' } @$tokens; # Ignore other than =>
    is(scalar @$tokens, 4); # 22
    foreach my $token (@$tokens) {
        my @problems = $checker->handle_operator($token);
        is(scalar @problems, 0); # 23, 24, 25, 26
    }

    $doc = PPI::Document->new(\<<'END_OF_CODE');
my %args = (foo=>1, bar=>2);
call(foo=>$bar, bar=>$baz);
END_OF_CODE

    $tokens = $doc->find('PPI::Token::Operator');
    @$tokens = grep { $_->content eq '=>' } @$tokens; # Ignore other than =>
    is(scalar @$tokens, 4); # 27
    foreach my $token (@$tokens) {
        my @problems = $checker->handle_operator($token);
        is(scalar @problems, 1); # 28, 29, 30, 31
    }
}

# after-control-word
{
    my $checker = Module::Checkstyle::Check::Whitespace->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Whitespace]
after-compound = true
END_OF_CONFIG

    my $doc = PPI::Document->new(\<<'END_OF_CODE');
if ($x) {
}
while($x) {
}

if ($x) {
} elsif($y) {
} else{
}
END_OF_CODE

    $doc->index_locations();

    my $tokens = $doc->find('PPI::Statement::Compound');
    is(scalar @$tokens, 3); # 32

    my $token = shift @$tokens;
    my @problems = $checker->handle_compound($token);
    is(scalar @problems, 0); # 33

    $token = shift @$tokens;
    @problems = $checker->handle_compound($token);
    is(scalar @problems, 1); # 34

    $token = shift @$tokens;
    @problems = $checker->handle_compound($token);
    is(scalar @problems, 2); # 35
    like((shift @problems)->get_message(), qr/^'elsif' /); # 36
    like((shift @problems)->get_message(), qr/^'else' /); # 37
}


1;

__DATA__
global-error-level    = WARN

[Whitespace]
after-comma      = true
before-comma     = true
after-fat-comma  = true
before-fat-comma = true
after-keyword    = true
