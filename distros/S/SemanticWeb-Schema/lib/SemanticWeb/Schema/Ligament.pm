use utf8;

package SemanticWeb::Schema::Ligament;

# ABSTRACT: A short band of tough

use Moo;

extends qw/ SemanticWeb::Schema::AnatomicalStructure /;


use MooX::JSON_LD 'Ligament';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Ligament - A short band of tough

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A short band of tough, flexible, fibrous connective tissue that functions
to connect multiple bones, cartilages, and structurally support joints.

=head1 SEE ALSO

L<SemanticWeb::Schema::AnatomicalStructure>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
