#$Id: Always.pm,v 0.01 2001/09/08 19:54:10 perler@xorgate.com Exp $
package Apache::OpenIndex;
use strict;

# Always is always called before each OpenIndex managed display.
#
# The following directive was use for always.
#
# OpenIndexOptions Always Always always
#
# This is a useless routine, but hey, it is a example.
#
sub always {
    my ($r,$args,$cfg,$uri) = @_;
    print STDERR "### always() proc=$args->{proc} uri=$uri\n" if $debug;
    1;
}
1;
