#<<<
use strict; use warnings;
#>>>

use subs qw ( _which );

use Config     qw( %Config );
use File::Spec qw();

my ( $local_lib_root, $local_lib );

BEGIN {
  $local_lib_root = "$ENV{ PWD }/local";
  $local_lib      = "$local_lib_root/lib/perl5";
}
use lib $local_lib;

{
  no warnings 'once';
  *MY::postamble = sub {
    my $make_fragment = '';
    $make_fragment .= <<"MAKE_FRAGMENT" if _which 'cpanm';
ifdef PERL5LIB
  PERL5LIB := $local_lib:\$(PERL5LIB)
else
  export PERL5LIB := $local_lib
endif

$local_lib_root: cpanfile
	rm -fr \$@
	cpanm --no-man-pages --local-lib-contained \$@ --installdeps .

.PHONY: installdeps
installdeps: $local_lib_root
MAKE_FRAGMENT

    $make_fragment .= <<"MAKE_FRAGMENT" if _which 'cover';

.PHONY: cover
cover:
	cover -test -ignore local -report vim
MAKE_FRAGMENT

    return $make_fragment;
  };
}

sub _which ( $ ) {
  my ( $executable ) = @_;
  for ( split /$Config{ path_sep }/, $ENV{ PATH } ) {
    my $file = File::Spec->catfile( $_, $executable );
    return $file if -x $file;
  }
  return;
}
