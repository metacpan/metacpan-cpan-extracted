
require 5;
# Time-stamp: "2003-10-14 18:48:09 ADT"
use strict;
use Test;

BEGIN { plan tests => 10 }

use RTF::Writer 1.10;
ok 1;

sub isbal ($) { (my $x = $_[0]) =~ tr/\{\}//cd; while($x =~ s/\{\}//g){;}; length($x) ? 0 : 1 }

foreach my $i (qw(png jpg)) {
  my $filename = "hypnocat2_$i.rtf";
  use File::Spec;
  $filename = File::Spec::->catfile( File::Spec::->curdir(), $filename);

  print "# Writing to $filename...\n";
  my $rtf = RTF::Writer->new_to_file($filename);
  $rtf->prolog( 'title' => "Greetings, $i hyoomon" );
  $rtf->number_pages;
  $rtf->paragraph(
    \'\fs40\b\i',  # 20pt, bold, italic
    "Hi there!"
  );

  my $imagepath;
  ok(
   -e(
    $imagepath = File::Spec::->catfile( File::Spec::->curdir(), 't', "hypnocat.$i")
   ) or -e(
    $imagepath = File::Spec::->catfile( File::Spec::->curdir(), "hypnocat.$i")
   )
   or 0
  );

  $rtf->paragraph(
    "Blah blah blah ",
    $rtf->image('filename' => $imagepath),
    " blah blah -- it's a $i!",
  );

  $rtf->paragraph("Here's a subsequent paragraph.");
  
  $rtf->close;
  ok 1;

  my $errorcount;

  undef $rtf;
  {
    print "# Now checking $filename...\n";
    open IN, $filename or die "Can't read-open $filename: $!";
    local $/;
    my $rtf = <IN>;
    close(IN);
    
    ok $rtf, '/\\\\pict/'  # simple sanity
     or ++$errorcount;
    ok isbal($rtf), 1, "$filename 's is unbalanced"
     or ++$errorcount;
  }
  $errorcount or unlink $filename;
}

print "# Byebye\n";
ok 1;
