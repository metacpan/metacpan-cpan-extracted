package Telugu::Keyword;

our $VERSION = '0.06';

use Mouse;
use utf8;
use Keyword::Declare;


sub import {

  keyword ప్రింటు (List $params){
  	return qq {
  		print $params;
  	};
  }

  keyword ముద్రణ (List $params){
  	return qq {
  		print $params, "\n";
  	};
  }

  keyword ఇవ్వు (Expression $expr){
  	return "return $expr";
  }

  keyword నా (List $list) {
  	return "my $list";
  }

  keyword తరువాత {
  	return "next";
  }


  keyword ధర్మం (QualIdent $name, List $params, Block $code) {
  	return qq{
  		sub $name {
  			my ($params) = \@_;
  			$code;
  		}
  	};
  }

  keyword వరకు (List $condition, Block $code) {
  	return qq{
  		while ($condition) {
  			$code;
  		}
  	};
  }

  keyword కొఱకు (Variable $var, List $range, Block $code) {
  	return qq{
  		for my $var ($range) {
  			$code;
  		}
  	};
  }

  keyword ఐతే (List $condition, Block $code) {
  	return qq{
  		if ($condition) {
  			$code;
  		}
  	};
  }

}

1;
__END__
=encoding utf-8

=head1 NAME

Telugu::Keyword - Perl extension to provide Telugu keywords

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Telugu::Keyword;
    use utf8;
    binmode STDOUT, ":encoding(UTF-8)";

    ధర్మం డోర్స్($ఎన్ని) {
         నా @డోర్స్;
         కొఱకు $పాస్ (1 .. $ఎన్ని) {
               కొఱకు $ఎ (1 .. $ఎన్ని) {
                     ఐతే (0 == $ఎ % $పాస్) {
                         $డోర్స్[$ఎ] = !$డోర్స్[$ఎ];
                     }
               }
         }
         కొఱకు $ఎ (1 .. $ఎన్ని) {
                ముద్రణ "డోర్ $ఎ ", $డోర్స్[$ఎ] ? "తెర్చుంది" : "మూసుంది";
         }
    }

    డోర్స్(100);

=head1 DESCRIPTION

This module provides keywords to write perl program in Telugu script

=head1 KEYWORDS

=head2 ప్రింటు

   ప్రింటు keyword is equivalent to print
   ప్రింటు "మీ తెలుగు సందేశం";

=head2 ముద్రణ

   ముద్రణ keyword is equivalent to print. It adds \n char at the end of the string.

=head2 నా

   నా keyword is equivalent to my

=head2 ధర్మం

   ధర్మం is equivalent to sub.
   ధర్మం takes parameters, instead of writing them inside sub.

   ex:
      ధర్మం డోర్స్($ఎన్ని) {
        ... # code here
      }

      is equivalent to

      sub డోర్స్ {
        my ($ఎన్ని) = @_;
        ... #code here
      }

=head2 ఇవ్వు

   ఇవ్వు keyword is equivalent to return statement in function

=head2 వరకు

   వరకు is equivalent to while loop

=head2 తరువాత

   తరువాత keyword is equivalent to next keyword. It is used in while loop

=head2 కొఱకు

   కొఱకు is equivalent to for loop. No need to write my inforont of the loop variable
   eq:
      కొఱకు $పాస్ (1 .. $ఎన్ని) {
        ... #code here
      }

      is equivalent to

      for my $పాస్ (1 .. $ఎన్ని) {
        ... #code here
      }

=head2 ఐతే

   ఐతే is equivalent to if condition

=head2 shoba

    shoba is an executable installed with this module
    write your program in telugu and save it in a file with .sb extension
    use strict;use warnings;use utf8;use Telugu::Keyword;binmode STDOUT, ":encoding(UTF-8)"; are preloaded in a .sb file
    execute .sb file with shoba command
    ex: shoba filename.sb

=head1 BUGS

None reported.
Please email me if you find any.

=head1 AUTHOR

Rajkumar Reddy, E<lt>mesg.raj@outlook.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by bird

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
