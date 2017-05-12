#!perl

use strict;
use warnings;

use File::Spec;
use Test::More;
use Test::Compile::Internal;

plan skip_all => "I don't know how to redirect STDERR on your crazy OS"
    unless $^O =~ m/linux|.*bsd|solaris|darwin/;


sub makeAnError {
    my ($verbose) = @_;

    my $internal = Test::Compile::Internal->new();
    $internal->verbose($verbose);

    # Might output "$0 syntax OK" to STDERR
    $internal->pl_file_compiles($0);
}

sub main {
    my (@args) = @_;

    if ( @args && $args[0] =~ m/silent/ ) {
        makeAnError(0);
        return;
    }
    if ( @args && $args[0] =~ m/verbose/ ) {
        makeAnError(1);
        return;
    }

    local $ENV{PERL5LIB} = join(":",@INC);
    my $cmd = "$^X $0";

    my $silent = `$cmd silent 2>&1`;
    is($silent,"","no output when in silent mode");

    my $verbose = `$cmd verbose 2>&1`;
    isnt($verbose,"","got some output when in verbose mode");

    done_testing();
}

main(@ARGV) unless caller;
