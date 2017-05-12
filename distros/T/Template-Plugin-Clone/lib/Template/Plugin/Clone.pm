package Template::Plugin::Clone;
use Template::Plugin::Procedural;
use base qw(Template::Plugin::Procedural);

use Storable qw(dclone);

use strict;
#use warnings;

use vars qw($VERSION);
$VERSION = "0.01";

sub clone
{
  return dclone($_[0])
    if ref $_[0];

  my $thingy = shift;
  return $thingy;
}

1;

=head1 NAME

Template::Plugin::Clone - clone objects within TT

=head1 SYNOPSIS

  [% USE Clone %]
  [% bar = Clone.clone(foo) %]

  [% USE CloneVMethods %]
  [% baz = foo.clone %]

=head1 DESCRIPTION

Clones objects and datastructures from within the Template
Toolkit using the C<dclone> method from B<Storable>.  If the item
passed to the function isn't a object or data structure then it
is simply copied.

To access the C<clone> function like a class method, simply use the
plugin from within a Template Toolkit template:

  [% USE Clone %]

And then call the method against the Clone object.

  [% bar = Clone.close(foo) %]

Alternatively you can load the function as vmethods:

  [% USE CloneVMethods %]
  [% baz foo.clone %]

Using the VMethods plugin as above will cause the vmethods to be in
effect for the current template and all templates called from that
template.  To allow all templates called from any instance of the
Template module load the module from Perl with the 'install'
parameter.

  use Template::Plugin::CloneVMethods 'install';

=head1 AUTHOR

Written by Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

Copryright Mark Fowler 2003.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

Main functionality imported from Storable, which was written by
Raphael Manfredi E<lt>Raphael_Manfredi@pobox.comE<gt> and is now
maintained by the perl5-porters E<gt>perl5-porters@perl.orgE<lt>

=head1 BUGS

None known.

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-Clone>.

=head1 SEE ALSO

L<Storable>
L<Template::Plugin::Procedural>
L<Template::Plugin::VMethods>

=cut

1;
