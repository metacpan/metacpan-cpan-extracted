use utf8;

package SemanticWeb::Schema::AudioObject;

# ABSTRACT: An audio file.

use Moo;

extends qw/ SemanticWeb::Schema::MediaObject /;


use MooX::JSON_LD 'AudioObject';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has transcript => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'transcript',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::AudioObject - An audio file.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

An audio file.

=head1 ATTRIBUTES

=head2 C<transcript>

If this MediaObject is an AudioObject or VideoObject, the transcript of
that object.

A transcript should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MediaObject>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
