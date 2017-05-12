#!/usr/local/bin/perl
use CGI;
use RCGI;

my($base_url) = 'http://www.ibc.wustl.edu/';
my($cgi_form, %options) = RCGI::Process_Parameters( new CGI);

#$options{'nph'} = 1;
# Options are:
#
# method => (0 or undef) or 1  are GET or POST
# nph => (0 or undef) or 1
# username => 'username'
# password => 'password'
# user_agent => 'user_agent' (i.e. 'Mozilla')
# timeout => timeout in seconds (default is 180)
#
print RCGI::run_cgi_command($base_url, $cgi_form, %options);

