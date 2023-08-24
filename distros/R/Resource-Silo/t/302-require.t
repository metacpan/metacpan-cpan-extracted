#!/usr/bin/env perl

=head1 DESCRIPTION

Test 'require' option.

=cut

use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);

use Resource::Silo;

resource plain =>
    require => 'My::Class',
    init    => sub { 42 };

# Now we require Digest::MD5 as it's present in perl core _and_ loads fast
resource list =>
    require => [ 'My::Class', 'IPC::Open2' ],
    init    => sub { 42 };

my $prefix = dirname(__FILE__)."/tlib";
unshift @INC, $prefix;

my $class = "My/Class.pm";
my $other = "IPC/Open2.pm";

is $INC{$class}, undef, "nothing loaded yet";
is $INC{$other}, undef, "nothing loaded yet (2)";

is silo->plain, 42, "resource instantiated";
like $INC{$class}, qr($prefix[\\/]$class), "My::Class now loaded";
is $INC{$other}, undef, "but not other class";

is silo->list, 42, "other resource instantiated";
ok $INC{$other}, "Other class loaded from somewhere";

done_testing;
