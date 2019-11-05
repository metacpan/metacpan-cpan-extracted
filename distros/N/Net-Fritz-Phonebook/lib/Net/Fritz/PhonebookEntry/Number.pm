package Net::Fritz::PhonebookEntry::Number;
use strict;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
use PerlX::Maybe;

use Data::Dumper;

use vars '$VERSION';
$VERSION = '0.04';

has entry => (
    is => 'ro',
    weak_ref => 1,
);

has 'uniqueid' => (
    is => 'ro',
);

has 'person' => (
    is => 'ro',
);

has 'quickdial' => (
    is => 'ro',
    default => undef,
);

has 'vanity' => (
    is => 'ro',
    default => undef,
);

has 'prio' => (
    is => 'rw',
    default => undef,
);

=head2 C<< type >>

  home
  mobile
  work
  fax_work

All other strings get displayed as "Sonstige" but get preserved.

=cut

has 'type' => (
    is => 'rw',
    default => 'home',
);

has 'content' => (
    is => 'rw',
);

sub build_structure( $self ) {
    return {
              type      => $self->type,
              content   => $self->content,
        maybe quickdial => $self->quickdial,
        maybe vanity    => $self->vanity,
        maybe prio      => $self->prio,
    }
}

1;

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
