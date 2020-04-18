use Data::Dumper;
use RedisScript;
use Redis;

my $rs_o = RedisScript->new( redis => Redis->new(),
                             code => <<EOB,
      local key1 = KEYS[1]
      local res = redis.call( 'setex', key1, ARGV[1], ARGV[2] )
      return 1
EOB
                           );
my @res = $rs_o->runit( keys => [ qw/ a / ], args => [ 1, 300 ] );
print Dumper \@res;
