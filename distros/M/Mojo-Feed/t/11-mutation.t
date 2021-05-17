use Mojo::Feed;
use Test::More;
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
      is_deeply $hash_got, $hash_expected, $file
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
      is_deeply $hash_got, $changed_hash, $file
          or diag explain $hash_got;
  }
});

# This is the real test we want to write:
subtest('Mutating and serializing', sub {
  for my $file (sort keys %Hashes) {
      my $path = path( $FindBin::Bin, 'samples', $file );
      my $feed = Mojo::Feed->new(file => $path)
          or fail "parse feed ($file) returned undef", next;
# Now, mutate:
      $feed->title(q{Melody's Blog});
      $feed->items->[1]{'author'} = 'Melody';
      $feed->items->[0]{'published'} = 1085902866;
      my $feed2 = Mojo::Feed->new(body => "$feed");
      is $feed2->title, $feed->title, $file . ' - change feed title';
      is $feed2->items->[1]->author, $feed->items->[1]->author, $file . ' - change second item author';
      is $feed2->items->[0]->published, $feed->items->[0]->published, $file . ' - change first item published time';
  }
});

subtest('Filter Items', sub {
  my $path = path( $FindBin::Bin, 'samples', 'atom.xml' );
  my $feed = Mojo::Feed->new(file => $path);
  is $feed->items->size, 2, 'first feed has 2 items';
  # filter only items that are about sports:
  $feed->set_items($feed->items->grep(sub { $_->tags->first(qr/sport/i) }));
  my $feed2 = Mojo::Feed->new(body => "$feed");
  is $feed2->items->size, 1, 'new feed has only one item';
  is_deeply $feed2->items->map('tags')->map('to_array'), [ ['Sports'] ];
});

done_testing();
