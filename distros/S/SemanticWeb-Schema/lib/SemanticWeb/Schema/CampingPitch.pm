package SemanticWeb::Schema::CampingPitch;

# ABSTRACT: A camping pitch is an individual place for overnight stay in the outdoors

use Moo;

extends qw/ SemanticWeb::Schema::Accommodation /;


use MooX::JSON_LD 'CampingPitch';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CampingPitch - A camping pitch is an individual place for overnight stay in the outdoors

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

=for html A camping pitch is an individual place for overnight stay in the outdoors,
typically being part of a larger camping site. <br /><br /> See also the <a
href="/docs/hotels.html">dedicated document on the use of schema.org for
marking up hotels and other forms of accommodations</a>.

=head1 SEE ALSO

L<SemanticWeb::Schema::Accommodation>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
