use strict;
use warnings;

use Test::Most;

use Pod::Knit::Document;

my $doc = Pod::Knit::Document->new( content => <<'POD' =~ s/^    //rmg );

    =head1 SYNOPSIS

    Something B<nice>.

    =head1 Blah

            this is
              verbatim
            
            and it still is

    =cut

POD

like $doc->xml_pod, qr/<document/;

like $doc->as_pod, qr/
    ^ \s{4} this \s is \n
      \s{6}verbatim
/mx, "verbatim blocks are indented by 4 characters";

done_testing;

