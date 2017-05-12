#!/usr/bin/perl

use strict;
use warnings;
use vars qw(%user_action $query);
use CGI qw(:standard);
$query = new CGI;

my $op   = $query->param('op');
my $id   = $query->param('id');

# Load module
require SF::SF_form_secure;

# Set variables
 $SF_form_secure::code = 'Secuity_Key'; # Must Provide a secret key.
 $SF_form_secure::exp = '1'; # Minutes code will expire in 1 to 99, blank is off..
 $SF_form_secure::ip_ct = 'ip'; # use Remote IP in encoding, blank is off.

# extra code for action 4 and 5
 my $extra_code = 'Name:Password';

 # Define possible user actions.
%user_action = (
        testForm  => \&testForm,
        testForm2 => \&testForm2
    );

# Depending on user action, decide what to do.
if ($user_action{$op}) {
$user_action{$op}->();
}
else {
testForm();
}

sub testForm {


# Set this page up for self encoding if encoding is missing
# '3' - is the action type
# 'op=testForm' - to work, must provide a matching self link
# '' - not used for this action
my $sec_self = SF_form_secure::x_secure('3','op=testForm','');
 if ($sec_self) {
# print "Location: http://www.domain.com/index.cgi?$sec_self\n\n";
 print $query->redirect(-location => "http://www.domain.com/first.cgi?$sec_self");
 }
# Low Security - To get to this area the incoming link encoding must be correct.
# 2 - is the action type
# '' - 1 Check Referer encoding, 2 Check link encoding, 3 Check Both, Blank is off
# '' - Match this Referer, Blank is off
my $secure_check = SF_form_secure::x_secure(2, 2, '');
if ($secure_check ne 1) {
print "Content-type: text/html\n\n";
print "<html><h1>$secure_check</h1></html>\n";
exit;
}

# make some content
my $idl = SF_form_secure::x_secure(4, $extra_code, '');

$idl = 'op=testForm2;id=' . $idl;
# This makes encoded links for the next page
# Link encoding made expire in 10 min.
# 1 - is the action type
# 'op=testForm2;id=...' - The link to encode
# '' - not used for this action
my $secure_link = SF_form_secure::x_secure(1, $idl, '');
# example of $secure_link = 'op=testForm;module=Flex_Forma;Flex=e690dec564cf52fcfcc967a9d5c079a7687f87d1|1161373021';
# 1161373021 date is bound in encoding.


print "Content-type: text/html\n\n";
print "<html><h1>";
print "OK<br><a href=\"http://www.domain.com/first.cgi?$secure_link\">Next_page</a>";
print "</h1></html>\n";
exit;

}
# This is the page to secure
sub testForm2 {
#use CGI::SF_form_secure;
# Full Security - To get to this area the referer must match the one given, the incoming link and past referer encoding must be correct.
# 2 - is the action type
# '3' - 1 Check Referer encoding, 2 Check link encoding, 3 Check Both, Blank is off
# "http://www.domain.com/first.cgi" - Match this Referer, Blank is off
my $secure_check = SF_form_secure::x_secure(2,'3',"http://www.domain.com/first.cgi?op=testForm");
if ($secure_check ne 1) {
print "Content-type: text/html\n\n";
print "<html><h1>$secure_check</h1></html>\n";
exit;
}
# check some content
my $idl = SF_form_secure::x_secure(5, $extra_code, $id);
if ($idl ne 1) {
print "Content-type: text/html\n\n";
print "<html><h1>$idl</h1></html>\n";
exit;
}

# make some content
$idl = SF_form_secure::x_secure(4, $extra_code, '');

$idl = 'op=testForm;id=' . $idl;

# This makes encoded links for the next page
# 1 - is the action type
# 'op=testForm;id=...' - Part of the link to encode
# '' - not used for this action
my $secure_link = SF_form_secure::x_secure(1,$idl,'');
# example of $secure_link = 'op=testForm;module=Flex_Form;Flex=7b51f039a5e9b5b50dc42ef9dffca113fee8e7f2|1161373022';
# 1161373022 date is bound in encoding.


print "Content-type: text/html\n\n";
print "<html><h1>OK<br><a href=\"http://www.The_domain.com/first.cgi?$secure_link\">Form</a></h1></html>\n";
exit;
}
1;