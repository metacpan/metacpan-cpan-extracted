use utf8;

package SemanticWeb::Schema::TVClip;

# ABSTRACT: A short TV program or a segment/part of a TV program.

use Moo;

extends qw/ SemanticWeb::Schema::Clip /;


use MooX::JSON_LD 'TVClip';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has part_of_tv_series => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'partOfTVSeries',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::TVClip - A short TV program or a segment/part of a TV program.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

A short TV program or a segment/part of a TV program.

=head1 ATTRIBUTES

=head2 C<part_of_tv_series>

C<partOfTVSeries>

The TV series to which this episode or season belongs.

A part_of_tv_series should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::TVSeries']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Clip>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
