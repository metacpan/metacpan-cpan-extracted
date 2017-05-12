package Net::Google::Spreadsheets::Cell;
use Any::Moose;
use XML::Atom::Util qw(first);

with 'Net::Google::DataAPI::Role::Entry';

has content => (
    isa => 'Str',
    is => 'ro',
);

has row => (
    isa => 'Int',
    is => 'ro',
);

has col => (
    isa => 'Int',
    is => 'ro',
);

has input_value => (
    isa => 'Str',
    is => 'rw',
    trigger => sub {$_[0]->update},
);

after from_atom => sub {
    my ($self) = @_;
    my $elem = first( $self->elem, $self->ns('gs')->{uri}, 'cell');
    $self->{row} = $elem->getAttribute('row');
    $self->{col} = $elem->getAttribute('col');
    $self->{input_value} = $elem->getAttribute('inputValue');
    $self->{content} = $elem->textContent || '';
};

around to_atom => sub {
    my ($next, $self) = @_;
    my $entry = $next->($self);
    $entry->set($self->ns('gs'), 'cell', '',
        {
            row => $self->row,
            col => $self->col,
            inputValue => $self->input_value,
        }
    );
    my $link = XML::Atom::Link->new;
    $link->rel('edit');
    $link->type('application/atom+xml');
    $link->href($self->editurl);
    $entry->link($link);
    $entry->id($self->id);
    return $entry;
};

__PACKAGE__->meta->make_immutable;

no Any::Moose;

1;
__END__

=head1 NAME

Net::Google::Spreadsheets::Cell - A representation class for Google Spreadsheet cell.

=head1 SYNOPSIS

  use Net::Google::Spreadsheets;

  my $service = Net::Google::Spreadsheets->new(
    username => 'mygoogleaccount@example.com',
    password => 'mypassword',
  );

  # get a cell
  my $cell = $service->spreadsheet(
    {
        title => 'list for new year cards',
    }
  )->worksheet(
    {
        title => 'Sheet1',
    }
  )->cell(
    {
        col => 1,
        row => 1,
    }
  );

  # update a cell
  $cell->input_value('new value');

  # get the content of a cell
  my $value = $cell->content;

=head1 ATTRIBUTES

=head2 input_value

Rewritable attribute. You can set formula like '=A1+B1' or so.

=head2 content

Read only attribute. You can get the result of formula.

=head1 SEE ALSO

L<https://developers.google.com/google-apps/spreadsheets/>

L<Net::Google::AuthSub>

L<Net::Google::Spreadsheets>

=head1 AUTHOR

Nobuo Danjou E<lt>danjou@soffritto.orgE<gt>

=cut

