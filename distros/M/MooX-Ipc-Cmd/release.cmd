p4 edit Changes
cd `pwd -P`
cd ../lib
p4 edit ...
cd ../bin
p4 edit ...
cd ../NV-rtltime/
export PERL5LIB=$PERL5LIB:./lib:/home/nv/lib/perl5
dzil clean
dzil release
cd DIST*
cpanm . -l ../../
cd ../lib
p4 revert -a ...
cd ../bin
p4 revert -a ...

