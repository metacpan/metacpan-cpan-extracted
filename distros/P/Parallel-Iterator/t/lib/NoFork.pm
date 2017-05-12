# $Id: NoFork.pm 2683 2007-10-04 12:35:06Z andy $
package NoFork;

# This code originally written by Eric Wilhelm for the Test::Harness
# project. Thanks Eric - it's just what I needed :)

BEGIN {
    *CORE::GLOBAL::fork = sub { die "you should not fork" };
}
use Config;
tied( %Config )->{d_fork} = 0;    # blatant lie

=begin TEST

Assuming not too much chdir:

  PERL5OPT='-It/lib -MNoFork' perl -Ilib bin/prove -r t

=end TEST

=cut

1;
