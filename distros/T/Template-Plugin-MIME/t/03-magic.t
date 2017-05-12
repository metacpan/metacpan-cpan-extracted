#!perl -T

use Test::More;

use Template::Plugin::MIME;

my $plugin = Template::Plugin::MIME->load({});
$plugin->new($plugin->_context);

unless (defined $plugin->{magic}) {
    plan skip_all => 'File::LibMagic not available';
}

my $cid = $plugin->attach('fourdots.gif');

my $entity = $plugin->_context->{ref($plugin)}->{attachments}->{index}->{cids}->{$cid};

if ($entity->mime_type eq 'application/octet-stream') {
    diag 'WARNING: magic mime-type detection failed and falled back to default. this may not be an error, since this module depend on libmagic and your system-wide mime.magic-file.';
    pass;
} else {
    is($entity->mime_type, 'image/gif');
}

done_testing;
