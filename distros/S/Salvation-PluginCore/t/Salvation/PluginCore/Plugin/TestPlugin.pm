package Salvation::PluginCore::Plugin::TestPlugin;

use strict;
use warnings;

use base 'Salvation::PluginCore::Plugin';

sub deep_plugin {

    return shift -> load_plugin( infix => 'Deep', base_name => 'deep_plugin' );
}

1;

__END__
