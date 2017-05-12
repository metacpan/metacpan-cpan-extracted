#!/usr/bin/perl -w

use File::Temp qw(tempdir);
use File::Path qw(mkpath);
use File::Spec::Functions qw(catdir);
use Test::More tests => 3;

=head1 NAME

synopsis.t - Tests that the synopsis works (using Pod::Snippets
itself, of course)

=cut

use_ok("Pod::Snippets");

my $snips = Pod::Snippets->load($INC{"Pod/Snippets.pm"},
                                -markup => "metatests",
                               -named_snippets => "strict");

my $testdir = tempdir("test-Pod-Snippet-XXXXXXX", TMPDIR => 1,
                      CLEANUP => 1);
push(@INC, $testdir);
mkpath(catdir($testdir, "Zero"));
open(WING, ">", catdir($testdir, qw(Zero Wing.pm))) or die "open: $!";
(print WING $snips->named("synopsis POD")->as_data()) or die "print: $!";
(close WING) or die "close: $!";

my $file_or_handle = catdir($testdir, qw(Zero Wing.pm));
sub Zero::Wing::capitain {
    bless { we_get_signal => "what!" }, shift;
}
sub Zero::Wing::what_happen {
    # Wait for it...
    return "Somebody set up us the bomb";
}
eval $snips->named("synopsis test script")->as_code(); die $@ if $@;
pass("synopsis OK");

