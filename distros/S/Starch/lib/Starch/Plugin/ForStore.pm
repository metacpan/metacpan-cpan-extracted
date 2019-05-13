package Starch::Plugin::ForStore;
our $VERSION = '0.14';

use Moo::Role;
use strictures 2;
use namespace::clean;

1;
__END__

=encoding utf8

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

=head1 SUPPORT

See L<Starch/SUPPORT>.

=head1 AUTHORS

See L<Starch/AUTHORS>.

=head1 COPYRIGHT AND LICENSE

See L<Starch/COPYRIGHT AND LICENSE>.

=cut

