use utf8;

package SemanticWeb::Schema::MusicComposition;

# ABSTRACT: A musical composition.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'MusicComposition';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has composer => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'composer',
);



has first_performance => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'firstPerformance',
);



has included_composition => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'includedComposition',
);



has iswc_code => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'iswcCode',
);



has lyricist => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'lyricist',
);



has lyrics => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'lyrics',
);



has music_arrangement => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'musicArrangement',
);



has music_composition_form => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'musicCompositionForm',
);



has musical_key => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'musicalKey',
);



has recorded_as => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'recordedAs',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MusicComposition - A musical composition.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A musical composition.

=head1 ATTRIBUTES

=head2 C<composer>

The person or organization who wrote a composition, or who is the composer
of a work performed at some event.

A composer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<first_performance>

C<firstPerformance>

The date and place the work was first performed.

A first_performance should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Event']>

=back

=head2 C<included_composition>

C<includedComposition>

Smaller compositions included in this work (e.g. a movement in a symphony).

A included_composition should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicComposition']>

=back

=head2 C<iswc_code>

C<iswcCode>

The International Standard Musical Work Code for the composition.

A iswc_code should be one of the following types:

=over

=item C<Str>

=back

=head2 C<lyricist>

The person who wrote the words.

A lyricist should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<lyrics>

The words in the song.

A lyrics should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=back

=head2 C<music_arrangement>

C<musicArrangement>

An arrangement derived from the composition.

A music_arrangement should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicComposition']>

=back

=head2 C<music_composition_form>

C<musicCompositionForm>

The type of composition (e.g. overture, sonata, symphony, etc.).

A music_composition_form should be one of the following types:

=over

=item C<Str>

=back

=head2 C<musical_key>

C<musicalKey>

The key, mode, or scale this composition uses.

A musical_key should be one of the following types:

=over

=item C<Str>

=back

=head2 C<recorded_as>

C<recordedAs>

An audio recording of the work.

A recorded_as should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MusicRecording']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
