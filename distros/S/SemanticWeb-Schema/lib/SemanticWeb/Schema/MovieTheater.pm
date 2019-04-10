use utf8;

package SemanticWeb::Schema::MovieTheater;

# ABSTRACT: A movie theater.

use Moo;

extends qw/ SemanticWeb::Schema::EntertainmentBusiness SemanticWeb::Schema::CivicStructure /;


use MooX::JSON_LD 'MovieTheater';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has screen_count => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'screenCount',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MovieTheater - A movie theater.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A movie theater.

=head1 ATTRIBUTES

=head2 C<screen_count>

C<screenCount>

The number of screens in the movie theater.

A screen_count should be one of the following types:

=over

=item C<Num>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CivicStructure>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
