package Mojolicious::Plugin::ReplyTable;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.11';
$VERSION = eval $VERSION;

use Mojo::Util;

sub register {
  my ($plugin, $app, $config) = @_;
  $plugin->setup_types($app);
  push @{$app->renderer->classes}, __PACKAGE__;
  $app->helper( 'reply.table' => \&_reply_table );
}

sub _reply_table {
  my $c = shift;
  my $default = ref $_[0] ? undef : shift;
  my $data = shift || die 'table data is required';
  my %respond = (
    json => { json => $data },
    html => { template => 'reply_table', 'reply_table.table' => $data },
    csv  => sub { $_[0]->render(text => _to_csv($_[0], $data)) },
    txt  => sub { $_[0]->render(text => _to_txt($_[0], $data)) },
    xls  => sub { $_[0]->render(data => _to_xls($_[0], $data)) },
    xlsx => sub { $_[0]->render(data => _to_xlsx($_[0], $data)) },
    @_
  );
  if ($default) {
    $c->stash(format => $default) unless @{$c->accepts};
  }
  $c->respond_to(%respond);
}

sub _to_csv {
  my ($c, $data) = @_;
  require Text::CSV;
  my $csv_options = $c->stash('reply_table.csv_options') || {};
  $csv_options->{binary} = 1 unless exists $csv_options->{binary};
  my $csv = Text::CSV->new($csv_options)
    or die Text::CSV->error_diag();
  my $string = '';
  for my $row (@$data) {
    $csv->combine(@$row) || die $csv->error_diag;
    $string .= $csv->string . "\n";
  }
  return $string;
}

sub _to_txt {
  my ($c, $data) = @_;
  if (!$c->stash('reply_table.tablify') && eval{ require Text::Table::Tiny; 1 }) {
    return Text::Table::Tiny::table(
      rows => $data,
      header_row    => $c->stash('reply_table.header_row'),
      separate_rows => $c->stash('reply_table.separate_rows'),
    );
  } else {
    return Mojo::Util::tablify($data);
  }
}

sub _to_xls {
  my ($c, $data) = @_;
  unless (eval{ require Spreadsheet::WriteExcel; 1 }) {
    $c->rendered(406);
    return '';
  }
  open my $xfh, '>', \my $fdata or die "Failed to open filehandle: $!";
  my $workbook  = Spreadsheet::WriteExcel->new( $xfh );
  my $worksheet = $workbook->add_worksheet();
  $worksheet->write_col('A1', $data);
  $workbook->close();
  return $fdata;
};

sub _to_xlsx {
  my ($c, $data) = @_;
  unless (eval{ require Excel::Writer::XLSX; 1 }) {
    $c->rendered(406);
    return '';
  }
  open my $xfh, '>', \my $fdata or die "Failed to open filehandle: $!";
  my $workbook  = Excel::Writer::XLSX->new( $xfh );
  my $worksheet = $workbook->add_worksheet();
  $worksheet->write_col('A1', $data);
  $workbook->close();
  return $fdata;
};

sub setup_types {
  my ($plugin, $app) = @_;
  my $types = $app->types;
  $types->type(csv => [qw{text/csv application/csv}]);
  $types->type(xls => [qw{
    application/vnd.ms-excel application/msexcel application/x-msexcel application/x-ms-excel
    application/x-excel application/x-dos_ms_excel application/xls
  }]);
  $types->type(xlsx => ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']);
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::ReplyTable - Easily render rectangular data in many formats using Mojolicious

=head1 SYNOPSIS

  use Mojolicious::Lite;
  plugin 'ReplyTable';

  my $format = [format => [qw(
    txt csv html json
    xls xlsx
  )]];
  any '/table' => $format => sub {
    my $c = shift;
    my $data = [
      [qw/a b c d/],
      [qw/e f g h/],
    ];
    $c->reply->table($data);
  };

  app->start;

=head1 DESCRIPTION

L<Mojolicious::Plugin::ReplyTable> adds the C<< reply->table >> helper which can render a table of data in one of several user-selected formats.
The format is selected by the client via the usual Mojolicious L<Content Negotiation|Mojolicious::Guides::Rendering/"Content negotiation"> mechanisms.

Loading the plugin also sets up several MIME types (using L<Mojolicious::Types>, see L<Mojolicious/types>), and appends the module to the list of rendering classes (See L<Mojolicious/renderer>).

=head1 HELPERS

=head2 reply->table

  $c->reply->table([[...], [...], ... ]]);
  $c->reply->table($default => $data, html => sub { ... });

Renders an arrayref of arrayrefs (the inner arrayref being a row) in one of several formats listed below.
An optional leading argument is used as the default format when one is not otherwise requested.
Optional trailing key-value pairs are merged into the arguments to L<Mojolicious::Controller/respond_to>.

Any additional options, particularly those governing formatting details, are via stash keys prefixed by C<reply_table.>.
Note that the prefix C<reply_table.private.> is reserved for internal use.

The formats currently include:

=head3 csv


Implemented via L<Text::CSV> using the default values with C<binary> enabled.
To override these defaults set the stash key C<reply_table.csv_options> to a hashref containing attributes to pass to Text::CSV.
For example, to create a PSV (pipe delimited) file:

  $c->stash('reply_table.csv_options' => { sep_char => "|" });

See L<Text::CSV/new> for available options.

=head3 html

Implemented via the standard L<Mojolicious> rendering functionality and a template named C<reply_table>.
Setting the stash key C<reply_table.header_row> to a true value will cause the default template to use the first row as header values.
This default template may be overloaded to change the formatting, the table is available to the template via the stash key C<reply_table.table>.

=head3 json

Implemented via the standard L<Mojo::JSON> handling.

=head3 txt

A textual representation of the table.
This format is intended for human consumption and the specific formatting should not be relied upon.

If L<Text::Table::Tiny> is available, it will be used to format the data (can be overridden with C<reply_table.tablify>).
It can be controlled via the stash keys C<reply_table.header_row> and C<reply_table.separate_rows> as noted in that module's documentation.
Otherwise it is generated via L<Mojo::Util::tablify>.

=head3 xls

Binary Microsoft Excel format (for older editions of Excel), provided by optional module L<Spreadsheet::WriteExcel>.
If that module is not installed, the client will receive an error status 406.

=head3 xlsx

XML Microsoft Excel format (for newer editions of Excel), provided by optional module L<Excel::Writer::XLSX>.
If that module is not installed, the client will receive an error status 406.

=head1 METHODS

This module inherits all the methods from L<Mojolicious::Plugin> and implements the following new ones

=head2 register

The typical mechanism of loading a L<Mojolicious::Plugin>.
No pass-in options are currently available.

=head1 FUTURE WORK

Beyond what is mentioned in the specifc formats above, the following work is planned.
If any of it tickles your fancy, pull-requests are always welcome.

=over

=item *

Better tests for generated Excel documents.

=item *

Exposing the formatters so that they can be used directly.

=item *

Add additional formats, like OpenOffice/LibreOffice.
If needed these can be appended via additional handlers to the helper.

=back

=head1 A NOTE ON FORMAT DETECTION

As of L<Mojolicious> version 9.11, format detection is disabled by default.
To enable it you can pass an array reference of C<< [format=>\@formats] >> to the route, where C<@formats> is the supported file extensions.
You may also use the shortcut C< [format => 1] >> to enable detection of any format, though that may change in the future.

As of Mojolicious 9.16 you can inherit these formats from a parent route:

  my $with_formats = $app->routes->any([format => \@formats]);
  $with_formats->get('/data')->to('MyController#my_action');

=head1 SEE ALSO

=over

=item L<Mojolicious>

=item L<https://metacpan.org/pod/Mojolicious::Plugin::WriteExcel>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojolicious-Plugin-ReplyTable>

=head1 SPECIAL THANKS

Pharmetika Software, L<http://pharmetika.com>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 CONTRIBUTORS

=over

Nils Diewald (Akron)

Красимир Беров (kberov)

Ryan Perry

Ilya Chesnokov (ichesnokov)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by L</AUTHOR> and L</CONTRIBUTORS>.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__

@@ reply_table.html.ep
% my $skip = 0;
% my $table = stash 'reply_table.table';
<table>
  % if ($skip = !!stash 'reply_table.header_row') {
    <thead><tr>
      % for my $header (@{$table->[0] || []}) {
        <th><%= $header %></th>
      % }
    </tr></thead>
  % }
  <tbody>
    % for my $row (@$table) {
      % if ($skip) { $skip = 0; next }
      <tr>
        % for my $value (@$row) {
          <td><%= $value %></td>
        % }
      </tr>
    % }
  </tbody>
</table>

