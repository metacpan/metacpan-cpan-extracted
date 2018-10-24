use utf8;

package SemanticWeb::Schema::CollegeOrUniversity;

# ABSTRACT: A college

use Moo;

extends qw/ SemanticWeb::Schema::EducationalOrganization /;


use MooX::JSON_LD 'CollegeOrUniversity';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CollegeOrUniversity - A college

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

A college, university, or other third-level educational institution.

=head1 SEE ALSO

L<SemanticWeb::Schema::EducationalOrganization>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
