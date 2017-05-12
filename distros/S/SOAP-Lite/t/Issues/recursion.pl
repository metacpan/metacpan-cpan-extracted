use strict;
use warnings;

## disable perl's warning mechanism
no warnings 'recursion';

use B      'svref_2object';
use Symbol 'qualify_to_ref';

sub change_depth_warn {
  my($subname, $limit) = @_;
  my $subref = \&$subname;
  my $gv     = svref_2object($subref)->GV;
  my $lineno = 0;

  no warnings 'redefine';
  *{ qualify_to_ref $subname } = sub {
     if( $gv->CV->DEPTH % $limit == 0 ) {
     $lineno = do {
     my $i = 0;
     1 while caller $i++;
     (caller($i - 2))[2]
    } unless $lineno;
    warn  sprintf "Deep recursion on subroutine '%s' at %s line %d.\n",  join('::', $gv->STASH->NAME, $gv->NAME), $0, $lineno;
  }
  &$subref(@_);
 };
}

																							my $cnt = 0;
																							sub foo { &foo while $cnt++ < $_[0] }

																							my $maxdepth = 10;
																							my $recdepth = 30;
																							change_depth_warn('foo', $maxdepth);

																							printf "calling foo(), expecting %d warnings ...\n",
																							       $recdepth / $maxdepth;

																								   foo($recdepth);
