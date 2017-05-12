######################### -*- Mode: Perl -*- #########################
##
## File          : Mrequire.pm
##
## Author        : Norbert Goevert
## Created On    : Fri Oct 16 13:13:11 1998
## Last Modified : Time-stamp: <2003-12-08 17:01:35 goevert>
##
## Description   : require on Perl extensions at run time
##
## $Id: Mrequire.pm,v 1.6 2003/12/08 16:19:06 goevert Exp $
##
######################################################################


use strict;


## ###################################################################
## package Mrequire
## ###################################################################

package Mrequire;

use Exporter;
use Carp;

use vars qw($VERSION @ISA @EXPORT_OK);
'$Name: release_0_6 $ 0_0' =~ /(\d+)[-_](\d+)/; $VERSION = sprintf '%d.%03d', $1, $2;

@ISA =qw(Exporter);
@EXPORT_OK = qw(mrequire);


## public ############################################################


sub mrequire ($ ) {

  my $file = shift;
  
  $file =~ s!::!/!g;
  $file .= '.pm';

  my $result;

  eval { $result = require $file };
  if ($@) {
    chomp $@;
    croak $@;
  }

  return $result;
}


## private ###########################################################

sub AUTOLOAD {

  my $func = $Mrequire::AUTOLOAD; $func =~ s/.*:://;
  my $class = $_[0];

  $class .= '::' . $func;

  no strict 'refs';
  return &$class(@_);
}


1;
__END__
## ###################################################################
## pod
## ###################################################################

=head1 NAME

Mrequire - require on Perl extensions at run time

=head1 SYNOPSIS

  require Mrequire;
  my $class = ('Foo::Bar', 'Bar::Baz')[int(rand + .5)];
  Mrequire::mrequire($class);
  &Mrequire::new($class, $arg1, $arg2, ...);

  use Mrequire qw(mrequire);
  mrequire(...)

=head1 DESCRIPTION

B<Mrequire> can be used to dynamically load Perl extensions at run
time. This becomes necessary if the decision of what kind of module
you want to use (or is available at all) is made at run time.

In addition you can call constructor-like functions (which assume the
package name as their first argument, see pertoot(1) for details) of
dynamically loaded modules via Mrequire.

=head1 METHODS

=over 3

=item mrequire($class)

Does a C<require> on package C<$class>. If a respective library file
cannot be loaded the process dies.

=item &Mrequire::constructor($class, $arg1, $arg2, ...)

Calls function C<constructor> in package $class. It is assumed that
C<constructor> expects the package name as a first argument.

=back

=head1 BUGS

Yes. Please let me know!

=head1 SEE ALSO

perl(1), perltoot(1).

=head1 AUTHOR

Norbert GE<ouml>vert E<lt>F<goevert@ls6.cs.uni-dortmund.de>E<gt>

=head1 COPYRIGHT

Copyright (c) 2003 Norbert GE<ouml>vert. All rights reserved. This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
