use Mojo::Base -strict;
use Test::More;
use Mojo::Util 'trim';
use Mojo::Redis::Cursor;
use Mojo::Redis::Database;
use Mojo::Redis::PubSub;
use Mojo::UserAgent;

plan skip_all => 'CHECK_METHOD_COVERAGE=1' unless $ENV{CHECK_METHOD_COVERAGE};

my $methods = Mojo::UserAgent->new->get('https://redis.io/commands')->res->dom->find('[data-name]');
my @classes = qw(Mojo::Redis::Database Mojo::Redis::PubSub);
my (%doc, %skip);

$skip{method}{$_} = 1 for qw(auth hscan quit monitor migrate pubsub scan select shutdown sscan sync swapdb wait zscan);

$methods = $methods->map(sub {
  $doc{$_->{'data-name'}} = [
    trim($_->at('.summary')->text),
    join(', ', map { $_ = trim($_); /^\w/ ? "\$$_" : $_ } grep {/\w/} split /[\n\r]+/, $_->at('.args')->text)
  ];
  return $_->{'data-name'};
});

METHOD:
for my $command (sort { $a cmp $b } @$methods) {
  my $method = $command;
  $method =~ s!\s.*$!!g;

  if ($skip{method}{$method}) {
    note "Skipping $method";
    next METHOD;
  }

  $method = 'listen'   if $method =~ /subscribe$/;
  $method = 'unlisten' if $method =~ /unsubscribe$/;

REDIS_CLASS:
  for my $class (@classes) {
    next REDIS_CLASS unless $class->can($method) or $class->can("${method}_p");
    ok 1, "$class can $method ($command)";
    next METHOD;
  }
  ok 0, "not implemented: $method ($command)";
}

if (open my $SRC, '<', $INC{'Mojo/Redis/Database.pm'}) {
  my %has_doc;
  /^=head2 (\w+)/ and $has_doc{$1} = 1 for <$SRC>;

  for my $method (
    sort @Mojo::Redis::Database::BASIC_COMMANDS,
    @Mojo::Redis::Database::BLOCKING_COMMANDS,
    qw(exec discard multi watch unwatch)
    )
  {
    next if $has_doc{$method} or !$doc{$method};
    my ($summary, $args) = @{$doc{$method}};
    $summary .= '.' unless $summary =~ /\W$/;

    print <<"HERE";

=head2 $method

  \$res     = \$self->$method($args);
  \$self    = \$self->$method($args, sub { my (\$self, \$res) = \@_ });
  \$promise = \$self->${method}_p($args);

$summary

See L<https://redis.io/commands/$method> for more information.
HERE
  }
}

done_testing;
