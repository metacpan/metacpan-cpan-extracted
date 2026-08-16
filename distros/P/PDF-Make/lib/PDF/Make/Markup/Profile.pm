package PDF::Make::Markup::Profile;
use strict;
use warnings;

our $VERSION = '0.10';

# No logic lives here. What a template may not do - reach code, or turn a data
# value into markup - is decided in src/pdfmake_markup_profile.c and
# xs/markup_profile.xs. Even the filters are XSUBs: Template::Stencil takes
# filters as Perl coderefs, so the only way to offer formatting without
# offering a way back to arbitrary code is for the coderefs to be C.
require PDF::Make;

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Markup::Profile - the rules a template runs under

=head1 SYNOPSIS

    my $markup = PDF::Make::Markup::Profile->render($template, $data);

=head1 DESCRIPTION

Templates arrive from whoever holds the account and run here, over data that
frequently came from someone else again. This module is the boundary, and it
is deliberately small enough to read in one sitting.

=head2 Escaping is not optional

Every value a template interpolates is escaped. A customer called
S<C<< Smith & Sons <Ltd> >>> appears as those characters rather than as
broken markup, and a hostile value cannot close an element and open its own.
C<auto_escape> cannot be passed to L</engine>: attempting it is an error
rather than something that quietly wins.

Stencil escapes to C<&amp;>, C<&lt;>, C<&gt;>, C<&quot;> and C<&#39;>, all of
which L<PDF::Make::Markup::Parse> decodes, so the round trip is exact.

=head2 {% raw %} is refused

Stencil's C<< {% raw value %} >> prints a value with no escaping. There is no
way to disable it in the engine, so a template that uses it is rejected
before it compiles, with the line number and the reason. Markup comes from
the template; values come from the data. A template that needs to vary its
structure should do it with C<< {% if %} >> and C<< {% for %} >>, which is
the same expressiveness without handing structure to the payload.

=head2 Filters are a fixed list

Stencil takes filters as Perl coderefs, which is a fine design for an
application and an unacceptable one for a multi-tenant service, so the map is
fixed here and cannot be extended by a caller. C<filters> cannot be passed to
L</engine>.

On top of Stencil's own C<upper>, C<lower>, C<trim>, C<html>, C<uri> and
C<default>, this profile adds C<money> and C<number>. Both are pure functions
of their input. Adding one is a code change and a review, which is the
intended cost.

=head2 Strictness

C<strict> is on: a field the data does not have is an error rather than an
empty space. A silently blank invoice number is worse than a render that
refuses, because only one of them is noticed.

=head2 What this module does not do

It does not bound CPU time. A template that loops for a very long time is
still running inside a C render loop that a Perl C<alarm> will not interrupt,
so the wall-clock limit belongs in the worker that calls this - a process it
can kill - and not here. Saying so plainly is better than a timeout that
looks like protection and is not. The output size cap is enforced, since that
is checkable after the fact.

=head1 SEE ALSO

L<PDF::Make::Markup::Render>, L<Template::Stencil>

=cut
