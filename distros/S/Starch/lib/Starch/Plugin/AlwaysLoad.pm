package Starch::Plugin::AlwaysLoad;
our $VERSION = '0.14';

use Moo::Role;
use strictures 2;
use namespace::clean;

with 'Starch::Plugin::ForState';

after BUILD => sub{
    my ($self) = @_;

    $self->data();

    return;
};

1;
__END__

=encoding utf8

=head1 NAME

Starch::Plugin::AlwaysLoad - Always retrieve state data.

=head1 SYNOPSIS

    my $starch = Starch->new(
        plugins => ['::AlwaysLoad'],
        ...,
    );

=head1 DESCRIPTION

This plugin causes L<Starch::State/data> to be always loaded
from the store as soon as the state object is created.  By default
the state data is only retrieved from the store when it is first
accessed.

=head1 SUPPORT

See L<Starch/SUPPORT>.

=head1 AUTHORS

See L<Starch/AUTHORS>.

=head1 COPYRIGHT AND LICENSE

See L<Starch/COPYRIGHT AND LICENSE>.

=cut

