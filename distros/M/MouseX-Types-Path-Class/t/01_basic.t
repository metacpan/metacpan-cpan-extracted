use Test::More;
use Path::Class qw(dir file);

do {
    package Foo;
    use Mouse;
    use MouseX::Types::Path::Class;

    has 'dir' => (
        is       => 'ro',
        isa      => 'Path::Class::Dir',
        required => 1,
        coerce   => 1,
    );

    has 'file' => (
        is       => 'ro',
        isa      => 'Path::Class::File',
        required => 1,
        coerce   => 1,
    );

    package Bar;
    use Mouse;
    use MouseX::Types::Path::Class qw( Dir File );

    has 'dir' => (
        is       => 'ro',
        isa      => Dir,
        required => 1,
        coerce   => 1,
    );

    has 'file' => (
        is       => 'ro',
        isa      => File,
        required => 1,
        coerce   => 1,
    );
};

my $dir  = dir('', 'tmp');
my $file = file('', 'tmp', 'foo');

for my $class (qw(Foo Bar)) {
    my $obj = $class->new( dir => "$dir", file => [ '', 'tmp', 'foo' ] );
    isa_ok $obj => $class;
    isa_ok $obj->dir  => 'Path::Class::Dir';
    isa_ok $obj->file => 'Path::Class::File';
    is $obj->dir  => $dir;
    is $obj->file => $file;
}

done_testing;
