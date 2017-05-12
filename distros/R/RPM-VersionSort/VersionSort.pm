package RPM::VersionSort;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter AutoLoader DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	     rpmvercmp
);
$VERSION = '1.00';

bootstrap RPM::VersionSort $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RPM::VersionSort - RPM version sorting algorithm, in perl XS

=head1 SYNOPSIS

  use RPM::VersionSort;
  rpmvercmp("2.0", "2.0.1");

=head1 DESCRIPTION

RPM uses a version number sorting algorithm for some of its decisions.
It's useful to get at this sorting algoritm for other nefarious
purposes if you are using RPM at your site.

=head1 AUTHOR

Daniel Hagerty, <hag@linnaean.org>

=head1 SEE ALSO

perl(1).

=cut
