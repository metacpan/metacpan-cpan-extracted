use Mojo::Base qw{ -strict };
use Mojolicious::Lite;

use File::Basename;

my $dir = dirname(__FILE__);
plugin 'Directory', root => $dir, dir_page => <<'EOF';
entries: <%= scalar @$files %>
EOF

use Test::More tests => 3;
use Test::Mojo;

my $t = Test::Mojo->new();
$t->get_ok('/')->status_is(200);

use File::Basename;
subtest 'entries' => sub {
    my $dh = DirHandle->new($dir);
    my $entries;
    while ( defined( my $ent = $dh->read ) ) {
        next if -d $ent or $ent eq '.' or $ent eq '..';
        $entries++;
    }
    $t->get_ok('/')->status_is(200)->content_like(qr/entries: $entries/);
}
