use strict;
use Test::More;

require MySQL::GrantParser;
MySQL::GrantParser->import;
note("new");
my $obj = new_ok("MySQL::GrantParser" => [ dbh => {dummy=>'dummy'} ]);

# diag explain $obj

done_testing;
