package MooX::ClassAttribute::HandleMoose;

use 5.008;
use strict;
use warnings;

BEGIN {
	$MooX::ClassAttribute::HandleMoose::AUTHORITY = 'cpan:TOBYINK';
	$MooX::ClassAttribute::HandleMoose::VERSION   = '0.011';
}

{
	package MooX::ClassAttribute;
	
	our %ROLE;
	our %CLASS;
	our %ATTRIBUTES;
	
	my $warning;
	sub _on_inflation
	{
		my ($me, $target, $args) = @_;
		my $meta = $args->[0];
		
		eval { require MooseX::ClassAttribute }
			or do { carp <<WARNING unless $warning++; return };
***
*** MooX::ClassAttribute and Moose, but MooseX::ClassAttribute is not
*** available. It is strongly recommended that you install this module.
***
WARNING
	
	1;#meh
		require Moose::Util::MetaRole;
		if ( is_role($meta->name) )
		{
			$meta = Moose::Util::MetaRole::apply_metaroles(
				for             => $meta->name,
				role_metaroles  => {
					role                 => ['MooseX::ClassAttribute::Trait::Role'],
					application_to_class => ['MooseX::ClassAttribute::Trait::Application::ToClass'],
					application_to_role  => ['MooseX::ClassAttribute::Trait::Application::ToRole'],
				},
			);
		}
		else
		{
			$meta = Moose::Util::MetaRole::apply_metaroles(
				for             => $meta->name,
				class_metaroles => {
					class => ['MooseX::ClassAttribute::Trait::Class'] #,'MooseX::ClassAttribute::Hack']
				},
			);
		}
		
		my $attrs = $ATTRIBUTES{$target} || [];
		for (my $i = 0; $i < @$attrs; $i+=2)
		{
			my $name = $attrs->[$i+0];
			my $spec = $attrs->[$i+1];
			MooseX::ClassAttribute::class_has(
				$meta,
				$name,
				$me->_sanitize_spec($name, $spec),
			);
		}
		
		$args->[0] = $meta; # return new $meta
	}
	
	my %ok_options = map { ;$_=>1 } qw(
		is reader writer accessor clearer predicate handles
		required isa does coerce trigger
		default builder lazy_build lazy
		documentation
	);
	
	sub _sanitize_spec
	{
		my ($me, $name, $spec) = @_;
		my %spec = %$spec;
		
		my $TYPE_MAP = \%Moo::HandleMoose::TYPE_MAP;
		
		# Stolen from Moo::HandleMoose
		$spec{is} = 'ro' if $spec{is} eq 'lazy' || $spec{is} eq 'rwp';
		if (my $isa = $spec{isa}) {
			my $tc = $spec{isa} = do {
				if (my $mapped = $TYPE_MAP->{$isa}) {
					$mapped->();
				} else {
					Moose::Meta::TypeConstraint->new(
						constraint => sub { eval { &$isa; 1 } }
					);
				}
			};
			if (my $coerce = $spec{coerce}) {
				$tc
					-> coercion(Moose::Meta::TypeCoercion->new)
					-> _compiled_type_coercion($coerce);
				$spec{coerce} = 1;
			}
		}
		elsif (my $coerce = $spec{coerce}) {
			my $attr = perlstring($name);
			my $tc = Moose::Meta::TypeConstraint->new(
				constraint => sub { die "This is not going to work" },
				inlined    => sub { 'my $r = $_[42]{'.$attr.'}; $_[42]{'.$attr.'} = 1; $r' },
			);
			$tc
				-> coercion(Moose::Meta::TypeCoercion->new)
				-> _compiled_type_coercion($coerce);
			$spec{isa}    = $tc;
			$spec{coerce} = 1;
		}
		
		my @return;
		for my $key (%spec)
		{
			next unless $ok_options{$key};
			push @return, $key, $spec->{$key};
		}
		return (
			@return,
			definition_context => { package => __PACKAGE__ },
		);
	}
}

## This doesn't actually seem needed any more...
#{
#	package
#  MooseX::ClassAttribute::Hack;
#	use Moo::Role;
#	around _post_add_class_attribute => sub {
#		my $orig = shift;
#		my $self = shift;
#		return if $self->definition_context->{package} eq 'MooX::ClassAttribute';
#		$self->$orig(@_);
#	};
#}

1;

__END__

=head1 NAME

MooX::ClassAttribute::HandleMoose - Moose inflation stuff

=head1 DESCRIPTION

For an idea of how this works, see the very fine documentation for
L<Moo::HandleMoose>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-ClassAttribute>.

=head1 SEE ALSO

L<Moo::HandleMoose>,
L<MooX::ClassAttribute>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

