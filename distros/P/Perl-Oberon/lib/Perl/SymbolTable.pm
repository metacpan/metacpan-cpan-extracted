package Perl::Oberon::SymbolTable;

sub new {
	my ($class) = @_;
	my $self = {
		symbtab = {},	
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub push {
	my ($self, $key, $value) = @_;

	$self->{symtab}[$key] = $value;
}	

sub value {
	my ($self, $key) = @_;

	return ($self->{symtab}[$key]);
}	

1;
