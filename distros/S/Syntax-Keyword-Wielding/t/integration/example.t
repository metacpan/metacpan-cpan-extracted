use Test2::V0;
use Syntax::Keyword::Wielding;

my @output;

BEGIN {
	package Speaker;
	sub new {
		my $class = shift;
		my $self = @_ == 1 ? shift : { @_ };
		bless $self, $class;
	}
	sub name {
		my $self = shift;
		return $self->{name};
	}
	sub speak {
		my $self = shift;
		push @output, sprintf( "%s: %s", $self->name, $_ ) for @_;
		return $self;
	}
};

my $dude    = Speaker->new( name => "The Dude" );
my $dudette = Speaker->new( name => "The Dudette" );

wielding $dude->speak {
	_ "Hello world!";
	_ "The answer to life, the universe, and everything is...", __LINE__ + 13;
	wielding $dudette->speak {
		_ "Oh, cool!", "Nice!";
	}
	_("It is indeed, as you say... cool.");
}

wielding { push @output, uc shift } {
	_ "The"
	_ "End"
}

is(
	\@output,
	[
		"The Dude: Hello world!",
		"The Dude: The answer to life, the universe, and everything is...",
		"The Dude: 42",
		"The Dudette: Oh, cool!",
		"The Dudette: Nice!",
		"The Dude: It is indeed, as you say... cool.",
		"THE",
		"END",
	],
	'works',
);

done_testing;

