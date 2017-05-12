
// process a directory, insert all files found
\EMBED{lang=perl}

use strict;

sub includeDirectoryFiles
 {
  # get and check parameters
  my ($dir)=@_;
  die qq([Error] Missing directory option.\n) unless $dir;
  die qq([Error] Directory "$dir" does not exist.\n) unless -d $dir;

  # declare variables
  my ($perlPoint, %headlines)='';

  # get all sources of this category
  opendir(D, $dir) or die(qq([Error] Cannot open directory "$dir".\n));
  my @sources=grep(/\.pp$/, readdir(D));
  closedir(D);

  # open all files and extract their first headline
  foreach my $source (@sources)
    {
     # open file
     open(F, "$dir/$source") or warn(qq([Error] Cannot open file "$dir/$source"\n)), next;
     
     # extract headline
     while (<F>)
       {
        # find headline
        next unless /^=+(.+)$/;
        # and store it
        push(@{$headlines{$1}}, $source);
        last;
       }

     # close file
     close(F);
    }

  # anything found?
  if (%headlines)
    {
     # process files in sorted order
     foreach my $headline (sort keys %headlines)
       {
        # pass the file(s) to PerlPoint
        $perlPoint.=qq(\n\n\\INCLUDE{file="$dir/$_" type=pp headlinebase=CURRENT_LEVEL}\n\n) foreach @{$headlines{$headline}};
       }
    }

  # supply generated PerlPoint
  $perlPoint;
 }

\END_EMBED
