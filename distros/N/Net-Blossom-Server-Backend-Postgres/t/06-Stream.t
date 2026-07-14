use strictures 2;

use Test::More;

use Net::Blossom::Server::Backend::Postgres;

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

{
    package Local::StreamDBH;
    use strictures 2;

    sub new {
        my ($class, %args) = @_;
        return bless {
            data   => defined $args{data} ? $args{data} : '',
            offset => 0,
            %args,
        }, $class;
    }

    sub pg_lo_read {
        my ($self, undef, undef, $length) = @_;
        die "read failed\n" if $self->{read_error};
        $_[2] = substr($self->{data}, $self->{offset}, $length);
        $self->{offset} += length $_[2];
        return length $_[2];
    }

    sub pg_lo_close {
        my ($self) = @_;
        $self->{large_object_closed}++;
        die "close failed\n" if $self->{close_error};
        return 1;
    }

    sub commit {
        my ($self) = @_;
        $self->{committed}++;
        die "commit failed\n" if $self->{commit_error};
        return 1;
    }

    sub rollback {
        my ($self) = @_;
        $self->{rolled_back}++;
        return 1;
    }

    sub disconnect {
        my ($self) = @_;
        $self->{disconnected}++;
        return 1;
    }
}

sub stream {
    my ($dbh) = @_;
    return Net::Blossom::Server::Backend::Postgres::BlobStore::_Stream->new(
        dbh => $dbh,
        fd  => 7,
    );
}

subtest 'getline reaches EOF and commits the read transaction' => sub {
    my $first = 'x' x 65536;
    my $dbh = Local::StreamDBH->new(data => $first . 'tail');
    my $stream = stream($dbh);

    is($stream->getline, $first, 'getline returns one bounded chunk');
    is($stream->getline, 'tail', 'getline returns the final chunk');
    is($stream->getline, undef, 'getline returns undef at EOF');
    is($stream->getline, undef, 'getline remains at EOF');
    my $buffer = 'stale';
    is($stream->read($buffer, 1), 0, 'read remains at EOF');
    is($buffer, '', 'read at EOF clears the output buffer');
    is($dbh->{large_object_closed}, 1, 'EOF closes the large object once');
    is($dbh->{committed}, 1, 'EOF commits the read transaction');
    is($dbh->{disconnected}, 1, 'EOF disconnects the reader');
};

subtest 'zero-length read leaves the stream open' => sub {
    my $dbh = Local::StreamDBH->new(data => 'body');
    my $stream = stream($dbh);
    my $chunk = 'unchanged';

    is($stream->read($chunk, 0), 0, 'zero-length read returns zero');
    is($chunk, '', 'zero-length read clears the output buffer');
    ok(!$dbh->{large_object_closed}, 'zero-length read does not close the stream');
    ok($stream->close, 'stream closes normally afterwards');
    is($dbh->{committed}, 1, 'explicit close commits the read transaction');
};

subtest 'read failure rolls back and disconnects' => sub {
    my $dbh = Local::StreamDBH->new(read_error => 1);
    my $stream = stream($dbh);
    my $chunk = '';

    like(dies { $stream->read($chunk, 10) }, qr/read failed/, 'read error is preserved');
    is($dbh->{large_object_closed}, 1, 'read failure closes the large object');
    is($dbh->{rolled_back}, 1, 'read failure rolls back the transaction');
    ok(!$dbh->{committed}, 'read failure does not commit');
    is($dbh->{disconnected}, 1, 'read failure disconnects the reader');
};

subtest 'large-object close failure rolls back instead of committing' => sub {
    my $dbh = Local::StreamDBH->new(close_error => 1);
    my $stream = stream($dbh);

    like(dies { $stream->close }, qr/close failed/, 'large-object close error is preserved');
    is($dbh->{rolled_back}, 1, 'close failure rolls back the transaction');
    ok(!$dbh->{committed}, 'close failure does not commit');
    is($dbh->{disconnected}, 1, 'close failure disconnects the reader');
};

subtest 'transaction commit failure attempts rollback' => sub {
    my $dbh = Local::StreamDBH->new(commit_error => 1);
    my $stream = stream($dbh);

    like(dies { $stream->close }, qr/commit failed/, 'commit error is preserved');
    is($dbh->{rolled_back}, 1, 'commit failure attempts rollback');
    is($dbh->{disconnected}, 1, 'commit failure disconnects the reader');
};

done_testing;
