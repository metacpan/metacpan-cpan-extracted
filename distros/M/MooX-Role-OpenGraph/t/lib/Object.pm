package Object;

use Moo;
with 'MooX::Role::OpenGraph';

has title => (
  is => 'ro',
);

has url => (
  is => 'ro',
);

has type => (
  is => 'ro',
);

has desc => (
  is => 'ro',
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
