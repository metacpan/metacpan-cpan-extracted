# $Id: NIS.pm,v 1.2 1995/07/15 12:38:59 rik Exp $

package Net::NIS;

require Exporter;
require AutoLoader;
require DynaLoader;
@ISA = qw(Exporter AutoLoader DynaLoader);
# Items to export into callers namespace by default
# (move infrequently used names to @EXPORT_OK below)
@EXPORT = qw( 
);
# Other items we are prepared to export if requested
@EXPORT_OK = qw(
);

bootstrap Net::NIS;

# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.

1;
__END__
