package Net::Presto;
use Moo;
use Furl;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use JSON::XS;

our $VERSION = "0.02";

use Net::Presto::Statement;

has protocol => (
    is => 'ro',
    isa => sub { die "Unsupported protocol: $_[0]" unless $_[0] =~ /\Ahttps?\z/ },
    default => sub { 'http' },
);

has path => (
    is => 'ro',
    default => sub { '/v1/statement' },
);

has server => (
    is => 'ro',
    required => 1,
);

has catalog => (
    is => 'ro',
    required => 1,
);

has schema => (
    is => 'ro',
    required => 1,
);

has user => (
    is => 'ro',
    required => 1,
);

has time_zone => (
    is => 'ro',
);

has language => (
    is => 'ro',
);

has properties => (
    is => 'ro',
    isa => sub { die "properties is not a HashRef" unless ref $_[0] eq 'HASH' },
);

has furl => (
    is => 'ro',
    isa => sub { die "furl is not a Furl object" unless blessed $_[0] && $_[0]->isa('Furl') },
    default => sub {
        my $self = shift;
        Furl->new(
            agent   => $self->source,
            timeout => 180,
        );
    },
);

has source => (
    is => 'ro',
    default => sub { join('/', __PACKAGE__, $VERSION) },
);

sub execute {
    my ($self, $query) = @_;
    confess 'No query specified' unless defined $query;
    my $url = sprintf '%s://%s%s', $self->protocol, $self->server, $self->path;
    my $headers = [
        'X-Presto-User'    => $self->user,
        'X-Presto-Source'  => $self->source,
        'X-Presto-Catalog' => $self->catalog,
        'X-Presto-Schema'  => $self->schema,
        $self->time_zone  ? ('X-Presto-Time-Zone' => $self->time_zone) : (),
        $self->language   ? ('X-Presto-Language'  => $self->language) : (),
        $self->properties ? (
            map {
                ('X-Presto-Session' => join('=', $_, $self->properties->{$_})) # need to validate?
            } keys %{$self->properties}
        ) : (),
    ];
    my $response = $self->furl->post($url, $headers, $query);
    confess $response->status_line unless $response->is_success;
    my $res = decode_json $response->content;
    Net::Presto::Statement->create(
        furl    => $self->furl,
        headers => $headers,
        res     => $res,
    );
}

sub do {
    my ($self, $query) = @_;
    my $st = $self->execute($query);
    $st->wait_for_completion;
    1;
}

sub select_one {
    my ($self, $query) = @_;
    my $st = $self->execute($query);
    my $rows = $st->fetch;
    $st->wait_for_completion;
    $rows->[0]->[0];
}

sub select_row {
    my ($self, $query) = @_;
    my $st = $self->execute($query);
    my $rows = $st->fetch_hashref;
    $st->wait_for_completion;
    $rows->[0];
}

sub select_all {
    my ($self, $query) = @_;
    my $st = $self->execute($query);
    my @rows;
    while (my $rows = $st->fetch_hashref) {
        push @rows, @$rows;
    }
    \@rows;
}

1;
__END__

=encoding utf-8

=head1 NAME

Net::Presto - Presto client library for Perl

=head1 SYNOPSIS

    use Net::Presto;

    my $presto = Net::Presto->new(
        server    => 'localhost:8080',
        catalog   => 'hive',
        schema    => 'mydb',
        user      => 'scott',
        source    => 'myscript',   # defaults to Net::Presto/$VERSION
        time_zone => 'US/Pacific', # optional
        language  => 'English',    # optional
    );

    # easy to use interfaces
    my $rows = $presto->select_all('SELECT * FROM ...');
    my $row = $presto->select_row('SELECT * FROM ... LIMIT 1');
    my $col = $presto->select_one('SELECT COUNT(1) FROM ...');

    $presto->do('CREATE TABLE ...');

    # See Net::Presto::Statament for more details of low level interfaces
    my $sth = $presto->execute('SELECT * FROM ...');
    while (my $rows = $sth->fetch_hashref) {
        for my $row (@$rows) {
            $row->{column_name};
        }
    }

=head1 DESCRIPTION

Presto is a distributed SQL query engine for big data.

L<https://prestodb.io/>

Net::Presto is a client library for Perl to run queries on Presto.

=head1 CONSTRUCTOR

=head2 C<< Net::Presto->new(%options) :Net::Presto >>

Creates and return a new Net::Presto instance with options.

I<%options> might be:

=over

=item server

address[:port] to a Presto coordinator

=item catalog

Catalog (connector) name of Presto such as `hive-cdh4`, `hive-hadoop1`, etc.

=item schema

Default schema name of Presto. You can read other schemas by qualified name like `FROM myschema.table1`.

=item user

User name to connect to a Presto

=item source

Source name to connect to a Presto. This name is shown on Presto web interface.

=item time_zone

Time zone of the query. Time zone affects some functions such as `format_datetime`.

=item language

Language of the query. Language affects some functions such as `format_datetime`.

=item properties

Session properties.

=back

=head1 METHODS

=head2 C<< $presto->select_all($query) :ArrayRef[HashRef[Str]] >>

Shortcut for execute and fetchrow_hashref

=head2 C<< $presto->select_row($query) :HashRef[Str] >>

Shortcut for execute and fetchrow_hashref->[0]

=head2 C<< $presto->select_one($query) :Str >>

Shortcut for execute and fetch->[0]

=head2 C<< $presto->do($query) :Int >>

Execute a single statement.

=head2 C<< $presto->execute($query) :Net::Presto::Statement >>

Execute a statement and returns a L<Net::Presto::Statement> object.

=head1 LICENSE

Copyright (C) Jiro Nishiguchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

=cut
