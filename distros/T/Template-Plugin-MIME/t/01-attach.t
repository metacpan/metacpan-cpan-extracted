#!perl -T

use Test::More;

use Template::Plugin::MIME;

my $plugin = Template::Plugin::MIME->load({});
$plugin->new($plugin->_context, { hostname => 'localhost' });

my $cid = $plugin->attach('fourdots.gif');
is($cid => 'b3376abfd1f123b891dcb342ac5a7c2cc1da2e30b545b063806bf9f40a01033a@localhost');

done_testing;
