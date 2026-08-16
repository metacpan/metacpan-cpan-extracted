package PDF::Make::Markup::Render;
use strict;
use warnings;

our $VERSION = '0.10';

# No logic lives here. The engine-version gate and the three-stage chain -
# profile, parse, build - are in xs/markup_render.xs. The build stage is the
# one part still written in Perl, because it drives PDF::Make::Builder; when
# that becomes a C document compiler, only the XS changes.
require PDF::Make;
require PDF::Make::Markup::Profile;
require PDF::Make::Markup::Parse;
require PDF::Make::Markup::Build;

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Markup::Render - template and data in, PDF out

=head1 SYNOPSIS

    use PDF::Make::Markup::Render;

    my $pdf = PDF::Make::Markup::Render->render(<<'TPL', $data);
    <doc page-size="A4" margin="36">
      <h1>Invoice {% invoice.number %}</h1>
      <text>Amount due: <b>{% invoice.total | money %}</b></text>
      <table>
        {% for l in invoice.lines %}
        <tr><td>{% l.name %}</td><td align="right">{% l.qty %}</td></tr>
        {% end %}
      </table>
    </doc>
    TPL

=head1 DESCRIPTION

Three stages, in one place:

=over 4

=item 1.

L<PDF::Make::Markup::Profile> runs the template. Values are escaped, the
filter list is fixed, and C<< {% raw %} >> is refused.

=item 2.

L<PDF::Make::Markup::Parse> parses the markup that came out. Anything outside
the grammar is an error with a line and a column.

=item 3.

L<PDF::Make::Markup::Build> compiles the tree onto L<PDF::Make::Builder>.

=back

=head2 Reproducibility

Set C<SOURCE_DATE_EPOCH> and two renders of the same template and data
produce identical bytes. Without it the output carries the wall clock, and
nothing downstream - a golden corpus, a diff of one engine version against
the next - can be checked.

=head2 Engine versions

C<engine_version> selects the layout engine. There is one, and a template may
pin it. Asking for a version this build does not have is an error that says
whether the template is from the future or the past, rather than quietly
rendering with something else.

=head1 SEE ALSO

L<PDF::Make::Markup::Profile>, L<PDF::Make::Markup::Parse>,
L<PDF::Make::Markup::Build>

=cut
