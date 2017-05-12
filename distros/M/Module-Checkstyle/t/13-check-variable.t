#!perl
use Test::More tests => 20;

use strict;
use PPI;
use Module::Checkstyle::Config;

BEGIN { use_ok('Module::Checkstyle::Check::Variable'); } # 1

# matches-name
{
    my $checker = Module::Checkstyle::Check::Variable->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Variable]
matches-name = /^(?:[a-z]+)(_[a-z]+)*$/
END_OF_CONFIG
    
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
my $dontAllowCamelCase;
my $this_is_fine;
my $xistoo;
my ($foo, $bar);
my ($a, @b, %c);
my (%Fail, @Badly);
}
END_OF_CODE

    # Normally index_locations is called by Module::Checkstyle
    # when it loads a document but since we're loading
    # documents directlly here we have to do it manually
    $doc->index_locations();

    my $tokens = $doc->find('PPI::Statement::Variable');
    is(scalar @$tokens, 6); # 2
    my $token = shift @$tokens;

    my @problems = $checker->handle_declaration($token);
    is(scalar @problems, 1); # 3

    $token = shift @$tokens;
    @problems = $checker->handle_declaration($token);
    is(scalar @problems, 0); # 4

    $token = shift @$tokens;
    @problems = $checker->handle_declaration($token);
    is(scalar @problems, 0); # 5

    $token = shift @$tokens;
    @problems = $checker->handle_declaration($token);
    is(scalar @problems, 0); # 6

    $token = shift @$tokens;
    @problems = $checker->handle_declaration($token);
    is(scalar @problems, 0); # 7

    $token = shift @$tokens;
    @problems = $checker->handle_declaration($token);
    is(scalar @problems, 2); # 8
}

# arrays-in-plural, hashes-in-singalar
{
    my $checker = Module::Checkstyle::Check::Variable->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Variable]
arrays-in-plural   = true
hashes-in-singular = true
END_OF_CONFIG
    
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
my $dontAllowCamelCase;
my @cow;
my @cows;
my @number_of_cows;
my @NUMBER_OF_COWS;
my @numberOfCows;
my %pig;
my %pigs;
my %number_of_pig;
my %NUMBER_OF_PIG;
my %numberOfPig;
}
END_OF_CODE

    # Normally index_locations is called by Module::Checkstyle
    # when it loads a document but since we're loading
    # documents directlly here we have to do it manually
    $doc->index_locations();

    my $tokens = $doc->find('PPI::Statement::Variable');
    is(scalar @$tokens, 11); # 9
    my $token = shift @$tokens;

    my @problems = $checker->handle_declaration($token);
    is(scalar @problems, 0); # 10

    $token = shift @$tokens;
    @problems = $checker->handle_declaration($token);
    is(scalar @problems, 1); # 11

    $token = shift @$tokens;
    @problems = $checker->handle_declaration($token);
    is(scalar @problems, 0); # 12
    
    $token = shift @$tokens;
    @problems = $checker->handle_declaration($token);
    is(scalar @problems, 0); # 13

    $token = shift @$tokens;
    @problems = $checker->handle_declaration($token);
    is(scalar @problems, 0); # 14

    $token = shift @$tokens;
    @problems = $checker->handle_declaration($token);
    is(scalar @problems, 0); # 15

    $token = shift @$tokens;
    @problems = $checker->handle_declaration($token);
    is(scalar @problems, 0); # 16

    $token = shift @$tokens;
    @problems = $checker->handle_declaration($token);
    is(scalar @problems, 1); # 17
    
    $token = shift @$tokens;
    @problems = $checker->handle_declaration($token);
    is(scalar @problems, 0); # 18

    $token = shift @$tokens;
    @problems = $checker->handle_declaration($token);
    is(scalar @problems, 0); # 19

    $token = shift @$tokens;
    @problems = $checker->handle_declaration($token);
    is(scalar @problems, 0); # 20

}
