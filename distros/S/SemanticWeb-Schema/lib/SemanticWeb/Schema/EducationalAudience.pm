use utf8;

package SemanticWeb::Schema::EducationalAudience;

# ABSTRACT: An EducationalAudience.

use Moo;

extends qw/ SemanticWeb::Schema::Audience /;


use MooX::JSON_LD 'EducationalAudience';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has educational_role => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'educationalRole',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::EducationalAudience - An EducationalAudience.

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

An EducationalAudience.

=head1 ATTRIBUTES

=head2 C<educational_role>

C<educationalRole>

An educationalRole of an EducationalAudience.

A educational_role should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Audience>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
