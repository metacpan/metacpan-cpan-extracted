package Net::Google::Spreadsheets::Row;
use Any::Moose;
use Net::Google::DataAPI;
use XML::Atom::Util qw(nodelist);

with 
    'Net::Google::DataAPI::Role::Entry',
    'Net::Google::DataAPI::Role::HasContent';

after from_atom => sub {
    my ($self) = @_;
    for my $node (nodelist($self->elem, $self->ns('gsx')->{uri}, '*')) {
        $self->content->{$node->localname} = $node->textContent;
    }
};

around to_atom => sub {
    my ($next, $self) = @_;
    my $entry = $next->($self);
    while (my ($key, $value) = each %{$self->content}) {
        $entry->set($self->ns('gsx'), $key, $value);
    }
    return $entry;
};

__PACKAGE__->meta->make_immutable;

no Any::Moose;
no Net::Google::DataAPI;

1;
__END__

=head1 NAME

Net::Google::Spreadsheets::Row - A representation class for Google Spreadsheet row.

=head1 SYNOPSIS

  use Net::Google::Spreadsheets;

  my $service = Net::Google::Spreadsheets->new(
    username => 'mygoogleaccount@example.com',
    password => 'mypassword',
  );

  # get a row
  my $row = $service->spreadsheet(
    {
        title => 'list for new year cards',
    }
  )->worksheet(
    {
        title => 'Sheet1',
    }
  )->row(
    {
        sq => 'id = 1000'
    }
  );

  # get the content of a row
  my $hashref = $row->content;
  my $id = $hashref->{id};
  my $address = $hashref->{address};

  # update a row
  $row->content(
    {
        id => 1000,
        address => 'somewhere',
        zip => '100-0001',
        name => 'Nobuo Danjou',
    }
  );

  # get and set values partially
  
  my $value = $row->param('name');
  # returns 'Nobuo Danjou'

  # it's same by getting via param method without args, or content method:
  my $value_by_param = $row->param->{name};
  my $value_by_content = $row->content->{name};
  
  my $newval = $row->param({address => 'elsewhere'});
  # updates address (and keeps other fields) and returns new row value (with all fields)

  my $hashref2 = $row->param;
  # same as $row->content;

  # delete the row
  $row->delete;

=head1 METHODS

=head2 param

sets and gets content value.

=head2 delete

deletes the row.

=head1 CAVEATS

Space characters in hash key of rows will be removed when you access rows. See below.

  my $ws = Net::Google::Spreadsheets->new(
    username => 'me@gmail.com', 
    password => 'foobar'
  )->spreadsheet({titile => 'sample'})->worksheet(1);
  $ws->batchupdate_cell(
    {col => 1,row => 1, input_value => 'name'},
    {col => 2,row => 1, input_value => 'mail address'},
  ); 
  $ws->add_row(
    {
        name => 'my name',
        mailaddress => 'me@gmail.com',
  #      above passes, below fails.
  #      'mail address' => 'me@gmail.com',
    }
  );

Instead, Net::Google::Spreadsheets::Table and Net::Google::Spreadsheets::Record allows 
space characters in column name. 

  my $s = Net::Google::Spreadsheets->new(
    username => 'me@gmail.com', 
    password => 'foobar'
  )->spreadsheet({titile => 'sample'});

  my $t = $s->add_table(
    {
        worksheet => $s->worksheet(1),
        columns => ['name', 'mail address'],
    }
  );
  $t->add_record(
    {
        name => 'my name',
        'mail address' => 'me@gmail.com',
    }
  );

=head1 ATTRIBUTES

=head2 content

Rewritable attribute. You can get and set the value. 
So it's the same thing to get the value with param method or content attribute.

  my $value = $row->param('foo');
  # it's same
  my $value2 = $row->content->{'foo'};

=head1 SEE ALSO

L<https://developers.google.com/google-apps/spreadsheets/>

L<Net::Google::AuthSub>

L<Net::Google::Spreadsheets>

=head1 AUTHOR

Nobuo Danjou E<lt>danjou@soffritto.orgE<gt>

=cut

