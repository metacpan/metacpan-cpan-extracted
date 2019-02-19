package MooX::PluginKit::Plugin;

our $VERSION = '0.05';

=head1 NAME

MooX::PluginKit::Plugin - Setup a role as a PluginKit plugin.

=head1 SYNOPSIS

=head2 DESCRIPTION

This module, when C<use>d, exports several candy functions (see L</CANDY>)
into the caller.

Some higher-level documentation about how to consume plugins can
be found at L<MooX::PluginKit/CREATING PLUGINS>.

=cut

use MooX::PluginKit::Core;
use Carp qw();
use Exporter qw();

use strictures 2;
use namespace::clean;

our @EXPORT = qw(
    plugin_applies_to
    plugin_includes
);

sub import {
    {
        my $caller = (caller())[0];
        init_plugin( $caller );
    }

    goto &Exporter::import;
}

=head1 CANDY

=head2 plugin_applies_to

    # Only apply to classes which isa() the supplied class, or
    # DOES() the supplied role.
    plugin_applies_to 'Some::Class';
    plugin_applies_to 'Some::Role';
    
    # Only apply to classes which match the regex.
    plugin_applies_to qr/^MyApp::Foo::/;
    
    # Only apply to classes which implement these methods.
    plugin_applies_to ['foo', 'bar'];
    
    # Only apply to classes which pass this custom check.
    plugin_applies_to sub{ $_[0]->does('Some::Role') }

Declares which types of classes this plugin may be applied to.

=cut

sub plugin_applies_to {
    my ($plugin) = caller();
    local $Carp::Internal{ (__PACKAGE__) } = 1;
    set_plugin_applies_to( $plugin, @_ );
    return;
}

=head2 plugin_includes

    plugin_includes 'Some::Plugin', '::Relative::Plugin';

Registers a plugin for inclusion with this plugin.

=cut

sub plugin_includes {
    my ($plugin) = caller();
    local $Carp::Internal{ (__PACKAGE__) } = 1;
    set_plugin_includes( $plugin, @_ );
    return;
}

1;
__END__

=head1 AUTHORS AND LICENSE

See L<MooX::PluginKit/AUTHOR> and L<MooX::PluginKit/LICENSE>.

