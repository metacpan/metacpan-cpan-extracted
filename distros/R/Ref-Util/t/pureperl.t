use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => "All tests already executed in PP mode"
        if !eval { require Ref::Util::XS };

    no warnings 'uninitialized';
    plan skip_all => "Already running pure-Perl tests"
        if $ENV{PERL_REF_UTIL_IMPLEMENTATION} eq 'PP';
}

use Config;
use IPC::Open2 qw(open2);
use File::Find qw(find);

local $ENV{PERL_REF_UTIL_IMPLEMENTATION} = 'PP';
local $ENV{PERL5LIB} = join $Config{path_sep}, @INC;

my $this_file = quotemeta __FILE__;

find({ no_chdir => 1, wanted => sub {
    return if !/\.t\z/;

    my @cmd = ($^X, $_);

    open2(my $out, my $in, @cmd);
    while (my $line = <$out>) {
        print "   $line";
    }

    wait;
    ok !$?, "Exit $? from: @cmd";
} }, 't');

done_testing();
