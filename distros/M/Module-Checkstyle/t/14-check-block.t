#!perl
use Test::More tests => 29;

use strict;

use PPI;
use Module::Checkstyle::Config;

BEGIN { use_ok('Module::Checkstyle::Check::Block'); } # 1

# opening-curly
{
    my $checker = Module::Checkstyle::Check::Block->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Block]
opening-curly = same
END_OF_CONFIG
    
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
if (1) {
}

if (1)
{
}

if (1) {
} else {
}

my $x =
{
};
END_OF_CODE

    # Normally index_locations is called by Module::Checkstyle
    # when it loads a document but since we're loading
    # documents directlly here we have to do it manually
    $doc->index_locations();
    my $tokens = $doc->find('PPI::Structure::Block');
    is(scalar @$tokens, 5); # 2
    my @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 0); # 3
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 1); # 4
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 0); # 5
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 0); # 6
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 1); # 7

    $checker = Module::Checkstyle::Check::Block->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Block]
opening-curly = alone
END_OF_CONFIG
    
    $doc = PPI::Document->new(\<<'END_OF_CODE');
if (1) {
}

if (1)
{
}

if (1) {
} else
{
}

my $x =
{
};
END_OF_CODE

    # Normally index_locations is called by Module::Checkstyle
    # when it loads a document but since we're loading
    # documents directlly here we have to do it manually
    $doc->index_locations();
    $tokens = $doc->find('PPI::Structure::Block');
    is(scalar @$tokens, 5); # 8
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 1); # 9
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 0); # 10
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 1); # 11
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 0); # 12
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 0); # 13
    
}

# closing-curly
{
    my $checker = Module::Checkstyle::Check::Block->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Block]
closing-curly = same
END_OF_CONFIG
    
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
if (1) {
} else {
}

if (1)
{
}
else
{
}

eval {
  foo();
};

try {
}
catch IO::Error with {
};

my $x =
{
};
END_OF_CODE

    # Normally index_locations is called by Module::Checkstyle
    # when it loads a document but since we're loading
    # documents directlly here we have to do it manually
    $doc->index_locations();
    my $tokens = $doc->find('PPI::Structure::Block');
    is(scalar @$tokens, 8); # 14
    my @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 0); # 15
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 0); # 16
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 1); # 17
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 0); # 18
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 0); # 19
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 1); # 20
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 0); # 21
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 0); # 22
    
    $checker = Module::Checkstyle::Check::Block->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Block]
closing-curly = alone
END_OF_CONFIG
    
    $doc = PPI::Document->new(\<<'END_OF_CODE');
if (1) {
} else {
}

if (1)
{
}
else
{
}

my $x =
{
};
END_OF_CODE

    # Normally index_locations is called by Module::Checkstyle
    # when it loads a document but since we're loading
    # documents directlly here we have to do it manually
    $doc->index_locations();
    $tokens = $doc->find('PPI::Structure::Block');
    is(scalar @$tokens, 5); # 23
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 1); # 24
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 0); # 25
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 0); # 26
}

# ignore-same-line
{
    my $checker = Module::Checkstyle::Check::Block->new(Module::Checkstyle::Config->new(\<<'END_OF_CONFIG'));
[Block]
ignore-on-same-line = true
closing-curly = alone
END_OF_CONFIG
    
    my $doc = PPI::Document->new(\<<'END_OF_CODE');
my @bar = grep { } @foo;
sub test { }
END_OF_CODE

    # Normally index_locations is called by Module::Checkstyle
    # when it loads a document but since we're loading
    # documents directlly here we have to do it manually
    $doc->index_locations();
    my $tokens = $doc->find('PPI::Structure::Block');
    is(scalar @$tokens, 2); # 27
    my @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 0); # 28
    @problems = $checker->handle_block(shift @$tokens);
    is(scalar @problems, 0); # 29
}
