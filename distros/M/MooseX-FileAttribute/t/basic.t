use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;
use File::Spec;

{
    package Class;
    use Moose;
    use MooseX::FileAttribute;

    has_file 'file';
    has_directory 'dir';
}

my $c = Class->new( file => 'file', dir => 'dir' );
isa_ok $c, 'Class';
isa_ok $c->file, 'Path::Class::File';
isa_ok $c->dir, 'Path::Class::Dir';

{
    package EfClass;
    use Moose;
    use MooseX::FileAttribute;

    has_file 'file' => ( must_exist => 1 );
}

my $no_exist
    = File::Spec->catfile( '', qw/omg hopefully this does not exist!/ );

throws_ok {
    EfClass->new( file => $no_exist );
} qr/File '\Q$no_exist\E' must exist./, 'file must exist';

{
    package EdClass;
    use Moose;
    use MooseX::FileAttribute;

    has_directory 'dir' => ( must_exist => 1 );
}

throws_ok {
    EdClass->new( dir => $no_exist );
} qr/Directory '\Q$no_exist\E' must exist./, 'directory must exist';

lives_ok {
    EdClass->new( dir => '.' ); # if the current directory does not exist, I hate you.
} 'existing dir constraint passes on existing dir';
