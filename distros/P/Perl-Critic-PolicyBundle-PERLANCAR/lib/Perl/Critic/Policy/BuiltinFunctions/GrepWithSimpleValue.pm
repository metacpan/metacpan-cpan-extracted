## no critic (Modules::RequireFilenameMatchesPackage)
package Perl::Critic::PolicyBundle::PERLANCAR::BuiltinFunctions::GrepWithSimpleValue;
package # hide from PAUSE
    Perl::Critic::Policy::BuiltinFunctions::GrepWithSimpleValue;

our $DATE = '2017-08-16'; # DATE
our $VERSION = '0.002'; # VERSION

use warnings;
use strict;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils qw/:severities is_function_call/;
use Perl::Critic::Utils::PPI qw/is_ppi_constant_element/;

sub supported_parameters { return }
sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes { return qw/core bugs/ }
sub applies_to { return 'PPI::Token::Word' }

my $DESC = q{"grep" with constant value};
my $EXPL = q{Will return all or none of the values};

# based partially on
# Perl::Critic::Policy::BuiltinFunctions::ProhibitComplexMappings

sub violates {
	my ($self, $elem) = @_;
	return if $elem->content() ne 'grep';
	return if !is_function_call($elem);
	my $sib = $elem->snext_sibling();
	return $self->violation('Nothing following "grep"?',
		'It seems there is a lone "grep" in your code?',
		$elem) if !$sib;
	my $arg = $sib;
	if ( $arg->isa('PPI::Structure::List') ) {
		$arg = $arg->schild(0);
		$arg && $arg->isa('PPI::Statement::Expression')
			and $arg = $arg->schild(0);
	}
	if ($arg && $arg->isa('PPI::Structure::Block')) {
		my $stmt = $arg->schild(-1);
		return $self->violation($DESC,$EXPL,$sib)
			if !$stmt
			|| $stmt->isa('PPI::Statement')
			&& (   $stmt->schildren()==1
				|| $stmt->schildren()==2
					&& $stmt->schild(1)->isa('PPI::Token::Structure')
					&& $stmt->schild(1)->content eq ';' )
			&& is_ppi_constant_element($stmt->schild(0));
	}
	elsif ($arg && is_ppi_constant_element($arg))
		{ return $self->violation($DESC,$EXPL,$sib) }
	return;
}

1;
# ABSTRACT: Warn grep with simple value

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::PolicyBundle::PERLANCAR::BuiltinFunctions::GrepWithSimpleValue - Warn grep with simple value

=head1 VERSION

This document describes version 0.002 of Perl::Critic::PolicyBundle::PERLANCAR::BuiltinFunctions::GrepWithSimpleValue (from Perl distribution Perl-Critic-PolicyBundle-PERLANCAR), released on 2017-08-16.

=head1 SYNOPSIS

=head1 DESCRIPTION

This policy is written by HAUKEX.

A C<grep> with a constant value as the last thing in its block will either
return all or none of the items in the list (depending on whether the value is
true or false). You may have accidentally said C<grep {123}> when you meant
C<grep {$_==123}>, or C<grep {"foo"}> when you meant C<grep {$_ eq "foo"}> or
C<grep {/foo/}>.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perl-Critic-PolicyBundle-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perl-Critic-PolicyBundle-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Critic-PolicyBundle-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<http://perlmonks.org/?node_id=1196368>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
