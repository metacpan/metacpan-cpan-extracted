#!/usr/bin/env perl

use strict;
use warnings;
use HybridLoad ();
use ResidualOnly ();
use SlowLoad ();

my $cmd = shift @ARGV // 'status';
if ($cmd eq 'status') {
    print SlowLoad::message(), "\n";
    exit 0;
}

if ($cmd eq 'asset') {
    my $root = $ENV{PAX_EMBEDDED_ASSET_ROOT} // '';
    my $path = $root ? "$root/banner.txt" : '';
    if (!$path || !-f $path) {
        print STDERR "missing asset\n";
        exit 3;
    }
    open my $fh, '<', $path or die $!;
    my $content = <$fh>;
    close $fh;
    print $content;
    exit 0;
}

if ($cmd eq 'hybrid-fast') {
    print HybridLoad::fast_message(), "\n";
    exit 0;
}

if ($cmd eq 'hybrid-slow') {
    print HybridLoad::slow_message('alpha:beta'), "\n";
    exit 0;
}

if ($cmd eq 'residual-only') {
    print ResidualOnly::reverse_words('one two three'), "\n";
    exit 0;
}

print STDERR "unknown command: $cmd\n";
exit 2;

=pod

=head1 NAME

t/fixtures/app_entry.pl - fixture for application entrypoint fixture used by standalone app-image tests

=head1 DESCRIPTION

This fixture exists to provide application entrypoint fixture used by standalone app-image tests. Tests load or execute it to reproduce a
specific code shape that the PAX compiler, capture engine, or runtime must
handle correctly.

=head1 HOW TO USE

Keep the fixture small and focused on the behavior named above. When a new test
needs a different shape, add or change fixtures deliberately instead of turning
this file into a grab bag.

=cut
