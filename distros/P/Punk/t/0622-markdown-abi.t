#!perl

# The markdown mount's two provider ABIs, and what happens when they are not
# there.
#
# Both are resolved at runtime through the provider's _abi_ptr and gated on
# abi_version. There is no Perl fall-back worth having for either - rendering
# a documentation tree through method calls would defeat the point of the
# mount - so a missing or too-old table is a boot croak naming what to
# upgrade, not a silent degradation.
#
# PUNK_FAKE_MDS_BAD and PUNK_FAKE_SG_BAD make the resolvers fail, which is the
# only way to exercise that path without uninstalling something. They have to
# be set before Punk loads, so the mismatch runs in a child process the way
# t/0301-stencil-abi.t drives its own.

use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Config ();

BEGIN {
    plan skip_all => 'needs Markdown::Simple 0.20+ with its C ABI'
        unless eval { require Markdown::Simple;
                      Markdown::Simple->can('_abi_ptr')
                      && Markdown::Simple::_abi_version() >= 1 };
    plan skip_all => 'needs Template::Stencil with its C ABI'
        unless eval { require Template::Stencil;
                      Template::Stencil->can('_abi_ptr') };
}

require Punk;

my $DOCS = "$FindBin::Bin/test/docs";

# ---- the tables resolved here ------------------------------------------------

ok Punk::_mds_available(), 'the Markdown::Simple ABI resolved';
is Punk::_mds_abi_version(), 1, 'Punk compiled against mds_abi version 1';

SKIP: {
    skip 'Search::Trigram not installed', 2
        unless eval { require Search::Trigram; 1 };
    ok Punk::_sg_available(), 'the Search::Trigram ABI resolved';
    is Punk::_sg_abi_version(), 1, 'Punk compiled against sg_abi version 1';
}

# ---- what a mismatch looks like ----------------------------------------------

# Run a mount build in a child with the resolver sabotaged, and report what
# came back. The program goes through a file rather than -e: it carries
# quotes and a filesystem path, and threading that through a shell command
# line is a way to test the quoting rather than the ABI.
sub boot_with {
    my (%opt) = @_;
    my $env  = delete $opt{env} || {};
    my $args = delete $opt{args} || '';
    my $perl = $Config::Config{perlpath} || $^X;

    my $file = "$FindBin::Bin/abi-boot-$$.pl";
    open my $fh, '>', $file or die "cannot write $file: $!";
    print {$fh} <<"PROG";
package T;
use Punk;
markdown '/docs' => '$DOCS'$args;
package main;
T->to_app;
print "BOOTED\\n";
PROG
    close $fh;

    my @cmd = ($perl, (map { "-I$_" } @INC), $file);
    local %ENV = (%ENV, %$env);

    # Capture both streams: the interesting outcome is a croak, which lands
    # on stderr, and letting it through would scribble over the TAP.
    my $quoted = join ' ', map { my $a = $_; $a =~ s/'/'\\''/g; "'$a'" } @cmd;
    my $out = `$quoted 2>&1`;
    unlink $file;
    return $out;
}

{
    my $out = boot_with(env => { PUNK_FAKE_MDS_BAD => 1 });
    unlike $out, qr/BOOTED/, 'a bad Markdown::Simple ABI stops the boot';
    like $out, qr/Markdown::Simple/,
        'and the message names the distribution to upgrade';
    like $out, qr/0\.20\+|mds_abi/,
        'and what version or table it needs';
}

SKIP: {
    skip 'Search::Trigram not installed', 3
        unless eval { require Search::Trigram; 1 };

    my $out = boot_with(env => { PUNK_FAKE_SG_BAD => 1 });
    unlike $out, qr/BOOTED/, 'a bad Search::Trigram ABI stops the boot';
    like $out, qr/Search::Trigram/,
        'and the message names the distribution to upgrade';
    like $out, qr/search => 0/,
        'and points at the option that does without it';
}

# ---- search => 0 does not need Search::Trigram at all ------------------------

SKIP: {
    skip 'Search::Trigram not installed', 1
        unless eval { require Search::Trigram; 1 };

    # The whole point of naming the option in that croak is that it works.
    my $out = boot_with(env  => { PUNK_FAKE_SG_BAD => 1 },
                        args => ', search => 0');
    like $out, qr/BOOTED/,
        'search => 0 boots even with the Search::Trigram ABI unavailable';
}

done_testing();
