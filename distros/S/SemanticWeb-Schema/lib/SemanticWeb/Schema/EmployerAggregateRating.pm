use utf8;

package SemanticWeb::Schema::EmployerAggregateRating;

# ABSTRACT: An aggregate rating of an Organization related to its role as an employer.

use Moo;

extends qw/ SemanticWeb::Schema::AggregateRating /;


use MooX::JSON_LD 'EmployerAggregateRating';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::EmployerAggregateRating - An aggregate rating of an Organization related to its role as an employer.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

An aggregate rating of an Organization related to its role as an employer.

=head1 SEE ALSO

L<SemanticWeb::Schema::AggregateRating>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
