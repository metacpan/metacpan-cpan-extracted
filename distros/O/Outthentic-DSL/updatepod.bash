markdown2pod README.md > README.pod
cp lib/Outthentic/DSL.pm lib/Outthentic/DSL.pm.orig
perl -n -e 'print unless /__END__/ ... eof()' lib/Outthentic/DSL.pm.orig > lib/Outthentic/DSL.pm
( echo __END__; echo; cat README.pod ) >> lib/Outthentic/DSL.pm
rm -rf lib/Outthentic/DSL.pm.orig
  
