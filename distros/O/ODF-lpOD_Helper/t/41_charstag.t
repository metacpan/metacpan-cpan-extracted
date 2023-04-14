#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, Data::Dumper::Interp, etc.
use t_TestCommon ':silent',
                 qw/bug ok_with_lineno like_with_lineno
                    rawstr showstr showcontrols displaystr 
                    show_white show_empty_string
                    fmt_codestring 
                    timed_run
                    checkeq_literal check _check_end
                  /;

use ODF::lpOD;
use ODF::lpOD_Helper qw/:DEFAULT :chars/;

my $skel_path = "$Bin/../tlib/Skel.odt";
my $doc = odf_get_document($skel_path);
my $body = $doc->get_body;

{
  my $m = $body->search("☺");
  ok($m->{segment}, "The :chars import tag implies Huse_character_strings");

  like(fmt_node($m->{segment}), qr/☺Unicode/, 
       ":DEFAULT still imports others")
}
done_testing();
