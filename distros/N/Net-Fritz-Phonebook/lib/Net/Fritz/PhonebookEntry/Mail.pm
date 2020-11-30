package Net::Fritz::PhonebookEntry::Mail;
use strict;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

use Data::Dumper;

use vars '$VERSION';
$VERSION = '0.05';

has entry => (
    is => 'ro',
    weak_ref => 1,
);

has 'classifier' => (
    is => 'rw',
    default => 'private',
);

has 'content' => (
    is => 'rw',
);

around BUILDARGS => sub( $orig, $class, %args ) {
    my %self = (
        exists $args{ email }->[0]->{classifier}
        ? (classifier => $args{ email }->[0]->{classifier}) : (),
        content    => $args{ email }->[0]->{content},
    );
    $class->$orig( %self );
};

sub build_structure( $self ) {
    return {
        email => [{
            classifier => $self->classifier,
            content => $self->content,
        }],
    }
}

1;

=head1 SEE ALSO

L<https://avm.de/fileadmin/user_upload/Global/Service/Schnittstellen/X_contactSCPD.pdf>

=cut

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Net-Fritz-Phonebook>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Net-Fritz-Phonebook>
or via mail to L<net-fritz-phonebook-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2017 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
