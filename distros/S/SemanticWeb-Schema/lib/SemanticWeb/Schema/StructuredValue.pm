package SemanticWeb::Schema::StructuredValue;

# ABSTRACT: Structured values are used when the value of a property has a more complex structure than simply being a textual value or a reference to another thing.

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'StructuredValue';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::StructuredValue - Structured values are used when the value of a property has a more complex structure than simply being a textual value or a reference to another thing.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

Structured values are used when the value of a property has a more complex
structure than simply being a textual value or a reference to another
thing.

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
