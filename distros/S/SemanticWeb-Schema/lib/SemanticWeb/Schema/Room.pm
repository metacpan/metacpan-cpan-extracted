package SemanticWeb::Schema::Room;

# ABSTRACT: A room is a distinguishable space within a structure

use Moo;

extends qw/ SemanticWeb::Schema::Accommodation /;


use MooX::JSON_LD 'Room';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Room - A room is a distinguishable space within a structure

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

=for html A room is a distinguishable space within a structure, usually separated
from other spaces by interior walls. (Source: Wikipedia, the free
encyclopedia, see <a
href="http://en.wikipedia.org/wiki/Room">http://en.wikipedia.org/wiki/Room<
/a>). <br /><br /> See also the <a href="/docs/hotels.html">dedicated
document on the use of schema.org for marking up hotels and other forms of
accommodations</a>.

=head1 SEE ALSO

L<SemanticWeb::Schema::Accommodation>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
