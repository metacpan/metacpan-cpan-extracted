package Object;

use Moo;
use namespace::autoclean;
with 'MooX::Role::SEOTags';

has title => (
  is => 'ro',
  required => 1,
);

has url => (
  is => 'ro',
);

has type => (
  is => 'ro',
  required => 1,
);

has desc => (
  is => 'ro',
  required => 1,
);

has image => (
  is => 'ro',
);

sub og_title { shift->title }
sub og_type { shift->type }
sub og_description { shift->desc }
sub og_url { shift->url }
sub og_image { shift->image }

1;
