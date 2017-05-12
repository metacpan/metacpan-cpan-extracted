
\EMBED{lang=perl}

 # a very general test filter
 sub numberLines
  {
   # get parameters: start value
   my ($counter)=@_;
   $counter=1 unless defined $counter;

   # declare variables
   my ($buffer, @results, @lines, @buffer)=(0, '');

   # extract lines
   @lines=split("\n", $main::_pfilterText);

   # block specific preparations
   @buffer=(shift(@lines), pop(@lines)) if $main::_pfilterType eq 'verbatim block';
   $lines[0]=~/^(\s*)/, $buffer=defined $1 ? $1 : '' if $main::_pfilterType=~/block$/;

   # handle paragraph lines
   foreach my $line (@lines)
    {
     # empty lines in blocks
     push(@results, $main::_pfilterType=~/block$/ ? join('', $buffer, sprintf("%.2d:", $counter++)) : ''), next unless $line;

     # typical block lines
     push(@results, join('', $1, sprintf("%.2d: ", $counter++), $2)), next if $line=~/^(\s+)(.*)$/;

     # headlines
     push(@results, join('', $1, sprintf("%.2d: ", $counter++), $2)), next if $main::_pfilterType eq 'headline' and $line=~/^(=+)(.*)$/;

     # list lines
     push(@results, join('', $1, sprintf("%.2d: ", $counter++), $2)), next if $line=~/^([*#]\s*)(.*)$/ and $main::_pfilterType eq 'list';
     push(@results, join('', $1, sprintf(" (%.2d)", $counter++))), next if $line=~/^(:[^:]+:\s*.*)$/ and $main::_pfilterType eq 'list';

     # other lines
     push(@results, join('', sprintf("%.2d: ", $counter++), $line));
    }

   # complete result
   unshift(@results, $buffer[0]), push(@results, $buffer[1]) if $main::_pfilterType eq 'verbatim block';

   # provide result
   join('', map {"$_\n"} @results);
  }

\END_EMBED

