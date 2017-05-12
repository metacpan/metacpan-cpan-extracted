# -*-perl-*-

use Test::More qw(no_plan);
use lib qw(.);

print STDERR "\n";

if (system ( qq($^X blib/script/pod2axpoint > /dev/null 2>&1) )) {
  pass ("Could execute pod2axpoint");
}
else {
  fail ("Could not execute pod2axpoint: $!");
}

# create a slideshow
my $cmd = qq( $^X blib/script/pod2axpoint t/test.pod > t/test.xml);

if ( system($cmd) ){
  fail ("Could not create slideshow: $!");

}
else {
  pass ("Successfully created a test slideshow");
}

my $index = '';
# check if the supplied template variables have it made to the slideshow
if ( open T, "<t/test.xml") {
  pass ("Successfully opened the generated slideshow");
  $index = join '', <T>;
  close T;
}
else {
  fail ("Could not open the generated slideshow: $!");
}

my @lookat = ('print TRUE', '<source-code>', '<object' );
if (grep {$index =~ /$_/} @lookat) {
  pass ("Found template variables in slideshow");
}
else {
  fail ("Could not find template variables in slideshow");
}


1;
