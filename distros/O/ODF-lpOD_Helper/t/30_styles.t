#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, Data::Dumper::Interp, etc.
use t_TestCommon ':silent',
                 qw/bug tmpcopy_if_writeable $debug/;

use ODF::lpOD;
use ODF::lpOD_Helper;

my $doc = odf_create_document("text");
my $body = $doc->get_body;

my $as1 = $doc->Hautomatic_style("text", "bold", "42");
is($as1, 
   hash {
     field att => hash {
       #field "style:class" => "text";
       field "style:family" => "text";
       etc();
     };
     field first_child => hash {
       field att => hash {
         field "fo:font-weight" => "bold";
         field "fo:font-size" => "42pt";
         field "style:automatic" => 1;
         field "style:part" => "content.xml";
         end();  # etc(); ???
       };
       etc();
     };
     etc();
   },
   "automatic style #1"
);

my %cs;
for my $N (1,2,3) {
  $cs{$N} = $doc->Hcommon_style("text", name => "CS$N", "bold", "42");
  is($cs{$N}, 
     hash {
       field att => hash {
         #field "style:class" => "text";
         field "style:family" => "text";
         etc();
       };
       field first_child => hash {
         field att => hash {
           field "fo:font-weight" => "bold";
           field "fo:font-size" => "42pt";
           field "style:automatic" => 0;
           field "style:part" => "styles.xml";
           end();  # etc(); ???
         };
         etc();
       };
       etc();
     },
     "common style #$N"
  );
}

my $as2 = $doc->Hautomatic_style("text", "italic", "9");
is($as2, 
   hash {
     field att => hash {
       #field "style:class" => "text";
       field "style:family" => "text";
       etc();
     };
     field first_child => hash {
       field att => hash {
         field "fo:font-style" => "italic";
         field "fo:font-size" => "9pt";
         field "style:automatic" => 1;
         field "style:part" => "content.xml";
         end();  # etc(); ???
       };
       etc();
     };
     etc();
   },
   "automatic style #2"
);

my $as3 = $doc->Hautomatic_style("text", weight => "bold", size => "42pt");
ref_is($as1, $as3, "automatic style was reused",
       "as1:".fmt_tree($as1)."\nas3:".fmt_tree($as3));

my $as4 = $doc->Hautomatic_style("text", "bold", "4");
ref_is_not($as1, $as4, "unexpected alias did not occur");

ok((none{ my $k=$_; any{ $_ != $k && $cs{$k}==$cs{$_} } keys %cs } keys %cs),
   "common styles not reused");

ok((none{ $cs{1}==$_ or $cs{2}==$_ or $cs{3}==$_ } $as1, $as2),
   "no common:automatic aliasing");

done_testing();
