use t::Helper;

plan skip_all => 'TEST_ONLINE="zone|email|key" Need to be set' unless $ENV{TEST_ONLINE};

my @args = split '\|', $ENV{TEST_ONLINE};
my $cf = Mojo::Cloudflare->new(zone => $args[0], email => $args[1], key => $args[2], api_url => '/api_json', _ua => $t->ua);
my($records, $record);

{
  $records = $cf->records;

  isa_ok($records, 'Mojo::Cloudflare::RecordSet');

  is $records->_cf, $cf, 'records _cf points back';
  ok defined $records->get('/count'), 'records: /count';
  ok $records->get('/count'), 'records: /count';
  ok $records->contains('/has_more'), 'records: /has_more';
  ok $records->get('/objs'), 'records: /objs';

  $record = $records->single(sub { $_->name =~ /^direct\./ });

  ok $record, 'found direct.x record';
  is $record->_cf, $cf, 'record _cf points back';
  isa_ok($record, 'Mojo::Cloudflare::Record');
  ok $record, 'Found direct.foo.com record';
  ok $record->name, 'record: name';
}

done_testing;
