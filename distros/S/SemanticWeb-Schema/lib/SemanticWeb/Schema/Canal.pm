use utf8;

package SemanticWeb::Schema::Canal;

# ABSTRACT: A canal, like the Panama Canal.

use Moo;

extends qw/ SemanticWeb::Schema::BodyOfWater /;


use MooX::JSON_LD 'Canal';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Canal - A canal, like the Panama Canal.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A canal, like the Panama Canal.

=head1 SEE ALSO

L<SemanticWeb::Schema::BodyOfWater>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
