use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;

my $port   = Mojo::IOLoop::Server->generate_port;
my $redis  = Mojo::Redis->new("redis://whatever:s3cret\@mymaster/12?sentinel=localhost:$port&sentinel=localhost:$port");
my $conn_n = 0;
my @messages;

Mojo::IOLoop->server(
  {port => $port},
  sub {
    my ($loop, $stream) = @_;
    my $protocol = $redis->protocol_class->new(api => 1);
    my @res      = ({type => '$', data => 'OK'});

    push @res,
      $conn_n == 0
      ? {type => '$', data => 'IDONTKNOW'}
      : {type => '*', data => [{type => '$', data => 'localhost'}, {type => '$', data => $port}]};

    push @res, {type => '$', data => 42};

    my $cid = ++$conn_n;
    $protocol->on_message(sub {
      push @messages, pop;
      $messages[-1]{c} = $cid;
      $stream->write($protocol->encode(shift @res)) if @res;
    });

    $stream->on(read => sub { $protocol->parse(pop) });
  }
);

my $foo;
$redis->db->get_p('foo')->then(sub { $foo = shift })->wait;
is $foo, 42, 'get foo';

my @get_master_addr_by_name = (
  {data => 'SENTINEL',                type => '$'},
  {data => 'get-master-addr-by-name', type => '$'},
  {data => 'mymaster',                type => '$'},
);

is_deeply(
  \@messages,
  [
    {c => 1, data => [{data => 'AUTH', type => '$'}, {data => 's3cret', type => '$'}], type => '*'},
    {c => 1, data => \@get_master_addr_by_name,                                        type => '*'},
    {c => 2, data => [{data => 'AUTH', type => '$'}, {data => 's3cret', type => '$'}], type => '*'},
    {c => 2, data => \@get_master_addr_by_name,                                        type => '*'},
    {c => 3, data => [{data => 'AUTH', type => '$'}, {data => 's3cret', type => '$'}], type => '*'},
    {c => 3, data => [{data => 'SELECT', type => '$'}, {data => '12', type => '$'}],   type => '*'},
    {c => 3, data => [{data => 'GET', type => '$'}, {data => 'foo', type => '$'}],     type => '*'},
  ],
  'discovery + connect + command'
) or diag explain \@messages;

done_testing;
