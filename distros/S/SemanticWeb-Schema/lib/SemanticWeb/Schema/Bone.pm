use utf8;

package SemanticWeb::Schema::Bone;

# ABSTRACT: Rigid connective tissue that comprises up the skeletal structure of the human body.

use Moo;

extends qw/ SemanticWeb::Schema::AnatomicalStructure /;


use MooX::JSON_LD 'Bone';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Bone - Rigid connective tissue that comprises up the skeletal structure of the human body.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

Rigid connective tissue that comprises up the skeletal structure of the
human body.

=head1 SEE ALSO

L<SemanticWeb::Schema::AnatomicalStructure>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
