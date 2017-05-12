package Net::Google::Spreadsheets::Worksheet;
use Any::Moose;
use Net::Google::DataAPI;

with 'Net::Google::DataAPI::Role::Entry';

use Carp;
use Net::Google::Spreadsheets::Cell;
use XML::Atom::Util qw(first);

feedurl row => (
    entry_class => 'Net::Google::Spreadsheets::Row',
    as_content_src => 1,
    arg_builder => sub {
        my ($self, $args) = @_;
        return {content => $args};
    },
);

feedurl cell => (
    entry_class => 'Net::Google::Spreadsheets::Cell',
    can_add => 0,
    rel => 'http://schemas.google.com/spreadsheets/2006#cellsfeed',
    query_builder => sub {
        my ($self, $args) = @_;
        if (my $col = delete $args->{col}) {
            $args->{'max-col'} = $col;
            $args->{'min-col'} = $col;
            $args->{'return-empty'} = 'true';
        }
        if (my $row = delete $args->{row}) {
            $args->{'max-row'} = $row;
            $args->{'min-row'} = $row;
            $args->{'return-empty'} = 'true';
        }
        return $args;
    },

);

entry_has row_count => (
    isa => 'Int',
    is => 'rw',
    default => 100,
    tagname => 'rowCount',
    ns => 'gs',
);

entry_has col_count => (
    isa => 'Int',
    is => 'rw',
    default => 20,
    tagname => 'colCount',
    ns => 'gs',
);

__PACKAGE__->meta->make_immutable;

sub batchupdate_cell {
    my ($self, @args) = @_;
    my $feed = XML::Atom::Feed->new;
    for ( @args ) {
        my $id = sprintf("%s/R%sC%s",$self->cell_feedurl, $_->{row}, $_->{col});
        $_->{id} = $_->{editurl} = $id;
        $_->{container} = $self,
        my $entry = Net::Google::Spreadsheets::Cell->new($_)->to_atom;
        $entry->set($self->ns('batch'), operation => '', {type => 'update'});
        $entry->set($self->ns('batch'), id => $id);
        $feed->add_entry($entry);
    }
    my $res_feed = $self->service->post(
        $self->cell_feedurl."/batch", 
        $feed, 
        {'If-Match' => '*'}
    );
    $self->sync;
    return map {
        Net::Google::Spreadsheets::Cell->new(
            atom => $_,
            container => $self,
        )
    } grep {
        my $node = first(
            $_->elem, $self->ns('batch')->{uri}, 'status'
        );
        $node->getAttribute('code') == 200;
    } $res_feed->entries;
}

no Any::Moose;
no Net::Google::DataAPI;

1;
__END__

=head1 NAME

Net::Google::Spreadsheets::Worksheet - Representation of worksheet.

=head1 SYNOPSIS

  my $service = Net::Google::Spreadsheets->new(
    username => 'mygoogleaccount@example.com',
    password => 'mypassword',
  );

  my $ss = $service->spreadsheet(
    {
        key => 'key_of_a_spreasheet'
    }
  );

  my $worksheet = $ss->worksheet({title => 'Sheet1'});

  # update cell by batch request
  $worksheet->batchupdate_cell(
    {col => 1, row => 1, input_value => 'name'},
    {col => 2, row => 1, input_value => 'nick'},
    {col => 3, row => 1, input_value => 'mail'},
    {col => 4, row => 1, input_value => 'age'},
  );

  # get a cell object
  my $cell = $worksheet->cell({col => 1, row => 1});

  # add a row
  my $new_row = $worksheet->add_row(
    {
        name => 'Nobuo Danjou',
        nick => 'lopnor',
        mail => 'danjou@soffritto.org',
        age  => '33',
    }
  );

  # get rows
  my @rows = $worksheet->rows;

  # search rows
  @rows = $worksheet->rows({sq => 'age > 20'});

  # search a row
  my $row = $worksheet->row({sq => 'name = "Nobuo Danjou"'});

  # delete the worksheet
  # Note that this will fail if the worksheet is the only one
  # within the spreadsheet.

  $worksheet->delete;

=head1 METHODS

=head2 rows(\%condition)

Returns a list of Net::Google::Spreadsheets::Row objects. Acceptable arguments are:

=over 2

=item * sq

Structured query on the full text in the worksheet. see the URL below for detail.

=item * orderby

Set column name to use for ordering.

=item * reverse

Set 'true' or 'false'. The default is 'false'.

=back

See L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/reference.html#ListParameters> for details.
Note that 'the first row of the worksheet' you can see with the browser is 'header' for the rows, so you can't get it with this method. Use cell(s) method instead if you need to access them.

=head2 row(\%condition)

Returns first item of rows(\%condition) if available.

=head2 add_row(\%contents)

Creates new row and returns a Net::Google::Spreadsheets::Row object representing it. Arguments are
contents of a row as a hashref.

  my $row = $ws->add_row(
    {
        name => 'Nobuo Danjou',
        nick => 'lopnor',
        mail => 'danjou@soffritto.org',
        age  => '33',
    }
  );

=head2 cells(\%args)

Returns a list of Net::Google::Spreadsheets::Cell objects. Acceptable arguments are:

=over 2

=item * min-row

=item * max-row

=item * min-col

=item * max-col

=item * range

=item * return-empty

=back

See L<http://code.google.com/intl/en/apis/spreadsheets/docs/3.0/reference.html#CellParameters> for details.

=head2 cell(\%args)

Returns Net::Google::Spreadsheets::Cell object. Arguments are:

=over 2

=item * col

=item * row

=back

=head2 batchupdate_cell(@args)

update multiple cells with a batch request. Pass a list of hash references containing:

=over 2

=item * col

=item * row

=item * input_value

=back

=head2 delete

Deletes the worksheet. Note that this will fail if the worksheet is only one within the spreadsheet.

=head1 SEE ALSO

L<https://developers.google.com/google-apps/spreadsheets/>

L<Net::Google::AuthSub>

L<Net::Google::Spreadsheets>

=head1 AUTHOR

Nobuo Danjou E<lt>danjou@soffritto.orgE<gt>

=cut
