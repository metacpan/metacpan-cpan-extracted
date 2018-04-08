
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use Test::More tests => 1;
use Template::Perlish;

(my $filename = $INC{'Template/Perlish.pm'}) =~ s{pm$}{pod};

my $pod_version;

{
   open my $fh, '<', $filename
     or BAIL_OUT "can't open '$filename'";
   binmode $fh, ':raw';
   local $/;
   my $module_text = <$fh>;
   ($pod_version) = $module_text =~ m{
      ^This\ document\ describes\ Template::Perlish\ version\ (.*?).$
   }mxs;
}

is $pod_version, $Template::Perlish::VERSION, 'version in POD';
