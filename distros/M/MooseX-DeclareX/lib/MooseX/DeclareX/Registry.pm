package MooseX::DeclareX::Registry;

BEGIN {
	$MooseX::DeclareX::Registry::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::DeclareX::Registry::VERSION   = '0.009';
}

our %context_allow_options;

BEGIN
{
	require MooseX::Declare;
}

use Moose::Role;

has registered_features => (
	is        => 'ro',
	isa       => 'HashRef',
	default   => sub {{}},
	);

has registered_options => (
	is        => 'ro',
	isa       => 'HashRef',
	default   => sub {{}},
	);

sub register_option
{
	my ($self, $option, $callback) = @_;
	return if exists $self->registered_options->{$option};
	$self->registered_options->{$option} = $callback;
	$self->meta->add_method("add_${option}_option_customizations", $callback);
	$context_allow_options{$option} = 1;
	return 1;
}

sub register_feature
{
	my ($self, $feature, $callback) = @_;
	return if exists $self->registered_features->{$feature};
	$self->registered_features->{$feature} = $callback;
	return 1;
}

requires 'add_optional_customizations';
before add_optional_customizations => sub
{
	my ($self, $ctx, $package) = @_;
	
	my %features = %{ $self->registered_features // {} };
	foreach my $f (sort keys %features)
	{
		if (exists $ctx->options->{is}{$f})
		{
			my $code = $features{$f};
			$code->($self, $ctx, $package);
		}
	}
};

requires 'context_traits';
around context_traits	=> sub {
	my $orig = shift;
	my $self = shift;
	my @traits = $self->$orig();
	push @traits, 'MooseX::DeclareX::RegistryUsing';
	return @traits;
};

1;
