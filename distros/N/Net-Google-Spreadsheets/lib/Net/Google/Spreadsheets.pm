package Net::Google::Spreadsheets;
use 5.008001;
use Any::Moose;
use Net::Google::DataAPI;
use Net::Google::AuthSub;
use Net::Google::DataAPI::Auth::AuthSub;

our $VERSION = '0.1501';

with 'Net::Google::DataAPI::Role::Service';
has gdata_version => (
    is => 'ro',
    isa => 'Str',
    default => '3.0'
);
has namespaces => (
    is => 'ro',
    isa => 'HashRef',
    default => sub {
        {
            gs => 'http://schemas.google.com/spreadsheets/2006',
            gsx => 'http://schemas.google.com/spreadsheets/2006/extended',
            batch => 'http://schemas.google.com/gdata/batch',
        }
    },
);

has username => (is => 'ro', isa => 'Str');
has password => (is => 'ro', isa => 'Str');
has account_type => (is => 'ro', isa => 'Str', required => 1, default => 'HOSTED_OR_GOOGLE');
has source => (is => 'ro', isa => 'Str', required => 1, default => __PACKAGE__ . '-' . $VERSION);

sub _build_auth {
    my ($self) = @_;
    my $authsub = Net::Google::AuthSub->new(
        source => $self->source,
        service => 'wise',
        account_type => $self->account_type,
    );
    my $res = $authsub->login( $self->username, $self->password );
    unless ($res && $res->is_success) {
        die 'Net::Google::AuthSub login failed';
    }
    return Net::Google::DataAPI::Auth::AuthSub->new(
        authsub => $authsub,
    );
}

feedurl spreadsheet => (
    default => 'https://spreadsheets.google.com/feeds/spreadsheets/private/full',
    entry_class => 'Net::Google::Spreadsheets::Spreadsheet',
    can_add => 0,
);

around spreadsheets => sub {
    my ($next, $self, $args) = @_;
    my @result = $next->($self, $args);
    if (my $key = $args->{key}) {
        @result = grep {$_->key eq $key} @result;
    }
    return @result;
};

sub BUILD {
    my $self = shift;
    $self->auth;
}

__PACKAGE__->meta->make_immutable;

no Any::Moose;
no Net::Google::DataAPI;

1;
__END__

=head1 NAME

Net::Google::Spreadsheets - A Perl module for using Google Spreadsheets API.

=head1 SYNOPSIS

  use Net::Google::Spreadsheets;

  my $service = Net::Google::Spreadsheets->new(
    username => 'mygoogleaccount@example.com',
    password => 'mypassword'
  );

  my @spreadsheets = $service->spreadsheets();

  # find a spreadsheet by key
  my $spreadsheet = $service->spreadsheet(
    {
        key => 'key_of_a_spreasheet'
    }
  );

  # find a spreadsheet by title
  my $spreadsheet_by_title = $service->spreadsheet(
    {
        title => 'list for new year cards'
    }
  );

  # find a worksheet by title
  my $worksheet = $spreadsheet->worksheet(
    {
        title => 'Sheet1'
    }
  );

  # create a worksheet
  my $new_worksheet = $spreadsheet->add_worksheet(
    {
        title => 'Sheet2',
        row_count => 100,
        col_count => 3,
    }
  );

  # update cell by batch request
  $worksheet->batchupdate_cell(
    {row => 1, col => 1, input_value => 'name'},
    {row => 1, col => 2, input_value => 'nick'},
    {row => 1, col => 3, input_value => 'mail'},
    {row => 1, col => 4, input_value => 'age'},
  );

  # get a cell
  my $cell = $worksheet->cell({col => 1, row => 1});

  # update input value of a cell
  $cell->input_value('new value');

  # add a row
  my $new_row = $worksheet->add_row(
    {
        name => 'Nobuo Danjou',
        nick => 'lopnor',
        mail => 'danjou@soffritto.org',
        age  => '33',
    }
  );

  # fetch rows
  my @rows = $worksheet->rows;

  # or fetch rows with query
  
  @rows = $worksheet->rows({sq => 'age > 20'});

  # search a row
  my $row = $worksheet->row({sq => 'name = "Nobuo Danjou"'});

  # update content of a row
  $row->content(
    {
        nick => 'lopnor',
        mail => 'danjou@soffritto.org',
    }
  );

  # delete the row
  $row->delete;

  # delete the worksheet
  $worksheet->delete;

  # create a table
  my $table = $spreadsheet->add_table(
    {
        worksheet => $new_worksheet,
        columns => ['name', 'nick', 'mail address', 'age'],
    }
  );

  # add a record
  my $record = $table->add_record(
    {
        name => 'Nobuo Danjou',
        nick => 'lopnor',
        'mail address' => 'danjou@soffritto.org',
        age  => '33',
    }
  );

  # find a record
  my $found = $table->record(
    {
        sq => '"mail address" = "danjou@soffritto.org"'
    }
  );

  # delete it
  $found->delete;

  # delete table
  $table->delete;

=head1 DESCRIPTION

Net::Google::Spreadsheets is a Perl module for using Google Spreadsheets API.

=head1 METHODS

=head2 new

Creates Google Spreadsheet API client. It takes arguments below:

=over 2

=item * username

Username for Google. This should be full email address format like 'mygoogleaccount@example.com'.

=item * password

Password corresponding to the username.

=item * source

Source string to pass to Net::Google::AuthSub.

=back

=head2 spreadsheets(\%condition)

returns list of Net::Google::Spreadsheets::Spreadsheet objects. Acceptable arguments are:

=over 2

=item * title

title of the spreadsheet.

=item * title-exact

whether title search should match exactly or not.

=item * key

key for the spreadsheet. You can get the key via the URL for the spreadsheet.
http://spreadsheets.google.com/ccc?key=key

=back

=head2 spreadsheet(\%condition)

Returns first item of spreadsheets(\%condition) if available.

=head1 AUTHORIZATIONS

you can optionally pass auth object argument when initializing
Net::Google::Spreadsheets instance.

If you want to use AuthSub mechanism, make Net::Google::DataAPI::Auth::AuthSub
object and path it to the constructor:

  my $authsub = Net::Google::AuthSub->new;
  $authsub->auth(undef, $session_token);

  my $service = Net::Google::Spreadsheet->new(
    auth => $authsub
  );

In OAuth case, like this:

  my $oauth = Net::Google::DataAPI::Auth::OAuth->new(
    consumer_key => 'consumer.example.com',
    consumer_secret => 'mys3cr3t',
    callback => 'http://consumer.example.com/callback',
  );
  $oauth->get_request_token;
  my $url = $oauth->get_authorize_token_url;
  # show the url to the user and get the $verifier value
  $oauth->get_access_token({verifier => $verifier});
  my $service = Net::Google::Spreadsheet->new(
    auth => $oauth
  );

=head1 TESTING

To test this module, you have to prepare as below.

=over 2

=item * create a spreadsheet by hand

Go to L<http://docs.google.com> and create a spreadsheet.

=item * set SPREADSHEET_TITLE environment variable

  export SPREADSHEET_TITLE='my test spreadsheet'

or so.

=item * set username and password for google.com via Config::Pit

install Config::Pit and type 

  ppit set google.com

then some editor comes up and type your username and password like

  ---
  username: myname@gmail.com
  password: foobarbaz

=item * run tests

as always,

  perl Makefile.PL
  make
  make test

=back

=head1 AUTHOR

Nobuo Danjou E<lt>danjou@soffritto.orgE<gt>

=head1 SEE ALSO

L<https://developers.google.com/google-apps/spreadsheets/>

L<Net::Google::AuthSub>

L<Net::Google::DataAPI>

L<Net::OAuth>

L<Net::Google::Spreadsheets::Spreadsheet>

L<Net::Google::Spreadsheets::Worksheet>

L<Net::Google::Spreadsheets::Cell>

L<Net::Google::Spreadsheets::Row>

L<Net::Google::Spreadsheets::Table>

L<Net::Google::Spreadsheets::Record>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
