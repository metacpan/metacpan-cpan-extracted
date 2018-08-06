package SemanticWeb::Schema::HinduTemple;

# ABSTRACT: A Hindu temple.

use Moo;

extends qw/ SemanticWeb::Schema::PlaceOfWorship /;


use MooX::JSON_LD 'HinduTemple';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::HinduTemple - A Hindu temple.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A Hindu temple.

=head1 SEE ALSO

L<SemanticWeb::Schema::PlaceOfWorship>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
