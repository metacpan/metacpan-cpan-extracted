use strict;
use warnings;
use Test::More tests => 7;

{
    package TestSubClass;
    use strict;
    use warnings;
    use base qw(Object::Pluggable);
    use Test::More;
    use Object::Pluggable::Constants qw(:ALL);

    sub spawn {
        my $package = shift;
        my $self = bless { }, $package;
        $self->_pluggable_init(
            types => ['SERVER'],
        );
        return $self;
    }

    sub shutdown {
        my ($self) = @_;
        $self->_pluggable_destroy();
        return;
    }

    sub send_event {
        my ($self, $event, @args) = @_;
        $self->_pluggable_process('SERVER', $event, \@args);
        return;
    }

    sub run {
        my ($self) = @_;
        $self->send_event('test');
        $self->send_event('noret');
        return;
    }

    sub _pluggable_event {
        my ($self, @args) = @_;
        $self->send_event(@args);
        return;
    }

    sub SERVER_test {
        pass(__PACKAGE__ . ' test event');
        return PLUGIN_EAT_NONE;
    }
    sub SERVER_noret {
        pass(__PACKAGE__ . ' noret event');
        return;
    }
}

{
    package TestPlugin;
    use strict;
    use warnings;
    use Test::More;
    use Object::Pluggable::Constants qw(:ALL);

    sub new {
        my $package = shift;
        return bless { @_ }, $package;
    }

    sub plugin_register {
        my ($self,$subclass) = splice @_, 0, 2;
        pass(__PACKAGE__ . " Plugin Register");
        $subclass->plugin_register( $self, 'SERVER', qw(all) );
        return 1;
    }

    sub plugin_unregister {
        pass(__PACKAGE__ . " Plugin Unregister");
        return 1;
    }

    sub SERVER_test {
        my ($self,$irc) = splice @_, 0, 2;
        pass(__PACKAGE__ . ' test event');
        return PLUGIN_EAT_NONE;
    }

    sub SERVER_noret {
        my ($self,$irc) = splice @_, 0, 2;
        pass(__PACKAGE__ . ' noret event');
        return;
    }
}

use strict;
use warnings;

my $pluggable = TestSubClass->spawn();
isa_ok($pluggable, 'Object::Pluggable' );
$pluggable->plugin_add( 'TestPlugin', TestPlugin->new() );
$pluggable->run();
$pluggable->shutdown();

