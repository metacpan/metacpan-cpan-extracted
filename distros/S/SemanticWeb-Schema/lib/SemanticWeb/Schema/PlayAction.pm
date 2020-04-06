use utf8;

package SemanticWeb::Schema::PlayAction;

# ABSTRACT: The act of playing/exercising/training/performing for enjoyment

use Moo;

extends qw/ SemanticWeb::Schema::Action /;


use MooX::JSON_LD 'PlayAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.3';


has audience => (
    is        => 'rw',
    predicate => '_has_audience',
    json_ld   => 'audience',
);



has event => (
    is        => 'rw',
    predicate => '_has_event',
    json_ld   => 'event',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::PlayAction - The act of playing/exercising/training/performing for enjoyment

=head1 VERSION

version v7.0.3

=head1 DESCRIPTION

=for html <p>The act of playing/exercising/training/performing for enjoyment,
leisure, recreation, Competition or exercise.<br/><br/> Related
actions:<br/><br/> <ul> <li><a class="localLink"
href="http://schema.org/ListenAction">ListenAction</a>: Unlike ListenAction
(which is under ConsumeAction), PlayAction refers to performing for an
audience or at an event, rather than consuming music.</li> <li><a
class="localLink" href="http://schema.org/WatchAction">WatchAction</a>:
Unlike WatchAction (which is under ConsumeAction), PlayAction refers to
showing/displaying for an audience or at an event, rather than consuming
visual content.</li> </ul> <p>

=head1 ATTRIBUTES

=head2 C<audience>

An intended audience, i.e. a group for whom something was created.

A audience should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Audience']>

=back

=head2 C<_has_audience>

A predicate for the L</audience> attribute.

=head2 C<event>

Upcoming or past event associated with this place, organization, or action.

A event should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Event']>

=back

=head2 C<_has_event>

A predicate for the L</event> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Action>

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
