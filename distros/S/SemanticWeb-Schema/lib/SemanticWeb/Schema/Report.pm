use utf8;

package SemanticWeb::Schema::Report;

# ABSTRACT: A Report generated by governmental or non-governmental organization.

use Moo;

extends qw/ SemanticWeb::Schema::Article /;


use MooX::JSON_LD 'Report';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has report_number => (
    is        => 'rw',
    predicate => '_has_report_number',
    json_ld   => 'reportNumber',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Report - A Report generated by governmental or non-governmental organization.

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

A Report generated by governmental or non-governmental organization.

=head1 ATTRIBUTES

=head2 C<report_number>

C<reportNumber>

The number or other unique designator assigned to a Report by the
publishing organization.

A report_number should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_report_number>

A predicate for the L</report_number> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Article>

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

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
