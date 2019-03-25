package Starch::Plugin::ForManager;
use 5.008001;
use strictures 2;
our $VERSION = '0.13';

=head1 NAME

Starch::Plugin::ForManager - Base role for Starch plugins.

=head1 SYNOPSIS

    package MyPlugin::Manager;
    use Moo;
    with 'Starch::Plugin::ForManager';
    has foo => ( is=>'ro' );

    my $starch = Starch->new(
        plugins => ['MyPlugin::Manager'],
        foo => 'bar',
        ...,
    );
    print $starch->foo(); # bar

=head1 DESCRIPTION

This role provides no additional functionality to
manager plugins.  All it does is labels a plugin as a manager
plugin so that Starch knows which class type it applies to.

See L<Starch::Extending/PLUGINS> for more information.

=cut

use Moo::Role;
use namespace::clean;

1;
__END__

=head1 SUPPORT

See L<Starch/SUPPORT>.

=head1 AUTHORS

See L<Starch/AUTHORS>.

=head1 LICENSE

See L<Starch/LICENSE>.

=cut

