use strict;
use Rinchi::CPlusPlus::Preprocessor;

my %new_line = (
  'command_line' => 3,
  'include_directory' => 3,
  'object_macro' => 1,
  'predefined_macro' => 3,
  'preprocessing_file' => 3,
  'translation_unit' => 3,
  'use_on_code' => 3,
);

my @args = (
  'test.pl',
  '--debug',
);

my @xargs = (
  '-I/usr/include',
  '-I/usr/include/glib-2.0',
  '-I/home/bames/install/gnucash-2.2.2',
  '-I/home/bames/install/gnucash-2.2.2/src',
  '-I/home/bames/install/gnucash-2.2.2/src/app-utils',
  '-I/home/bames/install/gnucash-2.2.2/src/business/business-core',
  '-I/home/bames/install/gnucash-2.2.2/src/business/business-gnome',
  '-I/home/bames/install/gnucash-2.2.2/src/business/business-ledger',
  '-I/home/bames/install/gnucash-2.2.2/src/business/business-utils',
  '-I/home/bames/install/gnucash-2.2.2/src/business/dialog-tax-table',
  '-I/home/bames/install/gnucash-2.2.2/src/calculation',
  '-I/home/bames/install/gnucash-2.2.2/src/core-utils',
  '-I/home/bames/install/gnucash-2.2.2/src/engine',
  '-I/home/bames/install/gnucash-2.2.2/src/gnc-module',
  '-I/home/bames/install/gnucash-2.2.2/src/gnome',
  '-I/home/bames/install/gnucash-2.2.2/src/gnome-search',
  '-I/home/bames/install/gnucash-2.2.2/src/gnome-utils',
  '-I/home/bames/install/gnucash-2.2.2/src/import-export',
  '-I/home/bames/install/gnucash-2.2.2/src/register/ledger-core',
  '-I/home/bames/install/gnucash-2.2.2/src/register/register-core',
  '-I/home/bames/install/gnucash-2.2.2/src/register/register-gnome',
  '-I/home/bames/install/gnucash-2.2.2/src/report/report-gnome',
  '-I/home/bames/install/gnucash-2.2.2/src/report/report-system',
  '-I/home/bames/install/gnucash-2.2.2/src/report/stylesheets',
  '-DG_BYTE_ORDER:G_LITTLE_ENDIAN',
  '-Uaaa',
#  '-I/home/bames/project/rinchi/Rinchi/farpp/include',
#  '-P',
#   '-D__GNUC__:1',
#   '-D__STRICT_ANSI__:1',
#   '-D_XOPEN_SOURCE:400',
#   '-D_POSIX_SOURCE:1',
#   '-D_POSIX_C_SOURCE:1',
#  '-DONE:1',
#  '-DTWO:2',
#  '-DTHREE:3',
#  '-DFOUR:4',
#  '-Uaaa',
);

my $closed = 0;

sub startElementHandler() {
  my ($tag, $hasChild, %attrs) = @_;
  print "<$tag";
  foreach my $attr (sort keys %attrs) {
    my $val = $attrs{$attr};
    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;
    $val =~ s/\'/&apos;/g;
    print " $attr=\"$val\"";
  }
  if ($hasChild == 0) {
    print " />";
    $closed = 1;
    if($new_line{$tag} & 1) {
      print "\n";
    }
  } else {
    print ">";
    $closed = 0;
    if($new_line{$tag} & 2) {
      print "\n";
    }
  }
}

sub endElementHandler() {
  my ($tag) = @_;
  if ($closed == 0) {
    print "</$tag>\n";
  } else {
    $closed = 0;
  }
}

sub characterDataHandler() {
  my ($cdata) = @_;
  print $cdata;
}

sub processingInstructionHandler() {
  my ($target,$data) = @_;
  print "<?$target $data?>\n";
}

sub commentHandler() {
  my ($string) = @_;
  print "<!-- $string -->\n";
}

sub startCdataHandler() {
  print "<![CDATA[";
}

sub endCdataHandler() {
   print "]]>";
}

sub xmlDeclHandler() {
#  print 'xmlDeclHandler',@_,"\n";
  my ($version, $encoding, $standalone) = @_;
  print "<?xml version=\"$version\" encoding=\"$encoding\" standalone=\"$standalone\"?>\n";
}

my $cpp = new Rinchi::CPlusPlus::Preprocessor;
$cpp->setHandlers('Start'      => \&startElementHandler,
                  'End'        => \&endElementHandler,
                  'Char'       => \&characterDataHandler,
                  'Proc'       => \&processingInstructionHandler,
                  'Comment'    => \&commentHandler,
                  'CdataStart' => \&startCdataHandler,
                  'CdataEnd'   => \&endCdataHandler,
                  'XMLDecl'    => \&xmlDeclHandler,
                  );
#$cpp->process_file('test_src/recurring_macro.h',\@args);
#$cpp->process_file('test_src/if_elif.h',\@args);
#$cpp->process_file('test_src/include_test_1.h',\@args);
#$cpp->process_file('test_src/if_elif_else.h',\@args);
#$cpp->process_file('test_src/macro_expansion.cpp',\@args);

