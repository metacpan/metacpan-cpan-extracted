use strict;

# cgi environment no defined in command line
no warnings 'uninitialized';

use Test::More tests => 2;

BEGIN { use_ok('Nes') };

my $nes_code  = '{: $ test :}';
my $interpret = nes_interpret->new($nes_code);
my %tags      = ( test => 'the out' );
my $output    = $interpret->go( %tags );
ok($output =~ /the out/, 'interpret');
