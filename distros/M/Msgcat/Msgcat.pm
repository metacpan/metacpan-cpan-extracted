package Locale::Msgcat;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '1.03';

## Define required constants
#require 'nl_types.ph';

bootstrap Locale::Msgcat $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Locale::Msgcat - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Locale::Msgcat;
  
  $cat = new Locale::Msgcat;

  $rc  = $cat->catopen(name, oflag);
  $msg = $cat->catgets(set_number, message_number, string);
  $rc  = $cat->catclose();

=head1 DESCRIPTION

The B<Locale::Msgcat> module allows access to the message catalog functions
which are available on some systems. A new Locale::Msgcat object must first
be created for each catalog which has to be open at a given time.

The B<catopen> operation opens the catalog whose name is given as argument.
The oflag can be either 0 or NL_CAT_LOCALE (usually 1) which is the recommended
value.

The B<catgets> message retrieves message_number for the set_number message
set, and if not found returns string.

The B<catclose> function should be used when access to a catalog is not
needed anymore.

=head1 EXAMPLES

  use Locale::Msgcat;

  $cat = new Locale::Msgcat;
  unless ($cat->catopen("whois.cat", 1)) {
      print STDERR "Can't open whois catalog.\n";
      exit(1);
  }
  printf "First message, first set : %s\n", $cat->catgets(1, 1, "not found");
  unless ($cat->catclose()) {
      print STDERR "Can't close whois catalog.\n";
      exit(1);
  }

The above example would print the first message from the first message
set found in the whois catalog, or if not found it would print "not found".

=head1 AUTHOR

Christophe Wolfhugel, wolf@pasteur.fr

=head1 SEE ALSO

catopen(3), catclose(3), catgets(3), perl(1).

=cut

1;
