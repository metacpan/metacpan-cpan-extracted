package Starch::Plugin::ForState;

$Starch::Plugin::ForState::VERSION = '0.10';

=head1 NAME

Starch::Plugin::ForState - Base role for Starch::State plugins.

=head1 SYNOPSIS

    package MyPlugin::State;
    use Moo;
    with 'Starch::Plugin::ForState';
    sub foo { print 'bar' }

    my $starch = Starch->new(
        plugins => ['MyPlugin::State'],
        ...,
    );
    $starch->state->foo(); # bar

=head1 DESCRIPTION

This role provides no additional functionality to
state plugins.  All it does is labels a plugin as a state
plugin so that Starch knows which class type it applies to.

See L<Starch::Extending/PLUGINS> for more information.

=cut

use Moo::Role;
use strictures 2;
use namespace::clean;

1;
__END__

=head1 AUTHORS AND LICENSE

See L<Starch/AUTHOR>, L<Starch/CONTRIBUTORS>, and L<Starch/LICENSE>.

=cut

