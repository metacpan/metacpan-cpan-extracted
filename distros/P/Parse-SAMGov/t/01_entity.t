use Test::More;

use_ok('Parse::SAMGov::Entity');

my $e = new_ok('Parse::SAMGov::Entity');
can_ok(
    $e, qw( DUNS DUNSplus4 CAGE DODAAC
      regn_purpose regn_date expiry_date
      lastupdate_date activation_date
      name dba_name company_division division_no
      physical_address start_date fiscalyear_date
      url entity_structure incorporation_state
      incorporation_country biztype
      NAICS SBA PSC creditcard
      correspondence_type mailing_address
      delinquent_fed_debt exclusion_status
      is_private disaster_response
      POC_gov POC_gov_alt POC_pastperf
      POC_pastperf_alt POC_elec POC_elec_alt
      )
);
isa_ok($e->regn_date('20160101'), 'DateTime');
is($e->regn_date->ymd('/'), '2016/01/01', 'registration date matches');
isa_ok($e->activation_date('20160101'), 'DateTime');
is($e->activation_date->ymd('/'), '2016/01/01', 'activation date matches');
isa_ok($e->expiry_date('20180101'), 'DateTime');
is($e->expiry_date->ymd('/'), '2018/01/01', 'expiry date matches');
isa_ok($e->lastupdate_date('20160101'), 'DateTime');
is($e->lastupdate_date->ymd('/'), '2016/01/01', 'last update date matches');

$e->physical_address(
                     Parse::SAMGov::Entity::Address->new(
                                                  address => '123 Baker Street',
                                                  city    => 'Boringville',
                                                  state   => 'AB',
                                                  country => 'USA',
                                                  zip     => '20195'
                     )
                    );
isa_ok($e->physical_address, 'Parse::SAMGov::Entity::Address');
can_ok($e->physical_address, qw(address city state zip country));
$e->mailing_address(
                    Parse::SAMGov::Entity::Address->new(
                                                  address => '123 Baker Street',
                                                  city    => 'Boringville',
                                                  state   => 'AB',
                                                  country => 'USA',
                                                  zip     => '20195'
                    )
                   );
isa_ok($e->mailing_address, 'Parse::SAMGov::Entity::Address');
can_ok($e->mailing_address, qw(address city state zip country));
note $e->mailing_address;

my $poc = $e->POC_gov;
isa_ok($poc, 'Parse::SAMGov::Entity::PointOfContact');
isa_ok($poc, 'Parse::SAMGov::Entity::Address');
can_ok(
    $poc, qw(address city state zip country phone phone_ext phone_nonUS
      fax email first last middle title name));
isa_ok($e->POC_gov_alt,      'Parse::SAMGov::Entity::PointOfContact');
isa_ok($e->POC_pastperf,     'Parse::SAMGov::Entity::PointOfContact');
isa_ok($e->POC_pastperf_alt, 'Parse::SAMGov::Entity::PointOfContact');
isa_ok($e->POC_elec,         'Parse::SAMGov::Entity::PointOfContact');
isa_ok($e->POC_elec_alt,     'Parse::SAMGov::Entity::PointOfContact');

isa_ok($e->start_date('20160101'), 'DateTime');
is($e->start_date->ymd('/'), '2016/01/01', 'start date matches');
isa_ok($e->fiscalyear_date('20161231'), 'DateTime');
is($e->fiscalyear_date->ymd('/'), '2016/12/31', 'fiscal year date matches');
isa_ok($e->url('http://sam.gov'), 'URI');
is($e->DUNSplus4,             '0000',  'DUNS+4 default is 0000');
is(ref $e->biztype,           'ARRAY', 'biztype is an array');
is(ref $e->NAICS,             'HASH',  'NAICS is an hashref');
is(ref $e->PSC,               'ARRAY', 'PSC is an array');
is(ref $e->SBA,               'HASH',  'SBA is an hashref');
is(ref $e->disaster_response, 'HASH',  'disaster_response is an hashref');

done_testing();
__END__
### COPYRIGHT: Selective Intellect LLC.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
