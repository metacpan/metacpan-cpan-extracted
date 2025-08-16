package Net::Respite::AutoDoc;

use strict;
use warnings;
use CGI::Ex::App qw(:App);
use base qw(CGI::Ex::App);

use Throw qw(throw);
use Time::HiRes ();
use JSON ();
use Scalar::Util ();

1;
