use utf8;

package SemanticWeb::Schema::HowToDirection;

# ABSTRACT: A direction indicating a single action to do in the instructions for how to achieve a result.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork SemanticWeb::Schema::ListItem /;


use MooX::JSON_LD 'HowToDirection';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has after_media => (
    is        => 'rw',
    predicate => '_has_after_media',
    json_ld   => 'afterMedia',
);



has before_media => (
    is        => 'rw',
    predicate => '_has_before_media',
    json_ld   => 'beforeMedia',
);



has during_media => (
    is        => 'rw',
    predicate => '_has_during_media',
    json_ld   => 'duringMedia',
);



has perform_time => (
    is        => 'rw',
    predicate => '_has_perform_time',
    json_ld   => 'performTime',
);



has prep_time => (
    is        => 'rw',
    predicate => '_has_prep_time',
    json_ld   => 'prepTime',
);



has supply => (
    is        => 'rw',
    predicate => '_has_supply',
    json_ld   => 'supply',
);



has tool => (
    is        => 'rw',
    predicate => '_has_tool',
    json_ld   => 'tool',
);



has total_time => (
    is        => 'rw',
    predicate => '_has_total_time',
    json_ld   => 'totalTime',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::HowToDirection - A direction indicating a single action to do in the instructions for how to achieve a result.

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

A direction indicating a single action to do in the instructions for how to
achieve a result.

=head1 ATTRIBUTES

=head2 C<after_media>

C<afterMedia>

A media object representing the circumstances after performing this
direction.

A after_media should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MediaObject']>

=item C<Str>

=back

=head2 C<_has_after_media>

A predicate for the L</after_media> attribute.

=head2 C<before_media>

C<beforeMedia>

A media object representing the circumstances before performing this
direction.

A before_media should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MediaObject']>

=item C<Str>

=back

=head2 C<_has_before_media>

A predicate for the L</before_media> attribute.

=head2 C<during_media>

C<duringMedia>

A media object representing the circumstances while performing this
direction.

A during_media should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MediaObject']>

=item C<Str>

=back

=head2 C<_has_during_media>

A predicate for the L</during_media> attribute.

=head2 C<perform_time>

C<performTime>

=for html <p>The length of time it takes to perform instructions or a direction (not
including time to prepare the supplies), in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 duration
format</a>.<p>

A perform_time should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<_has_perform_time>

A predicate for the L</perform_time> attribute.

=head2 C<prep_time>

C<prepTime>

=for html <p>The length of time it takes to prepare the items to be used in
instructions or a direction, in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 duration
format</a>.<p>

A prep_time should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<_has_prep_time>

A predicate for the L</prep_time> attribute.

=head2 C<supply>

A sub-property of instrument. A supply consumed when performing
instructions or a direction.

A supply should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::HowToSupply']>

=item C<Str>

=back

=head2 C<_has_supply>

A predicate for the L</supply> attribute.

=head2 C<tool>

A sub property of instrument. An object used (but not consumed) when
performing instructions or a direction.

A tool should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::HowToTool']>

=item C<Str>

=back

=head2 C<_has_tool>

A predicate for the L</tool> attribute.

=head2 C<total_time>

C<totalTime>

=for html <p>The total time required to perform instructions or a direction
(including time to prepare the supplies), in <a
href="http://en.wikipedia.org/wiki/ISO_8601">ISO 8601 duration
format</a>.<p>

A total_time should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Duration']>

=back

=head2 C<_has_total_time>

A predicate for the L</total_time> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::ListItem>

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

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
