package SemanticWeb::Schema::Volcano;

# ABSTRACT: A volcano, like Fuji san.

use Moo;

extends qw/ SemanticWeb::Schema::Landform /;


use MooX::JSON_LD 'Volcano';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Volcano - A volcano, like Fuji san.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A volcano, like Fuji san.

=head1 SEE ALSO

L<SemanticWeb::Schema::Landform>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
