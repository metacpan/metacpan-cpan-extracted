package MooseX::MultiInitArg::Trait; 
use Moose::Role;
use Carp qw(confess);

has init_args => (
	is        => 'ro',
	isa       => 'ArrayRef',
	predicate => 'has_init_args',
);

around initialize_instance_slot => sub {
	my $original = shift;
	my ($self, $meta_instance, $instance, $params) = @_;
	if ($self->has_init_args)
	{
		if(my @supplied = grep { exists $params->{$_} } @{ $self->init_args })
		{
			if ($self->has_init_arg and exists $params->{ $self->init_arg })
			{
				push(@supplied, $self->init_arg);
			}

			if (@supplied > 1)
			{
				confess 'Conflicting init_args: (' . join(', ', @supplied) . ')';
			}

			$self->_set_initial_slot_value(
				$meta_instance, 
				$instance, 
				$params->{$supplied[0]},
			);

			return;
		}
	}
	$original->(@_);
};

no Moose::Role;
1;

__END__

=pod

=head1 NAME

MooseX::MultiInitArg::Trait - A composable role to add multiple init arguments
to your attributes.

=head1 DESCRIPTION

This is a composable trait which you can add to an attribute so that you can 
specify a list of aliases for your attribute to be recognized as constructor
arguments.  

=head1 AUTHOR

Paul Driver, C<< <frodwith at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2008 by Paul Driver.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

