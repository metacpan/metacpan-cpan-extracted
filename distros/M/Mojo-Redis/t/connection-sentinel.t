use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;

my $port   = Mojo::IOLoop::Server->generate_port;
my $conn_n = 0;
my @messages;

Mojo::IOLoop->server(
  {port => $port},
  sub {
    my ($loop, $stream) = @_;
    my $protocol = Protocol::Redis->new(api => 1);
    my @res = ({type => '$', data => 'OK'});

    push @res,
      $conn_n == 0
      ? {type => '$', data => 'IDONTKNOW'}
      : {type => '*', data => [{type => '$', data => 'localhost'}, {type => '$', data => $port}]};

    my $cid = ++$conn_n;
    $protocol->on_message(sub {
      push @messages, pop;
      $messages[-1]{c} = $cid;
      $stream->write($protocol->encode(shift @res)) if @res;
      Mojo::IOLoop->stop if $messages[-1]{data}[0]{data} eq 'SELECT';
    });

    $stream->on(read => sub { $protocol->parse(pop) });
  }
);

my $redis = Mojo::Redis->new("redis://whatever:s3cret\@mymaster/12?sentinel=localhost:$port&sentinel=localhost:$port");
my $db    = $redis->db;
$db->connection->_connect;
Mojo::IOLoop->start;

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
    {c => 3, data => [{data => 'AUTH',   type => '$'}, {data => 's3cret', type => '$'}], type => '*'},
    {c => 3, data => [{data => 'SELECT', type => '$'}, {data => '12',     type => '$'}], type => '*'},
  ],
  'discovery + connect'
);

done_testing;
