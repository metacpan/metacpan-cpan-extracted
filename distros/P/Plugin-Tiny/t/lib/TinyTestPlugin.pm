package TinyTestPlugin;
use strict;
use warnings;
use Moo;
use MooX::Types::MooseLike::Base 'InstanceOf';
#use File::Spec;
#use lib File::Spec->catfile('t', 'lib');
use Moo;
has 'plugin_system' => (is => 'ro', isa => InstanceOf['Plugin::Tiny'], required => 1);
with 'TestRolePlugin';

#acts as bundle, i.e. loads other plugins
sub register_another_plugin {
    $_[0]->plugin_system->register(
        phase  => 'bar',
        role   => undef, #not 100% why this is needed...
        plugin => 'TinySubPlug'
    );
}

sub do_something {
    'doing something';
}

sub some_method {
    print "hello world\n";

}

1;
