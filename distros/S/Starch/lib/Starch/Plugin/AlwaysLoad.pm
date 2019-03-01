package Starch::Plugin::AlwaysLoad;
use 5.008001;
use strictures 2;
our $VERSION = '0.12';

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

See L<Starch/AUTHORS> and L<Starch/LICENSE>.

=cut

