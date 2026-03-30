use strict;
use warnings;
no warnings 'once';
use Test::More;

use_ok('PDF::Sign');

# verify exported functions are available
for my $fn (qw(config prepare_file sign_file prepare_ts ts_file cms_sign ts_query tsa_fetch)) {
    can_ok('PDF::Sign', $fn);
}

# verify config() works
ok(PDF::Sign::config(debug => 1), 'config() returns true');
is($PDF::Sign::debug, 1, 'config() sets debug');
ok(PDF::Sign::config(debug => 0), 'config() resets debug');
is($PDF::Sign::debug, 0, 'config() resets debug correctly');

# verify package variables exist
ok(defined $PDF::Sign::osslcmd,  '$osslcmd defined');
ok(defined $PDF::Sign::tsaserver, '$tsaserver defined');
ok(defined $PDF::Sign::siglen,   '$siglen defined');

done_testing();
