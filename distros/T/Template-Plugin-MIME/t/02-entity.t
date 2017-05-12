#!perl -T

use Test::More;

use Template::Plugin::MIME;

my $plugin = Template::Plugin::MIME->load({});
$plugin->new($plugin->_context, { hostname => 'localhost' });

my $cid = $plugin->attach('fourdots.gif');

my $entity = $plugin->_context->{ref($plugin)}->{attachments}->{index}->{cids}->{$cid};

isa_ok($entity, 'MIME::Entity');
isa_ok($entity->bodyhandle, 'MIME::Body::File');
is($entity->bodyhandle->path, 'fourdots.gif');

done_testing;
