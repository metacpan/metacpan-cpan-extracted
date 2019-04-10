use utf8;

package SemanticWeb::Schema::MedicalWebPage;

# ABSTRACT: A web page that provides medical information.

use Moo;

extends qw/ SemanticWeb::Schema::WebPage /;


use MooX::JSON_LD 'MedicalWebPage';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


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

version v3.5.0

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

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
