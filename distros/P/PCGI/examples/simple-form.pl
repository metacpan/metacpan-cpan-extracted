#!/usr/bin/perl -w

use strict;
use PCGI qw(:all);

my $q = PCGI->new();

$q->sendheader;

print qq{<HTML>\n};
print qq{<BODY>\n};
print qq{<FORM action="">\n};
print qq{What is your name? <INPUT type=text name=name>\n};
print qq{<INPUT type=submit value="Sumbit">};
print qq{</FORM>};
print qq{<HR>\n};

my $name = $q->GET('name');
if( defined $name ) {
  print qq{Your name is $name<br>\n};
}

print qq{</BODY>\n};
print qq{</HTML>\n};
