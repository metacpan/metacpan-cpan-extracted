#!/bin/sh

./install_distroprefs.sh

export perl_version=`perl -MConfig -e 'print $Config{version}'`
eval $(perl -I$HOME/.perl5/$perl_version/lib/perl5 -Mlocal::lib=$HOME/.perl5/$perl_version/)

cd Task-Bootstrap
dzil build

cd Task-Bootstrap-1.0
PERL_MM_USE_DEFAULT=1 cpan .
