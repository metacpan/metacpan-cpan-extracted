#!/usr/local/bin/perl

use REDIRECT_MFORM;

my($base_url) = 'http://webserver_url/cgi-bin/multi_part_form.cgi';


# Options are:
#
# nph => (0 or undef) or 1
# username => 'username'
# password => 'password'
# user_agent => 'user_agent' (i.e. 'Mozilla')
# timeout => timeout in seconds (default is 180)
#
print REDIRECT_MFORM::redirect($base_url, %options);
