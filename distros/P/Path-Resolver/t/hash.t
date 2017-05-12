use strict;
use warnings;

use Test::More tests => 9;

use Path::Resolver;
use Path::Resolver::Resolver::Hash;

my $hash = {
  README => "This is a readme file.\n",

  t => {
    '00-load.t'   => "Load tests are weak.",
    '99-unload.t' => "This doesn't even make sense.",
  },
};

my $prh = Path::Resolver::Resolver::Hash->new({ hash => $hash });

{
  my $content = $prh->content_for('README');
  is($$content, $hash->{README}, 'README');
}

{
  my $content = $prh->content_for('/README');
  is($$content, $hash->{README}, '/README');
}

{
  my $content = $prh->content_for('t/00-load.t');
  is($$content, $hash->{t}{'00-load.t'}, 't/00-load.t');
}

for my $path (qw(
  foo
  t/foo
  /foo
  /t/foo
)) {
  is(
    $prh->content_for($path),
    undef,
    "no content for $path"
  );
}

for my $path (qw(
  t
  t/00-load.t/README
)) {
  my $content;
  my $ok  = eval { $content = $prh->content_for($path); 1 };
  my $err = $@;

  is(
    $content,
    undef,
    "no content for $path"
  );
#  my ($line) = split /\n/, $err;
#  $line =~ s/ at lib.+//;
#
#  ok(! $ok, "error: $path - $line");
}
