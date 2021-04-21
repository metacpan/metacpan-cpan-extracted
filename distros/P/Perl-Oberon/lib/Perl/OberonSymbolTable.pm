package Perl::Oberon::OberonSymbolTable;

use parent 'Perl::Oberon::SymbolTable';

sub new {
	my ($class, $name) = @_;
        my $self = $class->SUPER::new;

	$self->{SCOPE} = 10;
}

### push list of variables and function bodies in scope $key
sub push_scope {
	my ($self, $key @procedures_and_variables) = @_;

	$self->{symbtab}[$key] = ($SCOPE, @procedures_and_variables);
	$self->{SCOPE}+=10;
}

sub push_variable_key {
	my ($self, $key, $value) = @_;

	$self->push($key, ('VARIABLE', $value));
}

sub push_procedure_key {
	my ($self, $key, $tokens) = @_;

	$self->push($key, ('BODY', $tokens));
}

1;
