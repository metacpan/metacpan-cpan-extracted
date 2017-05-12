use 5.006;
use strict;
use warnings;
use Test::More tests => 21;
use Data::Dumper;

BEGIN { use_ok('Parse::ExuberantCTags') };
chdir('t') if -d 't';
use File::Spec;

SCOPE: {
  my $notptags = Parse::ExuberantCTags->new( 'perltagsdoesntexist' );
  ok(!defined($notptags), 'bad file returns undef');
}

SCOPE: {
  my $ptags = Parse::ExuberantCTags->new( File::Spec->catfile("data", "testtags") );
  isa_ok($ptags, 'Parse::ExuberantCTags');

  my $entry = $ptags->firstTag();
  is_deeply($entry, {
    file              => '/usr/local/share/perl/5.10.0/Padre/Util.pm',            
    name              => 'WXWIN32',                                               
    fileScope         => 0,                                                  
    kind              => 'c',
    addressPattern    => '/use constant WXWIN32 => WIN32;/',
    addressLineNumber => 58,
    extension         => {'class' => 'Padre::Util'},
  }, "first tag as expected");

  my $entry2 = $ptags->nextTag();
  is_deeply($entry2, {
    file              => '/usr/lib/perl/5.10/IO/File.pm',
    name              => 'IO::File',
    fileScope         => 0,
    kind              => 'p',
    addressPattern    => '/package IO::File;/',
    addressLineNumber => 3,
    extension         => {'class' => 'IO::File'},
  }, "second tag as expected");

  my $entry3 = $ptags->firstTag();
  is_deeply($entry, $entry3);

  $entry = $ptags->nextTag();
  is_deeply($entry, $entry2);

  $entry = $ptags->nextTag();
  is_deeply($entry, {
    file              => '/usr/local/share/perl/5.10.0/File/Which.pm',
    name              => 'Is_DOSish',
    fileScope         => 1,
    kind              => 'v',
    addressPattern    => '/my $Is_DOSish = (($^O eq \'MSWin32\') or/',
    addressLineNumber => 18, 
    extension         => {'class' => 'File::Which'},
  }, "third tag as expected");

  ok(!defined($ptags->nextTag()), "returns undef at end of file");

  my $found = $ptags->findTag("foo");
  ok(!defined($found), "non-existant tag returns undef");

  $found = $ptags->findTag("is_dosish");
  ok(!defined($found), "wrong caps in tag returns undef");

  $found = $ptags->findTag("is_dosish", ignore_case => 1);
  is_deeply($found, $entry, "ignoring case finds the right tag");

  $found = $ptags->findTag("Is_DOSish");
  is_deeply($found, $entry, "right case finds right tag");

  $found = $ptags->findTag("Is_DOSish", ignore_case => 1);
  is_deeply($found, $entry, "right case finds right tag -- also with ignore_case");

  $found = $ptags->findTag("Is_DOS");
  ok(!defined($found), "partial without partial is undef");

  $found = $ptags->findTag("Is_DOS", partial => 1);
  is_deeply($found, $entry, "partial option works");

  $found = $ptags->findTag("Is_dos", partial => 1, ignore_case => 1);
  is_deeply($found, $entry, "partial option works with ignore_case");

  $found = $ptags->findNextTag();
  ok(!defined($found), "only one tag matches in sample");

  $found = $ptags->findTag("i", partial => 1, ignore_case => 1);
  is_deeply($found, $entry2, "searching for 'i' yields second entry");

  $found = $ptags->findNextTag();
  is_deeply($found, $entry, "continuing search yields third");
}
pass("DESTROY of the ctags parser doesn't SEGV");


