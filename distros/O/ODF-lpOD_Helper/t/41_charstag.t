#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, Data::Dumper::Interp, etc.
use t_TestCommon ':silent',
                 qw/bug tmpcopy_if_writeable $debug/;

use ODF::lpOD;
use ODF::lpOD_Helper qw/:DEFAULT/;

my $master_copy_path = "$Bin/../tlib/Skel.odt";
my $input_path = tmpcopy_if_writeable($master_copy_path);
my $doc = odf_get_document($input_path, read_only => 1);
my $body = $doc->get_body;

{
  my $m = $body->search("☺");
  ok($m->{segment}, "Character mode is now the default");

  like(fmt_node($m->{segment}), qr/☺Unicode/, 
       ":DEFAULT imports fmt_node")
}
done_testing();
