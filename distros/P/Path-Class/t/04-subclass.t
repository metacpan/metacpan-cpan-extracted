#!/usr/bin/perl

# Test subclassing of Path::Class

use strict;
use warnings;

use Test::More tests => 6;

{
    package My::File;
    use parent qw(Path::Class::File);

    sub dir_class { return "My::Dir" }
}

{
    package My::Dir;
    use parent qw(Path::Class::Dir);

    sub file_class { return "My::File" }
}

{
    my $file = My::File->new("/path/to/some/file");
    isa_ok $file, "My::File";
    is $file->as_foreign("Unix"), "/path/to/some/file";

    my $dir = $file->dir;
    isa_ok $dir, "My::Dir";
    is $dir->as_foreign("Unix"), "/path/to/some";

    my $file_again = $dir->file("bar");
    isa_ok $file_again, "My::File";
    is $file_again->as_foreign("Unix"), "/path/to/some/bar";
}
