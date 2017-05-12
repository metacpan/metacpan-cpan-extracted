package SF_form_secure;

delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};
use strict;
use warnings;
use Digest::SHA1 qw(sha1_hex);
use vars qw($VERSION %x_error $exp2);

$VERSION = '4.0';

# Error List
%x_error = (
       a => 'Referer and Query String match.',
       b => 'Referer is to long.',
       c => 'Referer is not from HTTP Host.',
       e => 'Referers do not Match.',
       f => 'Bad code format.',
       h => 'Code Has expired.',
       i => 'Encoding is bad.'
    );

our $code = '';
our $exp = '';
our $ip_ct = '';

# Main Function
sub x_secure {
my ($act, $link, $ref) = @_;
my $ip;

if (!$link) {
    $link = '';
}
# bound code to remote ip
$ip_ct eq 'ip'
 ? $ip = $ENV{REMOTE_ADDR}
 : $ip = '';

# ------------------------------------------------------------------------------
# return secure link (makes secure link)
# ------------------------------------------------------------------------------
 if ($act eq 1 && $link && $code) {
# Allow experation times 1 up to 99 minutes
  $exp2 = x_time_cal($exp);
  my $security_key = x_code_maker($code, $exp2, $link, $ip);
  $security_key = $link . ';Flex=' . $security_key . '|' . $exp2;
  return $security_key;
 }
 elsif ($act eq 2 && $code) {
# ------------------------------------------------------------------------------
# return 1 for good link or error text if bad.
# ------------------------------------------------------------------------------

# Get Referer and link Query String
my $REF = $ENV{'HTTP_REFERER'} || '';
my $QRY = $ENV{'QUERY_STRING'} || '';
my $ref2 = x_regex($REF);

if ($link =~ m!^(1|3)$!i || $ref) {
my $host_name = $ENV{'HTTP_HOST'} || '';
# Security issue 1
 if ($ref2 eq $QRY) {
  return $x_error{a};
 }
# Security issue 2
 if (length($REF) > 1024) {
  return $x_error{b};
 }
 # Security issue 3
 if ($REF !~ m!^(http|https)\:\/\/$host_name((.*?)+)$!i) {
  return $x_error{c};
 }
}

# get referer codes
$REF =~ s/\;Flex\=(.+?)\|(.+?)$//;
my $ref_code = $1;
my $ref_date = $2;

# Mach Referer with one given.
if ($ref && $ref ne $REF) {
 return $x_error{e};
}

# check the Referer code and/or date.
 if ($link == 1 || $link == 3) {

# Check input integrity
 my $ref_input = x_bad_input($ref_code, $ref_date);
     if($ref_input) {
     return $ref_input;
     }
# page expires
my $expir = x_code_expires($exp, $ref_date);
if ($expir) {
 return $expir;
}

 $REF = x_regex($REF);
  my $security_key = x_code_maker($code, $ref_date, $REF, $ip);
  if ($security_key ne $ref_code) {
   return $x_error{i};
  }
 }

# check the query code and/or date.
if ($link == 2 || $link == 3) {

# get query codes
$QRY =~ s/\;Flex\=(.*?)\|(.*?)$//;
my $qry_code = $1 || '';
my $qry_date = $2 || '';

# Check input integrity
 my $qry_input = x_bad_input($qry_code, $qry_date);
     if($qry_input) {
     return $qry_input;
     }
# page expires
my $expir = x_code_expires($exp, $qry_date);
if ($expir) {
 return $expir;
}
# check the QUERY_STRING code.
 my $security_key = x_code_maker($code, $qry_date, $QRY, $ip);
  if ($security_key ne $qry_code) {
   return $x_error{i};
  }
}
# looks good to x_secure
  return 1;
 }
 elsif ($act eq 3 && $code){
# ------------------------------------------------------------------------------
# Settup starting page
# ------------------------------------------------------------------------------
# Returns The Query String with Encoding to be used in a redirect.
 my $QRY = $ENV{'QUERY_STRING'};
 if ($QRY !~ m!;Flex=(.+?)$!i && $QRY eq $link) {
 $exp2 = x_time_cal($exp);
 my $security_key = x_code_maker($code, $exp2, $QRY, $ip);
 $security_key = $QRY . ';Flex=' . $security_key . '|' . $exp2;
 return $security_key;
  }
 }
 elsif ($act eq 4 && $code) {
# ------------------------------------------------------------------------------
# Action 4 Returns an encoding for action 5 to check
# ------------------------------------------------------------------------------
# x_secure(4, extra_code, '');

 $exp2 = x_time_cal($exp);
 if (!$link) {
     $link = $exp2;
 }
 my $security_key = x_code_maker($code, $exp2, $link, $ip);
 $security_key = $security_key . '|' . $exp2;
 return $security_key;
 }
 elsif ($act eq 5 && $code && $ref) {
# ------------------------------------------------------------------------------
# Action 5 Checks an encoding action 4 makes
# ------------------------------------------------------------------------------
# x_secure(5, extra_code, match_code);

# split the data
$ref =~ s/^(.*?)\|(.*?)$/$1/;
my $the_date = $2;
# Check input integrity
 my $the_input = x_bad_input($ref, $the_date);
     if($the_input) {
     return $the_input;
     }
# code expires
my $expir = x_code_expires($exp, $the_date);
if ($expir) {
 return $expir;
}
if (!$link) {
    $link = $the_date;
}

 my $security_key = x_code_maker($code, $the_date, $link, $ip);
 $security_key ne $ref
 ? return $x_error{i}
 : return 1; # looks good to x_secure
 }
 else {
 return $VERSION;
 }
}

sub x_code_expires {
my ($expdate,$datein) = @_;
my $date = time;
 if ($expdate && $expdate =~ m!^([0-9]+)$!i && length($expdate) <= 2 && $datein < $date) {
      return $x_error{h};
 }
}

sub x_regex {
my $regex = shift;
$regex =~ s/^(.*?)\?(.*?)$/$2/;
return $regex;
}

sub x_bad_input {
my ($codein, $datein) = @_;
     if($codein !~ m/^([0-9a-z]+)$/i) {
         return $x_error{f};
     }
     if (length($codein) < 40 || length($codein) > 40) {
         return $x_error{f};
     }
     if($datein !~ m!^([0-9]+)$!i) {
     return $x_error{f};
     }
     if (length($datein) < 10 || length($datein) > 10) {
         return $x_error{f};
     }
}

sub x_code_maker {
my ($codea, $datea, $QRYa, $ip_cta) = @_;
 $codea = $codea . $datea . $ip_cta;
 my $security_keya = sha1_hex($QRYa, $codea);
 return $security_keya;
}

sub x_time_cal {
my $limit = shift;
# Allow experation times 1 up to 99 minutes
if ($limit =~ m!^([0-9]+)$!i && length($limit) <= 2) {
  $limit = 60 * $limit;
  $limit = time + $limit;
  }
  else {
# No experation
  $limit = time;
  }
  return $limit;
}

1;
__END__

=head1 NAME

SF::SF_form_secure - Data integrity for forms, links, cookie or other things.

=head1 SYNOPSIS

 require SF::SF_form_secure;

 $SF_form_secure::code = 'Security_Key';
 $SF_form_secure::exp = '';
 $SF_form_secure::ip_ct = '';

 my $extra_code = 'Name:Password';
 my $stuff = SF_form_secure::x_secure(4, $extra_code, '');
 print $stuff;
 $stuff = SF_form_secure::x_secure(5, $extra_code, $stuff);
 print $stuff;

=head1 PREREQUISITES

This modules requires the following perl modules:

Digest::SHA1

=head1 ABSTRACT

Data integrity for forms, links, cookie or other things.

=head1 DESCRIPTION

 Must Provide a secret key.
 Controle the expiration function and minutes used 1 to 99, blank is off.
 Can use Remote IP in encoding.
 Many security level Combos 4 examples!
 Check referer encoding, and/or maching referer.
 Checks incoming QUERY_STRING encoding is correct.
 Returns the number 1 if Check is ok.
 Returns English Text if Check is Bad.
 Action 4 and 5 where made to use in Form's, URL's, cookies and anywhere else you like.

=head1 SUPPORT

 1) Must Provide the same secret key for all action types.
 2) Must Provide the same  time and/or ip setting for all actions.

=head1 EXAMPLE

 Load the module and set variables

 require SF::SF_form_secure;
 $SF_form_secure::code = 'Secuity_Key'; # Must Provide a secret key.
 $SF_form_secure::exp = '5'; # Minutes code will expire in 1 to 99, blank is off..
 $SF_form_secure::ip_ct = 'ip'; # use Remote IP in encoding, blank is off.
 -------------------------------------------------------------------------------

 Set page up for self encoding if encoding is missing
 3 - is the action type
 'op=testForm;module=Flex_Form' - to work, must provide a matching self link
 '' - not used for this action

 my $sec_self = SF_form_secure::x_secure('3', 'op=testForm;module=Flex_Forma', '');
 if ($sec_self) {
 print "Location: http://www.domain.com/index.cgi?$sec_self\n\n";
 }
 -------------------------------------------------------------------------------

 This makes encoded links for the next page
 1 - is the action type
 'op=testForm2;module=Flex_Form' - The link to encode
 '' - not used for this action

 my $secure_link = SF_form_secure::x_secure(1, 'op=testForm2;module=Flex_Forma', '');

 example of $secure_link = 'op=testForm;module=Flex_Forma;Flex=e690dec564cf52fcfcc967a9d5c079a7687f87d1|1161373021';
 1161373021 date is bound in encoding.

 -------------------------------------------------------------------------------

 Full Security - To get to this area the referer must match the one given, the incoming link and past referer encoding must be correct.
 2 - is the action type
 3 - 1 Check Referer encoding, 2 Check link encoding, 3 Check Both, Blank is off
 "http://www.domain.com/index.cgi?op=testForm;module=Flex_Form" - Match this Referer, Blank is off

 my $secure_check = SF_form_secure::x_secure(2, 3, "http://www.domain.com/index.cgi?op=testForm;module=Flex_Forma");
 if ($secure_check ne 1) {
 print $secure_check;
 }

 -------------------------------------------------------------------------------

 Medium Security 1 - To get to this area the referer must match the one given and incoming link encoding must be correct.
 2 - is the action type
 2 -  1 Check Referer encoding, 2 Check link encoding, 3 Check Both, Blank is off
 "http://www.domain.com/index.cgi?op=testForm;module=Flex_Form" - Match this Referer, Blank is off

 my $secure_check = SF_form_secure::x_secure(2, 2, "http://www.domain.com/index.cgi?op=testForm;module=Flex_Form");
 if ($secure_check ne 1) {
 print $secure_check;
 }

 -------------------------------------------------------------------------------

 Medium Security 2 - To get to this area the referer encoding and incoming link encoding must be correct.
 2 - is the action type
 3 -  1 Check Referer encoding, 2 Check link encoding, 3 Check Both, Blank is off
 '' - Match this Referer, Blank is off

 my $secure_check = SF_form_secure::x_secure(2, 3, '');
 if ($secure_check ne 1) {
 print $secure_check;
 }

 -------------------------------------------------------------------------------

 Low Security - To get to this area the incoming link encoding must be correct.
 2 - is the action type
 2 -  1 Check Referer encoding, 2 Check link encoding, 3 Check Both, Blank is off
 '' - Match this Referer, Blank is off

 my $secure_check = SF_form_secure::x_secure(2, 2, '');
 if ($secure_check ne 1) {
 print $secure_check;
 }

=head1 NOTES

To Provide a uniqe link others can not use
Format the provided key something like this
$key = $key . $Member_Name;
and/or
use the IP encoding
the new key format and/or ip encoding will need to be used for all actions

=head1 BUGS

some security levels can hirt the search engine ranking of the site.

=head1 TODO

None.

=head1 AUTHOR

By: Nicholas K. Alberto

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

Bug reports and comments to sflex@cpan.com.

=head1 SEE ALSO

Digest::SHA1, CGI::EncryptForm

=cut