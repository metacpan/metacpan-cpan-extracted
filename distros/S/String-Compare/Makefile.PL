use ExtUtils::MakeMaker;

my $mm = new MM
 (
  {
   AUTHOR => "Daniel Ruoso <daniel\@ruoso.com>",
   NAME => "String::Compare",
   ABSTRACT => "Compare two strings and return how much they are alike",
   VERSION => "0.4",
  }
 );

$mm->flush;
