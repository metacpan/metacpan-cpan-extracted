#!/usr/bin/perl

# bin/extractuse
#  Extract modules used by this distribution
#
# $Id: extractuse 6744 2009-04-29 14:32:07Z FREQUENCY@cpan.org $
#
# This package and its contents are released by the author into the
# Public Domain, to the full extent permissible by law. For additional
# information, please see the included `LICENSE' file.

use strict;
use warnings;

use Pod::Usage;

=head1 NAME

extractuse - determine what Perl modules are used in a given file

=head1 VERSION

Version 1.0 ($Id: extractuse 6744 2009-04-29 14:32:07Z FREQUENCY@cpan.org $)

=cut

use version; our $VERSION = qv('1.0');

=head1 SYNOPSIS

Usage: extractuse filename [...]

Given a single path referring to a file containing Perl code, this script will
determine the modules included statically. This means that files included
by C<use> and C<require> will be retrieved and listed.

=head1 DESCRIPTION

This script is safe because the Perl code is never executed, only parsed by
C<Module::Extract::Use> or C<Module::ExtractUse>, which are two different
implementations of this idea. This module will prefer C<Module::Extract::Use>
if it is installed, because it uses PPI to do its parsing, rather than its
own separate grammar.

However, one limitation of this script is that only statically included
modules can be found - that is, they have to be C<use>'d or C<require>'d
at runtime, and not inside an eval string, for example. Because eval strings
are completely dynamic, there is no way of determining which modules might
be loaded under different conditions.

=cut

my @files = @ARGV;
my $class = 'Module::Extract::Use';

# if no parameters are passed, give usage information
unless (@files) {
  pod2usage(msg => 'Please supply at least one filename to analyze');
  exit();
}

eval {
  require Module::Extract::Use;
};
if ($@) {
  $class = 'Module::ExtractUse';
  eval {
    require Module::ExtractUse;
  };
  if ($@) {
    print {*STDERR} "No usable module found; exiting...\n";
    exit 1;
  }
}

eval {
  require Module::CoreList;
};
my $corelist = not $@;

foreach my $file (@files) {
  my $mlist;
  unless (-e $file and -r _) {
    printf {*STDERR} "Failed to open file '%s' for reading\n", $file;
    next;
  }
  if ($class eq 'Module::ExtractUse') {
    $mlist = Module::ExtractUse->new;
    $mlist->extract_use($file);
    dumplist($file, $mlist->array);
  }
  else {
    $mlist = Module::Extract::Use->new;
    dumplist($file, $mlist->get_modules($file));
  }
}

sub dumplist {
  my ($file, @mods) = @_;

  printf "Modules required by %s:\n", $file;
  my $core = 0;
  my $extern = 0;
  foreach my $name (@mods) {
    print ' - ' . $name;
    if ($corelist) {
      my $ver = Module::CoreList->first_release($name);
      if (defined $ver) {
        printf ' (first released with Perl %s)', $ver;
        $core++;
      }
      else {
        $extern++;
      }
    }
    print "\n";
  }
  printf "%d module(s) in core, %d external module(s)\n\n", $core, $extern;
}

=head1 AUTHOR

Jonathan Yu E<lt>frequency@cpan.orgE<gt>

=head1 SUPPORT

For support details, please look at C<perldoc Module::Extract::Use> or
C<perldoc Module::ExtractUse> and use the corresponding support methods.

=head1 LICENSE

Copyleft (C) 2009 by Jonathan Yu <frequency@cpan.org>. All rights reversed.

I, the copyright holder of this script, hereby release the entire contents
therein into the public domain. This applies worldwide, to the extent that
it is permissible by law.

In case this is not legally possible, I grant any entity the right to use
this work for any purpose, without any conditions, unless such conditions
are required by law. If not applicable, you may use this script under the
same terms as Perl itself.

=head1 SEE ALSO

L<Module::Extract::Use>,
L<Module::ExtractUse>,
L<Module::ScanDeps>,

=cut
