#!perl
use Test::More tests => 17;

use strict;
use PPI;
use Module::Checkstyle::Config;

BEGIN { use_ok('Module::Checkstyle::Check::Label'); } # 1

# matches-name
{
    my $checker = Module::Checkstyle::Check::Label->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Label]
matches-name = /^[A-Z]+(_[A-Z]+)*$/
END_OF_CONFIG
    
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
VALID: {
}

ALSO_VALID: {
}

INVALID123: {
}
END_OF_CODE

    # Normally index_locations is called by Module::Checkstyle
    # when it loads a document but since we're loading
    # documents directlly here we have to do it manually
    $doc->index_locations();

    my $tokens = $doc->find('PPI::Token::Label');
    is(scalar @$tokens, 3); # 2

    my @problems = $checker->handle_label(shift @$tokens);
    is(scalar @problems, 0); # 3
    @problems = $checker->handle_label(shift @$tokens);
    is(scalar @problems, 0); # 4
    @problems = $checker->handle_label(shift @$tokens);
    is(scalar @problems, 1); # 5
}

# label-position
{
    my $checker = Module::Checkstyle::Check::Label->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Label]
position = alone
END_OF_CONFIG
    
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
L1:
while (1) {
}

L2: while(1) {
}

my $x = 1; L2:
while(1) {
}

my $y = 2; L3: while(1) {
}
END_OF_CODE

    # Normally index_locations is called by Module::Checkstyle
    # when it loads a document but since we're loading
    # documents directlly here we have to do it manually
    $doc->index_locations();

    my $tokens = $doc->find('PPI::Token::Label');
    is(scalar @$tokens, 4); # 6

    my @problems = $checker->handle_label(shift @$tokens);
    is(scalar @problems, 0); # 7
    @problems = $checker->handle_label(shift @$tokens);
    is(scalar @problems, 1); # 8
    @problems = $checker->handle_label(shift @$tokens);
    is(scalar @problems, 1); # 9
    @problems = $checker->handle_label(shift @$tokens);
    is(scalar @problems, 1); # 10
}

# require-for-breaks
{
    my $checker = Module::Checkstyle::Check::Label->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Label]
require-for-break = true
END_OF_CONFIG
    
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
redo;
last;
next;
return;
redo FOO;
next if 1;
END_OF_CODE

    # Normally index_locations is called by Module::Checkstyle
    # when it loads a document but since we're loading
    # documents directlly here we have to do it manually
    $doc->index_locations();

    my $tokens = $doc->find('PPI::Statement::Break');
    is(scalar @$tokens, 6); # 11

    my @problems = $checker->handle_break(shift @$tokens);
    is(scalar @problems, 1); # 12
    @problems = $checker->handle_break(shift @$tokens);
    is(scalar @problems, 1); # 13
    @problems = $checker->handle_break(shift @$tokens);
    is(scalar @problems, 1); # 14
    @problems = $checker->handle_break(shift @$tokens);
    is(scalar @problems, 0); # 15
    @problems = $checker->handle_break(shift @$tokens);
    is(scalar @problems, 0); # 16
    @problems = $checker->handle_break(shift @$tokens);
    is(scalar @problems, 1); # 17
}
