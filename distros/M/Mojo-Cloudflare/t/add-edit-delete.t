use t::Helper;

plan skip_all => 'TEST_ONLINE="zone|email|key" Need to be set' unless $ENV{TEST_ONLINE};

my @args = split '\|', $ENV{TEST_ONLINE};
my $cf
  = Mojo::Cloudflare->new(zone => $args[0], email => $args[1], key => $args[2], api_url => '/api_json', _ua => $t->ua);
my $id = $ENV{TEST_ID};
my $record;

my %record = (type => 'CNAME', name => 'mojo-edit-delete', content => 'home.thorsen.pm', ttl => 1,);

if (!$id) {
  $record = $cf->record(\%record)->save;

  ok $id = $record->id, 'add_record: /obj/rec_id';
  is $record->name, "mojo-edit-delete.$args[0]", 'add_record: /obj/name';
  is $record->_cf->zone, $args[0], 'add_record: /obj/zone_name';

  $id or BAIL_OUT "Could not add record!";
  diag $id;
}

{
  is $record->content('thorsen.pm')->save, $record, 'save()';
  $record = $cf->records->single(sub { $_->content eq 'thorsen.pm' });
  is $record->content, 'thorsen.pm', 'content updated';
  is $record->get('/rec_id'),  $record->id,      'edit_record /rec_id';
  is $record->get('/content'), $record->content, 'edit_record /content';
  is $record->delete, $record, 'delete()';
}

done_testing;
