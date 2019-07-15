use utf8;

package SemanticWeb::Schema::MedicalWebPage;

# ABSTRACT: A web page that provides medical information.

use Moo;

extends qw/ SemanticWeb::Schema::WebPage /;


use MooX::JSON_LD 'MedicalWebPage';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has aspect => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'aspect',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalWebPage - A web page that provides medical information.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A web page that provides medical information.

=head1 ATTRIBUTES

=head2 C<aspect>

An aspect of medical practice that is considered on the page, such as
'diagnosis', 'treatment', 'causes', 'prognosis', 'etiology',
'epidemiology', etc.

A aspect should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::WebPage>

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
