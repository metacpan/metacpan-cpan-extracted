package Object::Tap;

use strict;
use warnings;
use base qw(Exporter);

our $VERSION = '1.000003'; # 1.0.3

our @EXPORT = qw($_tap);

our $_tap = sub { my ($obj, $call, @args) = @_; $obj->$call(@args); $obj };

1;

=head1 NAME

Object::Tap - Tap into a series of method calls to alter an object

=head1 SYNOPSIS

Instead of writing -

  my $thing = My::Class->new(...);
  
  $thing->set_foo(1);

you can instead write -

  use Object::Tap;
  
  my $thing = My::Class->new(...)->$_tap(sub { $_[0]->set_foo(1) });

To realise why this might be useful, consider instead -

  My::App->new(...)->$_tap(...)->run;

where a variable is thereby not required at all.

You can also pass extra args -

  $obj->$_tap(sub { warn "Got arg: $_[1]" }, 'arg');

or use a method name instead of a sub ref -

  my $thing = My::Class->new(...)->$_tap(set_foo => 1);

For a 'real' example of how that might be used, one could create and
initialize an L<HTML::TableExtract> object in one go using -

  my $te = HTML::TableExtract->new->$_tap(parse => $html);

=head1 AUTHOR

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None yet. Well volunteered? :)

=head1 COPYRIGHT

Copyright (c) 2014 the Object::Tap L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
