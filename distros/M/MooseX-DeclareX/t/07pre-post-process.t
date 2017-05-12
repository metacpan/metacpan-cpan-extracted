use Test::More tests => 1;
use MooseX::DeclareX plugins => [qw(preprocess postprocess std_constants)];

class Joiner
{
	has separator => (is => read_write, isa => 'Str', required => true);
	
	method go (@strings) {
		join $self->separator => @strings;
	}	
}

role DebuggerForJoiner
{
	preprocess go (@strings) {
		map { "[$_]" } @strings
	}

	postprocess go ($result) {
		return "{$result}";
	}
}

class DebuggedJoiner
	extends Joiner
	with DebuggerForJoiner;

my $j = DebuggedJoiner->new(separator => q[ ]);
is(
	$j->go(qw(foo bar baz)),
	'{[foo] [bar] [baz]}',
);
