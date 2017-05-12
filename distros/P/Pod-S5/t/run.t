# -*-perl-*-

use Test::More qw(no_plan);
use lib qw(.);

if ( system ( qq($^X blib/script/pod2s5 > /dev/null 2>&1) )) {
  fail ("Could not execute pod2s5: $!");
}
else {
  pass ("Could execute pod2s5");
}

# create a slideshow
my $cmd = qq( $^X blib/script/pod2s5 ) .
  qq(--theme     'flower' ) .
  qq(--author    'make test' ) .
  qq(--creation  '13.Nov.2007' ) .
  qq(--company   'The Perl Republic' ) .
  qq(--name      'How to make test' ) .
  qq(--where     'Vulcan' ) .
  qq(--dest      't/test' t/test.pod);

if ( system($cmd) ) {
  fail ("Could not create slideshow: $!");
}
else {
  pass ("Successfully created a test slideshow");
}

my $index = '';

# check if the supplied template variables have it made to the slideshow
if (open T, "<t/test/index.html" ) {
  pass ("Successfully opened the generated slideshow");
  $index = join '', <T>;
  close T;
}
else {
  fail ("Could not open the generated slideshow: $!");
}


my @lookat = ('make test', '13.Nov.2007', 'The Perl Republic',
	      'How to make test', 'Vulcan',
	      '<div class="slide">', 'print TRUE', '>Link<',
	      '<ul class="incremental">', '<code>', '<object'
	     );
if (grep {$index =~ /$_/} @lookat) {
  pass ("Found template variables in slideshow");
}
else {
  fail ("Could not find template variables in slideshow");
}


1;
