package Razor2::Preproc::deHTMLxs;

use strict;

use Exporter   ();
use XSLoader   ();
use AutoLoader ();

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
our @EXPORT  = qw();
our $VERSION = '2.86';

XSLoader::load( 'Razor2::Preproc::deHTMLxs', $VERSION );

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Razor2::Preproc::deHTMLxs - Perl extension for libpreproc deHTMLxs code

=head1 SYNOPSIS

  use Razor2::Preproc::deHTMLxs;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Razor2::Preproc::deHTMLxs was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
