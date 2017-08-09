package Perl::Critic::PolicyBundle::PERLANCAR;
package # hide from PAUSE
    Perl::Critic::Policy::Variables::ProhibitFatCommaInDeclaration;

our $DATE = '2017-08-01'; # DATE
our $VERSION = '0.001'; # VERSION

use warnings;
use strict;
use base 'Perl::Critic::Policy';
use Perl::Critic::Utils ':severities';
use List::Util 'first';

sub supported_parameters { return }
sub default_severity { return $SEVERITY_HIGH }
sub default_themes { return qw/core bugs/ }
sub applies_to { return 'PPI::Statement::Variable' }

sub violates {
    my ($self, $elem) = @_;
    my $found = first { $_->isa('PPI::Token::Operator') } $elem->children;
    if ($found && $found->content eq '=>') {
		return $self->violation('Fat comma used in declaration',
			'You probably meant "=" instead of "=>"', $found);
    }
    return;
}

1;
# ABSTRACT: Prohibit fat comma in declaration

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::PolicyBundle::PERLANCAR - Prohibit fat comma in declaration

=head1 VERSION

This document describes version 0.001 of Perl::Critic::PolicyBundle::PERLANCAR (from Perl distribution Perl-Critic-PolicyBundle-PERLANCAR), released on 2017-08-01.

=head1 SYNOPSIS

=head1 DESCRIPTION

This policy is written by HAUKEX.

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

L<http://perlmonks.org/?node_id=1180082>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
