use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'          => 'SuffixTree',
  'ABSTRACT_FROM' => 'SuffixTree.pm',
  'AUTHOR'        => 'Shlomo Yona <shlomo@cs.haifa.ac.il>',
  'LICENSE'       => 'perl',
  'OBJECT'        => 'suffix_tree_wrap.o suffix_tree.o',
  'VERSION_FROM'  => 'SuffixTree.pm', # finds $VERSION
);
print "\n";
print "Please take a moment to review the license.\n\n";
print "'make' to create the Makefile\n";
print "'make test' to test the module before installation\n";
print "'make install' to install the module.\n"; 
