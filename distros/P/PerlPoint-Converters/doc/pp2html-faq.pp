
// vim: set filetype=pp2html:

// declare helpful macros
+BU:\B<\U<__body__>>

// Later we can re-define these macros to use funny images ...
+QST:\BU<Question:>

+ANS:\BU<Answer:>

+DSC:\BU<Discussion:>

// general headline
=FAQ for pp2html

// process all articles dynamically
\EMBED{lang=perl}

{
 # declare variables
 my $perlPoint='';
 my $faq = "faq-pp2html";

 # get all subdirectories
 opendir(D, $faq) or die "[Fatal] Cannot open directory \"$faq\"\n";
 my @categories=grep((-d "$faq/$_" and !/^\./ and !/^CVS$/), readdir(D));
 closedir(D);

 # process all categories
 foreach my $category (@categories)
   {
    # declare variables
    my %questions;

    # pass category name to PerlPoint
    $perlPoint.="\n\n==$category\n\n";

    # get all questions of this category
    opendir(D, "$faq/$category") or warn(qq([Error] Cannot open theme directory "$faq/$category"\n)), next;
    my @questions=grep(/\.pp$/, readdir(D));
    closedir(D);

    # open all files and extract their questions
    foreach my $question (@questions)
      {
       # open file
       open(Q, "$faq/$category/$question") or warn(qq([Error] Cannot open question file "$faq/$category/$question"\n)), next;
     
       # extract question
       while (<Q>)
         {
          # find question
          next unless /^=+(.+)$/;
          # and store it
          push(@{$questions{$1}}, $question);
         }

       # close file
       close(Q);
      }

    # anything found?
    if (%questions)
      {
       # process questions in sorted order
       foreach my $question (sort keys %questions)
         {
          # pass the file(s) to PerlPoint
          $perlPoint.=qq(\n\n\\INCLUDE{file="$faq/$category/$_" type=pp headlinebase=CURRENT_LEVEL}\n\n) foreach @{$questions{$question}};
         }
      }
   }

 # supply generated PerlPoint
 $perlPoint;
}

\END_EMBED
