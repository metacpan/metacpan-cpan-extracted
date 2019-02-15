package Starch::Plugin::ForStore;

$Starch::Plugin::ForStore::VERSION = '0.10';

=head1 NAME

Starch::Plugin::ForStore - Base role for Starch::Store plugins.

=head1 SYNOPSIS

    package MyPlugin::Store;
    use Moo;
    with 'Starch::Plugin::ForStore';
    sub foo { print 'bar' }

    my $starch = Starch->new(
        plugins => ['MyPlugin::Store'],
        ...,
    );
    $starch->store->foo(); # bar

=head1 DESCRIPTION

This role provides no additional functionality to
store plugins.  All it does is labels a plugin as a store
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

