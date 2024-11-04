package RecentInfo::Application 0.03;
use 5.020;
use Moo 2;
use experimental 'signatures';

=head1 NAME

RecentInfo::Application - recent files application XBEL entry

=cut

has ['name', 'exec'] => (
    is => 'ro',
    required => 1
);

has ['modified', 'count'] => (
    is => 'rw',
    required => 1
);

sub as_XML_fragment($self, $doc) {
    my $app = $doc->createElement('bookmark:application');
    $app->setAttribute("name" =>  $self->name);
    $app->setAttribute("exec" =>  $self->exec);
    $app->setAttribute("modified" =>  $self->modified);
    $app->setAttribute("count" => $self->count);
    return $app
}

sub from_XML_fragment( $class, $frag ) {
    $class->new(
        name  => $frag->getAttribute('name'),
        exec  => $frag->getAttribute('exec'),
        modified  => $frag->getAttribute('modified'),
        count => $frag->getAttribute('count'),
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

