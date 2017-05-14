# This is a centralized configuration file for Net::ICal
# applications. Right now it's configured by the
# Net::ICal::VTIMEZONES install process. 
# 
$Net::ICal::Config = {
  'zoneinfo_location' => q[$$ZONEINFO_LOCATION$$],
};
1;
__END__
