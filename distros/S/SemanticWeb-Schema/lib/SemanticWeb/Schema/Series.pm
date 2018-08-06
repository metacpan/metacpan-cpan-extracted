package SemanticWeb::Schema::Series;

# ABSTRACT: A Series in schema

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Series';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Series - A Series in schema

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A Series in schema.org is a group of related items, typically but not
necessarily of the same kind.

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
