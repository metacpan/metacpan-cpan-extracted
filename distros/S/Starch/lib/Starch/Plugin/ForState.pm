package Starch::Plugin::ForState;
our $VERSION = '0.14';

use Moo::Role;
use strictures 2;
use namespace::clean;

1;
__END__

=encoding utf8

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

=head1 SUPPORT

See L<Starch/SUPPORT>.

=head1 AUTHORS

See L<Starch/AUTHORS>.

=head1 COPYRIGHT AND LICENSE

See L<Starch/COPYRIGHT AND LICENSE>.

=cut

