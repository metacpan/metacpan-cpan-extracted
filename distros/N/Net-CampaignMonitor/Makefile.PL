use inc::Module::Install::DSL 0.92;

author		jeffery@astraaustralis.com.au
all_from  lib/Net/CampaignMonitor.pm
requires  MIME::Base64     3.13
requires  REST::Client     171
requires  XML::Simple      2.18
requires  JSON             2.27
requires  LWP::UserAgent   5.835
requires  Carp             1.11
requires  Params::Util     1.01
requires  Test::Exception  0.32

repository 'https://github.com/campaignmonitor/createsend-perl.git';
