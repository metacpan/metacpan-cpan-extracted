#!/usr/bin/env perl

use strict;
use Test::More;
use Path::Class::Iterator;

require "t/help.pl";

my $no_links = setup();

if ($no_links)
{
    plan tests => 11;
}
else
{
    plan tests => 12;
}

my $root    = 'test';
my $skipped = 0;

sub debug
{
    diag(@_) if $ENV{PERL_TEST};
}

ok(
    my $walker = Path::Class::Iterator->new(
        root          => $root,
        error_handler => sub {
            my ($self, $path, $msg) = @_;

            debug $self->error;
            debug "we'll skip $path";
            $skipped++;

            return 1;
        },
        follow_symlinks => 1,
        breadth_first   => 1
                                           ),
    "new object"
  );

my $count = 0;
until ($walker->done)
{
    my $f = $walker->next;
    my $d = $f->depth;
    ok($d eq $f->depth, "depth");

    debug("$f  -> $d");

    $count++;

}

ok($count > 1, "found some files");
debug "skipped $skipped files";
unless ($no_links)
{
    cmp_ok($skipped, '==', 2, "skipped bad links");
}

cleanup();

