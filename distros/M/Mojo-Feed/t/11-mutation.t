use Mojo::Feed;
use Test::More;
use Test::Deep;
use FindBin;
use Mojo::File qw(path);
use Storable qw(dclone);

my %Hashes = (
    'atom1-short.xml' => 'Atom 1.0',
    'rss20-three.xml' => 'RSS 2.0',
);
my $hash_expected = {
    author => 'Melody',
    description => 'This is a test weblog.',
    items => [
        {
            author => 'Melody',
            content => '<p>Hello!</p>',
            description => 'Hello again!...',
            guid => ignore(),
            id => 'http://localhost/weblog/2004/05/entry_three.html',
            link => 'http://localhost/weblog/2004/05/entry_three.html',
            published => '1085902785',
            tags => [ 'Travel', 'Sports' ],
            title => 'Entry Three',
        },
        {
            author => 'Melody',
            content => '<p>Hello!</p>',
            description => 'Hello!...',
            guid => ignore(),
            id => 'http://localhost/weblog/2004/05/entry_two.html',
            link => 'http://localhost/weblog/2004/05/entry_two.html',
            published => '1085902765',
            tags => [ 'Travel' ],
            title => 'Entry Two',
        },
        {
            author => '',
            content => '<p>This is a test.</p>

<p>Why don\'t you come down to our place for a coffee and a <strong>chat</strong>?</p>',
            description => 'This is a test. Why don\'t you come down to our place for a coffee and a chat?...',
            guid => ignore(),
            id => 'http://localhost/weblog/2004/05/test.html',
            link => 'http://localhost/weblog/2004/05/test.html',
            published => '1084086208',
            tags => [ 'Sports' ],
            title => 'Test',
        }
    ],
    link => 'http://localhost/weblog/',
    published => '1085902797',
    subtitle => '',
    title => 'First Weblog',
};

subtest('Hash Structure', sub {
  for my $file (sort keys %Hashes) {
      my $feed_type_expected = $Hashes{$file};
      my $path = path( $FindBin::Bin, 'samples', $file );
      my $feed = Mojo::Feed->new(file => $path)
          or fail "parse feed ($file) returned undef", next;
      is $feed->feed_type, $feed_type_expected;
      my $hash_got = $feed->to_hash;
      cmp_deeply $hash_got, $hash_expected, $file
          or diag explain $hash_got;
  }
}
);

# OK, now let's mutate stuff and see what we get:
subtest('Mutating', sub {
  my $changed_hash = dclone $hash_expected;
  # change it:
  $changed_hash->{'title'} = q{Melody's Blog};
  $changed_hash->{'items'}[1]{'author'} = 'Melody';
  $changed_hash->{'items'}[0]{'published'} = 1085902866;
  for my $file (sort keys %Hashes) {
      my $path = path( $FindBin::Bin, 'samples', $file );
      my $feed = Mojo::Feed->new(file => $path)
          or fail "parse feed ($file) returned undef", next;
# Now, mutate:
      $feed->title(q{Melody's Blog});
      $feed->items->[1]{'author'} = 'Melody';
      $feed->items->[0]{'published'} = 1085902866;
      my $hash_got = $feed->to_hash;
      cmp_deeply $hash_got, $changed_hash, $file
          or diag explain $hash_got;
  }

});


done_testing();
