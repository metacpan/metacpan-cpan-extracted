use strict;
use warnings;

# Test that we can support different ways of describing perl versions

our (@versions, @invalid);
BEGIN {
    require Module::CoreList;

    # These are all valid versions, but not in the format used in
    # Module::CoreList
    @versions = (
        qw(
            5.0
            5.0.0
            5.1
            5.1.0
            5.2
            5.2.0
            5.3.7
            5.003_07
            5.4
            5.4.0
            5.5
            5.5.0
            5.5.3
            5.005_03
            5.5.4
            5.005_04
            5.6
            5.6.0
            5.6.1
            5.6.2
            5.7.3
            5.8
            5.8.0
            5.8.1
            5.8.2
            5.8.3
            5.8.4
            5.8.5
            5.8.6
            5.8.7
            5.9
            5.9.0
            5.9.1
            5.9.2
        ),
        # Plus check that the "official" spellings work
        keys %Module::CoreList::version,
    );

    @invalid = qw(
        4
        4.0.0
        4.0.1
        5.2.10
        foo
    );
}

use Test::More tests => 1 + @versions + @invalid;

eval { require Module::Mask::Deps };
ok(!$@, 'loaded Module::Mask::Deps');

for my $v (@versions) {
    my @core = eval { Module::Mask::Deps->_get_core($v) };
    ok(@core, "got core for $v");
}

for my $v (@invalid) {
    eval { Module::Mask::Deps->_get_core($v) };
    like(
        $@, qr(Couldn't find core modules for perl $v),
        "getting core for $v died as expected"
    );
}

__END__

vim: ft=perl ts=8 sts=4 sw=4 sr et
