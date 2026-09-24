#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Find;
use File::Spec;
use File::Basename qw(dirname);
use ExtUtils::Manifest qw(manicheck);

# Author-only tests: they verify the distribution itself (MANIFEST in sync,
# consistent versions) and are meaningless to a user installing the module.
unless ($ENV{AUTHOR_TESTING}) {
    plan skip_all => 'author test; set AUTHOR_TESTING=1 to run';
}

my $root = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));
my $lib  = File::Spec->catdir($root, 'lib');

# --- MANIFEST is in sync with the working tree ---------------------------
# manicheck() honours MANIFEST.SKIP, so dev-only paths (.github/, maint/)
# and build artifacts are ignored. A dirty MANIFEST means the tarball from
# `make dist` would silently drop or add files.
my @manifest_warnings = manicheck();
is_deeply(\@manifest_warnings, [], 'MANIFEST matches the working tree');

# --- every module shares the distribution version ------------------------
# The dist version comes from lib/Protocol/IR/Code.pm (VERSION_FROM). Keeping every
# module in step avoids confusion about which version was actually released.
my @modules;
find(sub {
    return unless /\.pm$/;
    (my $rel = $File::Find::name) =~ s{^\Q$lib\E/}{};
    (my $module = $rel) =~ s{/}{::}g;
    $module =~ s{\.pm$}{};
    push @modules, $module;
}, $lib);

eval "require Protocol::IR::Code";
die $@ if $@;
my $want = $Protocol::IR::Code::VERSION;

my @mismatch;
for my $module (sort @modules) {
    eval "require $module";
    fail("cannot load $module: $@"), next if $@;
    my $got = eval "no strict 'refs'; \$${module}::VERSION";
    push @mismatch, "$module ($got)" unless $got eq $want;
}
is_deeply(\@mismatch, [], "all modules report version $want");

done_testing;
