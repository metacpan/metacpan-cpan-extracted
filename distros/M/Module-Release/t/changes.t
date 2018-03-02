#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 1.0 tests => 5;

use Module::Release;

BEGIN {
	use File::Spec::Functions qw(rel2abs catfile);
	my $file = rel2abs( catfile( qw( t lib setup_common.pl) ) );
	require $file;
	}

my $release = Module::Release->new;

# due to the setup code above, we're in a directory without a 'Changes'
# file, hence:
is( $release->get_changes, '',
    'Empty string returned with nonexistent Changes file' );

{
    my $changes = <<'EOF';
Revision history for Perl module My::Temp::Test::Module

0.1 1900-01-01T00:00:00Z
    * initial release
EOF
    open my $fh, ">", "Changes" or die "$!";
    print $fh $changes;
    close $fh;

    like(
        $release->get_changes,
        qr/Revision history for Perl module/m,
        'Changes text includes title text'
    );
    is(
        $release->get_changes,
        "Revision history for Perl module My::Temp::Test::Module\n\n",
        'Changes includes title and text up to first non-w/s-beginning line'
    );

    unlink "Changes" or die "$!";
}
