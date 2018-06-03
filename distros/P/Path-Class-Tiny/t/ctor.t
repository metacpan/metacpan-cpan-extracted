use Test::Most 0.25;

use Path::Class::Tiny;


my $CLASS = 'Path::Class::Tiny';

foreach my $f ( qw< path file dir > )
{
	no strict 'refs';
	my $p = $f->('/', 'tmp', 'foo');
	isa_ok $p, $_, "obj created with $f()"
			foreach $CLASS, qw< Path::Tiny >; # Path::Class::File Path::Class::Dir Path::Class::Entity
}

# make sure all forms of file() and dir() work
	# dir() as a global function, with args
	is dir('/', 'tmp'), path('/', 'tmp'), 'dir(@args) works';
	# dir() as global function, no args
	is dir(), Path::Tiny->cwd, 'dir() works';
	# dir() as method, with args
	is path('/', 'tmp', 'foo')->dir, path('/', 'tmp'), '->dir(@args) works';
	# file() as a global function, with args
	is file('/', 'tmp', 'foo'), path('/', 'tmp', 'foo'), 'file(@args) works';
	# file() as method, with args
	is path('/', 'tmp')->file('foo'), path('/', 'tmp', 'foo'), '->file(@args) works';

my $p = $CLASS->new('/', 'tmp', 'foo');
isa_ok $p, $CLASS, "obj created with new()";


done_testing;
