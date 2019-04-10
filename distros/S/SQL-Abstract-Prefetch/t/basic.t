use Mojo::Base '-strict';
use Test::More;
use SQL::Abstract::Prefetch;
use SQL::Abstract::Pg;
use Mojo::File qw( path );
use FindBin qw( $Bin );
use DBI ();

my %items;
my $dbh = DBI->connect( "dbi:SQLite:dbname=:memory:", '', '' );
my $abstract = SQL::Abstract::Pg->new( name_sep => '.', quote_char => '"' );
my $ddl = path( $Bin, 'schema', 'sqlite.sql' )->slurp;
$dbh->do( $_ ) for grep /\S/, split /;/, $ddl;
push @{ $items{user} }, insert_item( $dbh, $abstract, user => %$_ ) for (
  {
    username => 'one',
    email => 'one@example.com',
    access => 'user',
    password => 'p1',
    age => 7,
  },
  {
    username => 'two',
    email => 'two@example.com',
    access => 'moderator',
    password => 'p2',
    age => 7,
  },
);
push @{ $items{blog} }, insert_item( $dbh, $abstract, blog => %$_ ) for (
  {
    title => 'T 1',
    markdown => '# Super',
    html => '<h1>Super</h1>',
    slug => 't-1',
    user_id => $items{user}[0]{id},
  },
  {
    title => 'T 2',
    markdown => '# Smashing',
    html => '<h1>Smashing</h1>',
    slug => 't-2',
    user_id => $items{user}[0]{id},
  },
);
push @{ $items{comment} }, insert_item( $dbh, $abstract, comment => %$_ ) for (
  {
    markdown => '# So good',
    html => '<h1>So good</h1>',
    user_id => $items{user}[1]{id},
    blog_id => $items{blog}[0]{id},
  },
  {
    markdown => '# So great',
    html => '<h1>So great</h1>',
    user_id => $items{user}[0]{id},
    blog_id => $items{blog}[1]{id},
  },
  {
    markdown => '# So amazing',
    html => '<h1>So amazing</h1>',
    user_id => $items{user}[1]{id},
    blog_id => $items{blog}[1]{id},
  },
);
my $prefetch = SQL::Abstract::Prefetch->new(
  abstract => $abstract,
  dbhgetter => sub { $dbh },
  dbcatalog => undef, # for SQLite
  dbschema => undef,
  filter_table => sub { return $_[0] !~ /^sqlite_/ },
);

# assume all ID called 'id', always create
sub insert_item {
  my ( $dbh, $abstract, $coll, %item ) = @_;
  my ( $sql, @bind ) = $abstract->insert( $coll => \%item );
  my $res = $dbh->do( $sql, undef, @bind );
  my $inserted_id = $dbh->last_insert_id( undef, undef, $coll, undef );
  $item{id} = $inserted_id;
  return \%item;
}

my %t2q = (
  user => {
    table => 'user',
    fields => [ 'access', 'age', 'email', 'id', 'password', 'username' ],
    keys => [ 'id' ],
  },
  comment => {
    table => 'comment',
    fields => [ 'blog_id', 'html', 'id', 'markdown', 'user_id' ],
    keys => [ 'id' ],
  },
  blog => {
    table => 'blog',
    fields => [
      'html',
      'id',
      'is_published',
      'markdown',
      'slug',
      'title',
      'user_id',
    ],
    keys => [ 'id' ],
  },
);
my $queryspec = {
  %{ $t2q{blog} },
  multi => { comments => $t2q{comment} },
  single => { user => $t2q{user} },
};

sub fetch {
  my ($dbh, $prefetch, $queryspec, $where, $opt) = @_;
  my ( $extractspec ) = $prefetch->extractspec_from_queryspec( $queryspec );
  my ( $sql, @bind ) = $prefetch->select_from_queryspec(
    $queryspec,
    $where,
    $opt,
  );
  my $sth = $dbh->prepare( $sql );
  $sth->execute( @bind );
  $prefetch->extract_from_query( $extractspec, $sth );
}

subtest 'get nojoin' => sub {
  my ( $got ) = fetch(
    $dbh, $prefetch, $t2q{blog}, { id => $items{blog}[0]{id} },
  );
#path('tf')->spurt(explain $got);
  is_deeply $got, {
    %{ $items{blog}[0] },
    is_published => 0, # default filled in
  } or diag explain $got;
};

subtest 'get one' => sub {
  my ( $got ) = fetch(
    $dbh, $prefetch, $queryspec, { id => $items{blog}[0]{id} },
  );
  is_deeply $got, {
    %{ $items{blog}[0] },
    is_published => 0, # default filled in
    comments => [ $items{comment}[0] ],
    user => $items{user}[0],
  } or diag explain $got;
};

subtest 'list limit 1 offset 1' => sub {
  my ( $got ) = fetch(
    $dbh, $prefetch, $queryspec, undef, { limit => 1, offset => 1 },
  );
  is_deeply $got, {
    %{ $items{blog}[1] },
    is_published => 0, # default filled in
    comments => [ @{ $items{comment} }[1..2] ],
    user => $items{user}[0],
  } or diag explain $got;
};

subtest 'order by' => sub {
  my ( $got ) = fetch(
    $dbh, $prefetch, $t2q{blog}, undef, { order_by => 'title' },
  );
  is_deeply $got, {
    %{ $items{blog}[0] },
    is_published => 0, # default filled in
  } or diag explain $got;
};

subtest 'order by hash' => sub {
  my ( $got ) = fetch(
    $dbh, $prefetch, $t2q{blog}, undef, { order_by => { -asc => 'title' } },
  );
  is_deeply $got, {
    %{ $items{blog}[0] },
    is_published => 0, # default filled in
  } or diag explain $got;
};

done_testing;
