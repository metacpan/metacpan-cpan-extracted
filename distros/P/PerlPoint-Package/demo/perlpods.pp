
//
// A PerlPoint document demonstrating how to process POD.
// To show this, all POD files in the distribution of the
// running perl are converted.
//
// This is version 0.01, part of the PerlPoint::Package distribution.
//
// Copyright (c) Jochen Stenzel (perl@jochen-stenzel.de), 2003. All rights reserved.
//


//
// Recommended converter options: "-active -safe ALL".
//
//              Do *not* use the cache!
// 


\EMBED{lang=perl}

# load libraries
use Pod::PerlPoint;
use File::Basename;
use Config qw(%Config);

# declare the filter function
sub pod2pp
 {
  my ($pod2pp, $result)=(new Pod::PerlPoint());
  $pod2pp->output_string(\$result);
  $pod2pp->parse_string_document(@main::_ifilterText);
  $result;
 }

# build output from all POD files in the distribution of the running perl
my $pp="\n\n";
$pp=join('', $pp, "\n=", basename($_, '.pod'), qq(\n\n\\INCLUDE{file="$_" ifilter=pod2pp type=pp headlinebase=CURRENT_LEVEL}), "\n\n") for (sort <$Config{privlib}/pod/*.pod>);

# provide result
$pp;

\END_EMBED

