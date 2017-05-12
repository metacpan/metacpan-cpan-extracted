package MojoliciousConfigTest;
use Mojo::Base 'Mojolicious'; use _inject_plugin;

sub startup { shift->plugin('Config') }

1;
