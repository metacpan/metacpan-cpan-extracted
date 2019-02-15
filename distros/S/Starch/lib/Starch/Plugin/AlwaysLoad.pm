package Starch::Plugin::AlwaysLoad;

$Starch::Plugin::AlwaysLoad::VERSION = '0.10';

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

=cut

use Moo::Role;
use strictures 2;
use namespace::clean;

with qw(
    Starch::Plugin::ForState
);

after BUILD => sub{
    my ($self) = @_;

    $self->data();

    return;
};

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

=cut

