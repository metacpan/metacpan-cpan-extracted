package Net::Presto::Statement;
use Moo;
use JSON::XS;
use Carp qw(confess);

use constant DEBUG => $ENV{PERL_PRESTO_DEBUG} ? 1 : 0;

has furl => (
    is => 'ro',
    required => 1,
);

has headers => (
    is => 'ro',
    required => 1,
);

has res => (
    is => 'rw',
    required => 1,
);

has columns => (
    is => 'rw',
);

has stats => (
    is => 'rw',
);

has state => (
    is => 'rw',
);

has error => (
    is => 'rw',
);

sub create {
    my $class = shift;
    my $self = $class->new(@_);
    $self->_set_state($self->res);
    $self;
}

sub fetch {
    my $self = shift;
    my $data;
    $self->poll(sub {
        return 1 unless $_[0]->{data};
        $data = $_[0]->{data};
        return 0;
    });
    $data;
}

sub fetch_hashref {
    my $self = shift;
    my $data = $self->fetch or return;
    my @names = $self->column_names;
    my @rows;
    for my $row (@$data) {
        my %row;
        @row{@names} = @$row;
        push @rows, \%row;
    }
    \@rows;
}

sub column_names {
    my $self = shift;
    my $columns = $self->columns or return;
    map { $_->{name} } @$columns;
}

sub poll {
    my ($self, $cb) = @_;
    until ($self->state eq 'FINISHED') {
        my $url = $self->res->{nextUri} or return;
        my $res = $self->_request(get => $url);
        my @ret = $cb->($res) if $cb;
        last if @ret && !$ret[0];
    }
    return;
}

sub wait_for_completion {
    my $self = shift;
    $self->poll;
    return;
}

sub cancel {
    my $self = shift;
    my $url = $self->res->{nextUri} or return;
    $self->_request(delete => $url);
    1;
}

sub _request {
    my ($self, $method, $url) = @_;
    my $response = $self->furl->$method($url, $self->headers);
    confess $response->status_line unless $response->is_success;
    warn "$method $url " . $response->content || '' if DEBUG;
    if ($response->content) {
        my $res = decode_json $response->content;
        $self->_set_state($res);
        return $res;
    } else {
        $self->_set_state({});
        return;
    }
}

sub _set_state {
    my ($self, $res) = @_;
    $self->columns($res->{columns} || []);
    $self->stats($res->{stats} || {});
    $self->state($res->{stats}->{state} || '');
    $self->error($res->{error});
    $self->res($res);
    if ($self->error) {
        confess 'ERROR ' . $self->error->{errorCode} . ': ' . $self->error->{message};
    }
    return;
}

sub DESTROY {
    my $self = shift;
    unless ($self->state eq 'FINISHED') {
        eval { $self->cancel };
        if ($@) {
            warn "Error at Net::Presto::Statement::DESTROY: $@";
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Net::Presto::Statement - Presto client statement object

=head1 SYNOPSIS

    use Net::Presto;

    my $presto = Net::Presto->new(...);
    my $sth = $presto->execute('SELECT * FROM ...');
    while (my $rows = $sth->fetch) {
        my @column_names = $sth->column_names;
        for my $row (@$rows) {
            my @columns = @$row; # ArrayRef
        }
    }
    while (my $rows = $sth->fetch_hashref) {
        for my $row (@$rows) {
            $row->{column_name}; # HashRef
        }
    }

    $sth->cancel; # cancel the statement

    # do callback on each requests
    $sth->poll(sub {
        my $res = shift;
        my $data = $res->{data};
        my $stats = $res->{stats};
        # stop polling by return false
        return 0 if $stats->{status} eq 'FINISHED';
        1; # continue
    });

=head1 DESCRIPTION

Net::Presto statement handler object.

=head1 METHODS

=head2 C<< $sth->fetch() :ArrayRef[ArrayRef[Str]] >>

Fetch next data as ArrayRef.

=head2 C<< $sth->fetch_hashref() :ArrayRef[HashRef[Str]] >>

Fetch next data as HashRef.

=head2 C<< $sth->columns() :ArrayRef[HashRef[Str]] >>

Returns column data.

=head2 C<< $sth->columns_names() :(Str,...) >>

Returns column names.

=head2 C<< $sth->cancel() :Bool >>

Cancel the query.

=head2 C<< $sth->wait_for_completion() :Void >>

Wait until the query is completed.

=head2 C<< $sth->poll($callback) :Void >>

Do I<$callback> on each HTTP requests.

=head1 SEE ALSO

L<Net::Presto>

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

=cut
