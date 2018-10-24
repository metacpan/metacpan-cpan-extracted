#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use FindBin;

my $stat_test = "$FindBin::Bin/mock-stat.t";

ok -e $stat_test, "mock-stat.t is there";

my $test_content;
if ( open( my $fh, '<', $stat_test ) ) {
    local $/;
    $test_content = <$fh>;
}

ok length $test_content, "read content from stat_test" or die;

ok $test_content =~ s{^\s*done_testing.*$}{}m, "strip done_testing" or die;
ok $test_content =~ s{^\s*exit\s*;$}{}m,       "strip exit"         or die;
ok $test_content =~ s{\sstat(\b)}{ lstat$1}g,  "s{stat}{lstat}"     or die;

#note explain $test_content;

note "=" x 20, " start stat like test";
eval $test_content;
note "=" x 20, " end stat like test";

ok "Test is finished";

done_testing;
