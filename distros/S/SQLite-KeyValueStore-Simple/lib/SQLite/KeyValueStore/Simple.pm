package SQLite::KeyValueStore::Simple;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-18'; # DATE
our $DIST = 'SQLite-KeyValueStore-Simple'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       dump_sqlite_kvstore
                       list_sqlite_kvstore_keys
                       get_sqlite_kvstore_value
                       set_sqlite_kvstore_value
                       check_sqlite_kvstore_key_exists
               );

our $db_schema_spec = {
    latest_v => 1,
    install => [
        'CREATE TABLE kvstore (
             key VARCHAR(255) PRIMARY KEY,
             value BLOB,
             encoding VARCHAR(1) NOT NULL -- r=raw/binary, j=json
         )',
    ],
};

sub _init {
    require DBI;
    require SQL::Schema::Versioned;

    my $args = shift;

    $args->{path} //= do {
        $ENV{HOME} or die "HOME not defined, can't set default for path";
        "$ENV{HOME}/kvstore.db";
    };

    my $dbh = DBI->connect("dbi:SQLite:database=$args->{path}", undef, undef,
                           {RaiseError=>1});

    my $res = SQL::Schema::Versioned::create_or_update_db_schema(
        spec => $db_schema_spec,
        dbh => $dbh,
    );
    return $res unless $res->[0] == 200;
    ($res, $dbh);
}

sub _decode_value {
    my ($value, $encoding) = @_;
    my $decoded;

    if ($encoding eq 'j') {
        require JSON::MaybeXS;
        eval { $decoded = JSON::MaybeXS::decode_json($value) };
        return [500, "Can't decode JSON value: $@"] if $@;
    } elsif ($encoding eq 'r') {
        $decoded = $value;
    } elsif ($encoding eq 'h') {
        $value =~ /([^0-9A-Fa-f])/ and return [400, "Invalid digit '$1' in hexdigit value"];
        length($value) % 2 and return [400, "Odd number of hexdigits"];
        $decoded = pack("H*", $value);
    } elsif ($encoding eq 'b') {
        require MIME::Base64;
        $decoded = MIME::Base64::decode_base64($value);
    } else {
        return [400, "Unknown encoding '$encoding'"];
    }
    [200, "OK (decoded)", $decoded];
}

sub _encode_value {
    my ($value, $encoding) = @_;
    my $encoded;

    if (!defined $encoding) {
        return [200, "OK (unencoded)", $value];
    } elsif ($encoding eq 'j') {
        require JSON::MaybeXS;
        eval { $encoded = JSON::MaybeXS::encode_json($value) };
        return [500, "Can't encode JSON value: $@"] if $@;
    } else {
        return [412, "Can't encode undef/structure to '$encoding', please choose 'j'"]
            if ref $value or !defined($value);
        if ($encoding eq 'r') {
            $encoded = $value;
        } elsif ($encoding eq 'h') {
            $encoded = unpack("H*", $value);
        } elsif ($encoding eq 'b') {
            require MIME::Base64;
            $encoded = MIME::Base64::encode_base64($value);
        } else {
            return [400, "Unknown encoding '$encoding'"];
        }
    }
    [200, "OK (encoded)", $encoded];
}

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'A simple key-value store using SQLite',
    description => <<'_',

This module provides simple key-value store using SQLite as the backend. The
logic is simple; this module just stores the key-value pairs as rows in the
database table. You can implement a SQLite-based key-value yourself, but this
module provides the convenience of getting/setting via a single function call or
a single CLI script invocation.

_
};

our %argspec0_key = (
    key => {
        summary => 'Key name',
        schema => ['str*', max_len=>255],
        req => 1,
        pos => 0,
        cmdline_aliases => {k=>{}},
    },
);

our %argspec1_value = (
    value => {
        summary => 'Value',
        schema => 'str*',
        req => 1,
        pos => 1,
    },
);

our %argspecopt_input_encoding = (
    input_encoding => {
        summary => 'Input encoding',
        schema => ['str*', in=>['r','j','h','b']],
        default => 'r',
        cmdline_aliases => {e=>{}},
        description => <<'_',

Possible values are `r` (raw/binary), `j` (JSON), `h` (hexdigits), `b` (base64).
Note that in the database table, value will be stored as raw or JSON. So `b` and
`h` will be converted to raw first.

_
    },
);

our %argspecopt_output_encoding = (
    output_encoding => {
        summary => 'Output encoding',
        schema => ['str*', in=>['r','j','h','b']],
        cmdline_aliases => {E=>{}},
        description => <<'_',

Possible values are `r` (raw/binary), `j` (JSON), `h` (hexdigits), `b` (base64).
Note that a data structure or undef value must be encoded to JSON. The default
output encoding is `r` (or `j`).

_
    },
);

our %argspecopt_quiet = (
    quiet => {
        schema => ['bool*'],
        cmdline_aliases => {q=>{}},
    },
);

our %argspecs_common = (
    path => {
        summary => 'Database path',
        description => <<'_',

If not specified, will default to $HOME/kvstore.db. If file does not exist, will
be created by DBD::SQLite.

If you want an in-memory database (that will be destroyed after your process
exits), use `:memory:`.

_
        schema => 'filename*',
    },
);

$SPEC{dump_sqlite_kvstore} = {
    v => 1.1,
    summary => 'Dump content of key-value store as hash',
    description => <<'_',
_
    args => {
        %argspecs_common,
    },
};
sub dump_sqlite_kvstore {
    my %args = @_;

    my ($res, $dbh) = _init(\%args);
    return $res unless $res->[0] == 200;

    my %hash;
    my $sth = $dbh->prepare("SELECT key,value,encoding FROM kvstore");
    $sth->execute;
    while (my $row = $sth->fetchrow_arrayref) {
        my $res = _decode_value($row->[1], $row->[2]);
        if ($res->[0] != 200) {
            warn "Key '$row->[0]' cannot be decoded: $res->[0] - $res->[1], skipped";
            next;
        }
        $hash{ $row->[0] } = $res->[2];
    }
    [200, "OK", \%hash];
}

$SPEC{list_sqlite_kvstore_keys} = {
    v => 1.1,
    summary => 'List existing keys in the key-value store',
    description => <<'_',
_
    args => {
        %argspecs_common,
    },
};
sub list_sqlite_kvstore_keys {
    my %args = @_;

    my ($res, $dbh) = _init(\%args);
    return $res unless $res->[0] == 200;

    my @keys;
    my $sth = $dbh->prepare("SELECT key FROM kvstore ORDER BY key");
    $sth->execute;
    while (my $row = $sth->fetchrow_arrayref) {
        push @keys, $row->[0];
    }
    [200, "OK", \@keys];
}

$SPEC{get_sqlite_kvstore_value} = {
    v => 1.1,
    summary => 'Get the current value of a key, will return undef if key does not exist',
    description => <<'_',

CLI will exit non-zero (1) when key does not exist.

_
    args => {
        %argspecs_common,
        %argspec0_key,
        %argspecopt_output_encoding,
    },
};
sub get_sqlite_kvstore_value {
    my %args = @_;

    my ($res, $dbh) = _init(\%args);
    return $res unless $res->[0] == 200;

    my $row = $dbh->selectrow_arrayref("SELECT value,encoding FROM kvstore WHERE key=?", {}, $args{key});
    return [200, "OK", undef, {'cmdline.exit_code'=>1}] unless $row;
    $res = _decode_value(@$row);
    return $res unless $res->[0] == 200;
    _encode_value($res->[2], $args{output_encoding});
}

$SPEC{set_sqlite_kvstore_value} = {
    v => 1.1,
    summary => 'Set the value of a key',
    description => <<'_',

Will automatically create the key if not already exists.

Will return the old value (or `undef` if key previously did not exist).

_
    args => {
        %argspecs_common,
        %argspec0_key,
        %argspec1_value,
        %argspecopt_input_encoding,
        %argspecopt_output_encoding,
        %argspecopt_quiet,
    },
};
sub set_sqlite_kvstore_value {
    my %args = @_;

    my ($res, $dbh) = _init(\%args);
    return $res unless $res->[0] == 200;

    my $oldval;
    $dbh->begin_work;
  WORK: {
      GET_OLD_VAL: {
            my $row = $dbh->selectrow_arrayref("SELECT value,encoding FROM kvstore WHERE key=?", {}, $args{key});
            if ($row) {
                my $dres = _decode_value(@$row);
                do { $res = $dres; last WORK } unless $dres->[0] == 200;
                $oldval = $dres->[2];
            }
        }

      SET_NEW_VAL: {
            my $dres = _decode_value($args{value}, $args{input_encoding} // 'r');
            do { $res = $dres; last WORK } unless $dres->[0] == 200;
            my $newval = $dres->[2];
            my $store_encoding = ref $newval || !defined($newval) ? 'j' : 'r';
            my $eres = _encode_value($newval, $store_encoding);
            my $encoded = $eres->[2];
            $dbh->do("INSERT OR IGNORE INTO kvstore (key,value,encoding) VALUES (?,'','')", {}, $args{key});
            $dbh->do("UPDATE kvstore SET value=?,encoding=? WHERE key=?", {}, $encoded, $store_encoding, $args{key});
        }
    }
    $dbh->commit;
    if ($args{quiet}) {
        [200, "OK"];
    } else {
        _encode_value($oldval, $args{output_encoding});
    }
}

$SPEC{check_sqlite_kvstore_key_exists} = {
    v => 1.1,
    summary => 'Check whether a key exists',
    args => {
        %argspecs_common,
        %argspec0_key,
        %argspecopt_quiet,
    },
};
sub check_sqlite_kvstore_key_exists {
    my %args = @_;

    my ($res, $dbh) = _init(\%args);
    return $res unless $res->[0] == 200;

    my $row = $dbh->selectrow_array("SELECT value FROM kvstore WHERE key=?", {}, $args{key});
    [200, "OK", $row ? 1:0, {
        ($args{quiet} ? ("cmdline.result" => "") : ()),
        "cmdline.exit_code" => $row ? 0:1,
    }];
}

1;
# ABSTRACT: A simple key-value store using SQLite

__END__

=pod

=encoding UTF-8

=head1 NAME

SQLite::KeyValueStore::Simple - A simple key-value store using SQLite

=head1 VERSION

This document describes version 0.002 of SQLite::KeyValueStore::Simple (from Perl distribution SQLite-KeyValueStore-Simple), released on 2021-06-18.

=head1 SYNOPSIS

From Perl:

 use SQLite::KeyValueStore::Simple qw(
     dump_sqlite_kvstore
     list_sqlite_kvstore_keys
     get_sqlite_kvstore_value
     set_sqlite_kvstore_value
     check_sqlite_kvstore_key_exists
 );

 # list existing keys in the store
 my $res;
 $res = list_sqlite_kvstore_keys(); # => [200, "OK", []]

 # set value of a key (automatically create key), returns old value
 $res = set_sqlite_kvstore_value(key=>"foo", value=>"bar"); # => [200, "OK", undef]
 $res = set_sqlite_kvstore_value(key=>"foo", value=>"baz"); # => [200, "OK", "bar"]

 # get value of a key (returns 404 if key does not exist)
 $res = get_sqlite_kvstore_value(key=>"foo"); # => [200, "OK", "baz"]
 $res = get_sqlite_kvstore_value(key=>"qux"); # => [404, "Key does not exist"]

 # check the existence of a key
 $res = check_sqlite_kvstore_key_exists(key=>"foo"); # => [200, "OK", 1]
 $res = check_sqlite_kvstore_key_exists(key=>"qux"); # => [200, "OK", 0]

 # customize the database path
 $res = check_sqlite_kvstore_key_exists(key=>"foo", path=>"/home/ujang/myapp.db"); # => [200, "OK", 0]

From command-line (install L<App::SQLiteKeyValueStoreSimpeUtils>):

 # list existing keys in the store
 % list-sqlite-kvstore-keys

 # set value of a key (returns the old value)
 % set-sqlite-kvstore-value foo bar
 % set-sqlite-kvstore-value foo baz
 bar

 # get value of a key
 % get-sqlite-kvstore-value foo
 baz

 # check existence of a key
 % check-sqlite-kvstore-key-exists foo

=head1 DESCRIPTION


This module provides simple key-value store using SQLite as the backend. The
logic is simple; this module just stores the key-value pairs as rows in the
database table. You can implement a SQLite-based key-value yourself, but this
module provides the convenience of getting/setting via a single function call or
a single CLI script invocation.

=head1 FUNCTIONS


=head2 check_sqlite_kvstore_key_exists

Usage:

 check_sqlite_kvstore_key_exists(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether a key exists.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<key>* => I<str>

Key name.

=item * B<path> => I<filename>

Database path.

If not specified, will default to $HOME/kvstore.db. If file does not exist, will
be created by DBD::SQLite.

If you want an in-memory database (that will be destroyed after your process
exits), use C<:memory:>.

=item * B<quiet> => I<bool>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 dump_sqlite_kvstore

Usage:

 dump_sqlite_kvstore(%args) -> [$status_code, $reason, $payload, \%result_meta]

Dump content of key-value store as hash.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<path> => I<filename>

Database path.

If not specified, will default to $HOME/kvstore.db. If file does not exist, will
be created by DBD::SQLite.

If you want an in-memory database (that will be destroyed after your process
exits), use C<:memory:>.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 get_sqlite_kvstore_value

Usage:

 get_sqlite_kvstore_value(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get the current value of a key, will return undef if key does not exist.

CLI will exit non-zero (1) when key does not exist.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<key>* => I<str>

Key name.

=item * B<output_encoding> => I<str>

Output encoding.

Possible values are C<r> (raw/binary), C<j> (JSON), C<h> (hexdigits), C<b> (base64).
Note that a data structure or undef value must be encoded to JSON. The default
output encoding is C<r> (or C<j>).

=item * B<path> => I<filename>

Database path.

If not specified, will default to $HOME/kvstore.db. If file does not exist, will
be created by DBD::SQLite.

If you want an in-memory database (that will be destroyed after your process
exits), use C<:memory:>.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_sqlite_kvstore_keys

Usage:

 list_sqlite_kvstore_keys(%args) -> [$status_code, $reason, $payload, \%result_meta]

List existing keys in the key-value store.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<path> => I<filename>

Database path.

If not specified, will default to $HOME/kvstore.db. If file does not exist, will
be created by DBD::SQLite.

If you want an in-memory database (that will be destroyed after your process
exits), use C<:memory:>.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 set_sqlite_kvstore_value

Usage:

 set_sqlite_kvstore_value(%args) -> [$status_code, $reason, $payload, \%result_meta]

Set the value of a key.

Will automatically create the key if not already exists.

Will return the old value (or C<undef> if key previously did not exist).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input_encoding> => I<str> (default: "r")

Input encoding.

Possible values are C<r> (raw/binary), C<j> (JSON), C<h> (hexdigits), C<b> (base64).
Note that in the database table, value will be stored as raw or JSON. So C<b> and
C<h> will be converted to raw first.

=item * B<key>* => I<str>

Key name.

=item * B<output_encoding> => I<str>

Output encoding.

Possible values are C<r> (raw/binary), C<j> (JSON), C<h> (hexdigits), C<b> (base64).
Note that a data structure or undef value must be encoded to JSON. The default
output encoding is C<r> (or C<j>).

=item * B<path> => I<filename>

Database path.

If not specified, will default to $HOME/kvstore.db. If file does not exist, will
be created by DBD::SQLite.

If you want an in-memory database (that will be destroyed after your process
exits), use C<:memory:>.

=item * B<quiet> => I<bool>

=item * B<value>* => I<str>

Value.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SQLite-KeyValueStore-Simple>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SQLite-KeyValueStore-Simple>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SQLite-KeyValueStore-Simple>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<SQLite::Counter::Simple>

Some other key-value stores: the various C<DBM::*> (see L<GDBM_File> or
L<AnyDBM_File>), Riak (see L<Data::Riak>), Redis (see L<Redis> or
L<Mojo::Redis>).

Some other key-value store frameworks: L<CHI>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
