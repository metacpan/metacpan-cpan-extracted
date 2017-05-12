package MojoX::Renderer::WriteExcel;

use warnings;
use strict;

use Spreadsheet::WriteExcel::Simple;

our $VERSION = '1.0';

# Fry: Why would a robot need to drink?
# Bender: I don't need to drink. I can quit anytime I want!
sub new {
  shift;    # ignore

  return sub {
    my ($r, $c, $output, $options) = @_;

    # don't let MojoX::Renderer to encode output to string
    delete $options->{encoding};

    my $ss       = Spreadsheet::WriteExcel::Simple->new;
    my $heading  = $c->stash->{heading};
    my $result   = $c->stash->{result};
    my $settings = $c->stash->{settings};

    if (ref $heading) {
      $ss->write_bold_row($heading);
    }

    if (ref $settings) {
      $c->render_exception("invalid column width")
        unless defined $settings->{column_width};
      for my $col (keys %{$settings->{column_width}}) {
        $ss->sheet->set_column($col, $settings->{column_width}->{$col});
      }
    }

    foreach my $data (@$result) {
      $ss->write_row($data);
    }

    $$output = $ss->data;

    return 1;
  };
}

=head1 NAME

MojoX::Renderer::WriteExcel - emit Excel spreadsheets from Mojo

=head1 SYNOPSIS

    use MojoX::Renderer::WriteExcel;

    sub startup {
      my $self = shift;

      $self->types->type(xls => 'application/vnd.ms-excel');

      my $self->renderer->add_handler(
          xls => MojoX::Renderer::WriteExcel->new
      );
    }

=head1 DESCRIPTION

This renderer converts the C<result> element in the stash to an Excel
spreadsheet.  If the stash also has a C<heading> element, the renderer
will also write headings in bold type for the columns in the
spreadsheet.

C<heading> is an arrayref, while C<result> is an array of arrayrefs.

Optionally, a C<settings> parameter can be provided to set additional
attributes in the Excel spreadsheet.  Currently 'column_width' is the
only working attribute.  C<settings> is a hashref.  Column widths
could be set by passing the settings to render such as:

   settings => {column_width => {'A:A' => 10, 'B:B' => 25, 'C:D' => 40}}

=head1 METHODS

=head2 new

This method returns a handler for the Mojo renderer.

=cut

=head1 AUTHOR

Zak B. Elep <zakame@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mojox-renderer-writeexcel at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MojoX-Renderer-WriteExcel>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MojoX::Renderer::WriteExcel


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MojoX-Renderer-WriteExcel>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MojoX-Renderer-WriteExcel>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MojoX-Renderer-WriteExcel>

=item * Search CPAN

L<http://search.cpan.org/dist/MojoX-Renderer-WriteExcel/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Graham Barr and his L<MojoX::Renderer::YAML> module, and
Sebastian Riedel's core L<Mojolicious::Plugin::EpRenderer> for showing
how to write renderers for Mojo!

Inspiration for this renderer came from this mailing list thread:
L<http://archives.free.net.ph/thread/20100625.092704.ed777265.en.html>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Zak B. Elep.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of MojoX::Renderer::WriteExcel
