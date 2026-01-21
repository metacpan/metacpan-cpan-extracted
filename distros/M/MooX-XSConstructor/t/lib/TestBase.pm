package TestBase;

sub new {
	my ( $class, %args ) = @_;
	our %GOT = %args;
	return bless { %args }, $class;
}

1;
