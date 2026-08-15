#!perl
use 5.024;
use strict;
use warnings;
use Test::More;

# the plugin's import installs the keyword into a Punk application and
# croaks anywhere else (by design), so the bare load is require_ok
BEGIN {
    use_ok('Punk::GraphQL')             || print "Bail out!\n";
    require_ok('Punk::Plugin::GraphQL') || print "Bail out!\n";
}

# and importing from a non-Punk package croaks with the useful message
{
    my $err = do { local $@; eval { Punk::Plugin::GraphQL->import }; $@ };
    like $err, qr/use Punk` before/, 'import outside a Punk app croaks';
}

diag("Testing Punk::GraphQL $Punk::GraphQL::VERSION, "
   . "GraphQL::Houtou $GraphQL::Houtou::VERSION, Perl $], $^X");

done_testing();
