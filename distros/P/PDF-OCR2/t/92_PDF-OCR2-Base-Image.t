use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Cwd;
use vars qw($_part $cwd);
$cwd = cwd();
use PDF::OCR2::Base::Image;

my $DEBUG = $ARGV[0] eq '-d' ? 1 : 0;

my $abs = './t/imgs/image.tif';

testone($abs);

sub testone {
   my $abs = shift;
   -f $abs or die;
   
   my $i;
   ok( $i = PDF::OCR2::Base::Image->new($abs),"instanced for $abs")
      or die;

   my $txt = $i->text;

   ok($txt,"text()");

   my $txt_length = $i->text_length;
   ok($txt_length,"text_length() $txt_length");

   $DEBUG and warn("Text is: \n\n$txt\n\n");

   

}
   












sub ok_part {
   printf STDERR "\n\n===================\nPART %s %s\n==================\n\n",
      $_part++, "@_";
}



