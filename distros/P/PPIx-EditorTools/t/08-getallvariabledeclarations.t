#!/usr/bin/perl

# Test for RT #63107: Finding declared variables fragile and misses loop variables
# Courtesy of Ovid++

use strict;
use warnings;

use Test::Most 'no_plan';
use PPI;

use PPIx::EditorTools;
diag "PPI version is $PPI::VERSION";

my $code = <<'END_OF_CODE';
use warnings;

foreach my $arg (@ARGV) {
print $arg;
}
END_OF_CODE

# Test finding variable declaration when on the variable
my $declarations;
lives_ok {
	$declarations = PPIx::EditorTools::get_all_variable_declarations( PPI::Document->new( \$code ) );
}
'We should be able to find variable declarations';

explain $declarations;
ok exists $declarations->{lexical}{'$arg'}, '... and we should be able to find loop variables';

$code = <<'END_OF_CODE';
foreach my $arg (@ARGV) {
print $arg;
}
END_OF_CODE

lives_ok {
	$declarations = PPIx::EditorTools::get_all_variable_declarations( PPI::Document->new( \$code ) );
}
'We should be able to find variable declarations';

explain $declarations;
ok exists $declarations->{lexical}{'$arg'}, '... and we should be able to find loop variables';
