#!perl -w
# given some class:
use strict;
{
    package My::Module;
    use Mouse;

    has package => (
        is => "ro",
        init_arg => "name",
    );

    has version => (
        is  => "rw",
        init_arg => undef,
    );

    sub BUILD { shift->version(3) }
}

# load an object like so:

use MouseX::YAML qw(Load);

my $obj = Load(<<'YAML');
--- !!perl/hash:My::Module
name: "MouseX::YAML"
YAML

print $obj->dump;
