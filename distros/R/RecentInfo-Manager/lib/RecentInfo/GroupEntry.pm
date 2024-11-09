package RecentInfo::GroupEntry 0.04;
use 5.020;
use Moo 2;
use experimental 'signatures';

=head1 NAME

RecentInfo::GroupEntry - recent files group XBEL entry

=cut

has ['group'] => (
    is => 'ro',
    required => 1
);

sub as_XML_fragment($self, $doc) {
    my $group = $doc->createElement('bookmark:group');
    $group->addChild($doc->createTextNode($self->group));
    #$group->setTextContent($self->group);
    return $group
}

sub from_XML_fragment( $class, $frag ) {
    $class->new(
        group => $frag->textContent,
    );
}

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/RecentInfo-Manager>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via Github
at L<https://github.com/Corion/RecentInfo-Manager/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2024-2024 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

