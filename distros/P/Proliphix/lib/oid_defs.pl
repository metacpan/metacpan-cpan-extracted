our $oid2name = {
  '4.1.1' => 'thermHvacMode',
  '4.1.2' => 'thermHvacState',
  '4.1.3' => 'thermFanMode',
  '4.1.4' => 'thermFanState',
  '4.1.5' => 'thermSetbackHeat',
  '4.1.6' => 'thermSetbackCool',
  '4.2.22' => 'thermConfigHumidityCool',
  '4.1.9' => 'thermSetbackStatus',
  '4.1.10' => 'thermCurrentPeriod',
  '4.1.12' => 'thermActivePeriod',
  '4.1.11' => 'thermCurrentClass',
};
our $name2oid;
foreach (keys %$oid2name) { $name2oid->{$oid2name->{$_}} = $_; }

=head2 why this file?

  This is hackish at best. With a decent parsable list from Proliphix 
I wouldn't have done it this way, but I'm certainly not going to go
thru the API PDF and fat finger everything in. I'll be happy to take
updates to this if anyone has them

=cut
