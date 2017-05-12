#!perl
use Ruby::Run;

Perl.eval('use File::Spec');

fs = Perl['File::Spec'];

f = fs.catfile(fs.curdir, __FILE__);

p f;
p f = fs.rel2abs(f);
p fs.want(:array).splitpath(f);
p fs.devnull;
