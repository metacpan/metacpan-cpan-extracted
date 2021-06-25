package SQLite::Counter::Simple;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-21'; # DATE
our $DIST = 'SQLite-Counter-Simple'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $db_schema_spec = {
    latest_v => 1,
    install => [
        'CREATE TABLE counter (name VARCHAR(255) PRIMARY KEY, value INT)',
    ],
};

sub _init {
    require DBI;
    require SQL::Schema::Versioned;

    my $args = shift;

    $args->{counter} //= "default";

    $args->{path} //= do {
        $ENV{HOME} or die "HOME not defined, can't set default for path";
        "$ENV{HOME}/counter.db";
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

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'A simple counter using SQLite',
    description => <<'_',

This module provides simple counter using SQLite as the storage. The logic is
simple; this module just uses row of a table to store a counter. You can
implement this yourself, but this module provides the convenience of
incrementing or getting the value of a counter using a single function call or
a single CLI script invocation.

_
};

our %argspecs_common = (
    path => {
        summary => 'Database path',
        description => <<'_',

If not specified, will default to $HOME/counter.db. If file does not exist, will
be created by DBD::SQLite.

If you want an in-memory database (that will be destroyed after your process
exits), use `:memory:`.

_
        schema => 'filename*',
        pos => 1,
    },
);

our %argspec_counter = (
    counter => {
        summary => 'Counter name, defaults to "default" if not specified',
        schema => 'str*',
        pos => 0,
    },
);

sub _increment {
    my ($dbh, $counter, $increment, $dry_run) = @_;

    $increment //= 1;

    $dbh->begin_work;
    # XXX use prepared statement for speed
    $dbh->do("INSERT OR IGNORE INTO counter (name,value) VALUES (?,?)", {}, $counter, 0);
    my ($val) = $dbh->selectrow_array("SELECT value FROM counter WHERE name=?", {}, $counter);
    return [500, "Cannot create counter '$counter' (1)"] unless defined $val;
    $val += $increment;
    unless ($dry_run) {
        $dbh->do("UPDATE counter SET value=? WHERE name=?", {}, $val, $counter);
    }
    $dbh->commit;
    [200, "OK", $val];
}

$SPEC{increment_sqlite_counter} = {
    v => 1.1,
    summary => 'Increment a counter in a SQLite database and return the new incremented value',
    description => <<'_',

The first time a counter is created, it will be set to 0 then incremented to 1,
and 1 will be returned. The next increment will increment the counter to two and
return it.

If dry-run mode is chosen, the value that is returned is the value had the
counter been incremented, but the counter will not be actually incremented.

_
    args => {
        %argspecs_common,
        %argspec_counter,
        increment => {
            summary => 'Specify by how many should the counter be incremented',
            schema => 'int*',
            default => 1,
            cmdline_aliases => {i=>{}},
        },
    },
    features => {
        dry_run => 1,
    },
};
sub increment_sqlite_counter {
    my %args = @_;

    my ($res, $dbh) = _init(\%args);
    return $res unless $res->[0] == 200;

    _increment($dbh, $args{counter}, $args{increment}, $args{-dry_run});
}

$SPEC{dump_sqlite_counters} = {
    v => 1.1,
    summary => 'Return all the counters in a SQLite database as a hash',
    description => <<'_',
_
    args => {
        %argspecs_common,
    },
    features => {
        dry_run => 1,
    },
};
sub dump_sqlite_counters {
    my %args = @_;

    my ($res, $dbh) = _init(\%args);
    return $res unless $res->[0] == 200;

    my $sth = $dbh->prepare("SELECT name,value FROM counter");
    $sth->execute;
    my %counters;
    while (my $row = $sth->fetchrow_hashref) {
        $counters{$row->{name}} = $row->{value};
    }
    [200, "OK", \%counters];
}

$SPEC{get_sqlite_counter} = {
    v => 1.1,
    summary => 'Get the current value of a counter in a SQLite database',
    description => <<'_',

Undef (exit code 1 in CLI) can be returned if counter does not exist.

_
    args => {
        %argspecs_common,
        %argspec_counter,
    },
    features => {
        dry_run => 1,
    },
};
sub get_sqlite_counter {
    my %args = @_;

    my ($res, $dbh) = _init(\%args);
    return $res unless $res->[0] == 200;

    my ($val) = $dbh->selectrow_array("SELECT value FROM counter WHERE name=?", {}, $args{counter});
    [200, "OK", $val, {'cmdline.exit_code'=>defined $val ? 0:1}];
}

sub new {
    my ($class, %args) = @_;

    my ($res, $dbh) = _init(\%args);
    die "Can't initialize: $res->[0] - $res->[1]" unless $res->[0] == 200;

    my $obj = {
        path => delete $args{path},
        dbh  => $dbh,
    };

    delete $args{counter};
    keys(%args) and die "Unknown constructor argument(s): ".join(", ", sort keys %args);
    bless $obj, $class;
}

sub increment {
    my ($self, %args) = @_;

    my $counter = delete($args{counter}) // 'default';
    my $increment = delete($args{increment});
    keys(%args) and die "Unknown argument(s): ".join(", ", sort keys %args);
    my $res = _increment($self->{dbh}, $counter, $increment); # doesn't support dry-run
    die "Can't increment counter '$counter': $res->[0] - $res->[1]"
        unless $res->[0] == 200;
    $res->[2];
}

sub get {
    my ($self, %args) = @_;

    my $counter = delete($args{counter}) // 'default';
    keys(%args) and die "Unknown argument(s): ".join(", ", sort keys %args);
    my ($val) = $self->{dbh}->selectrow_array("SELECT value FROM counter WHERE name=?", {}, $counter);
    $val;
}


1;
# ABSTRACT: A simple counter using SQLite

__END__

=pod

=encoding UTF-8

=head1 NAME

SQLite::Counter::Simple - A simple counter using SQLite

=head1 VERSION

This document describes version 0.003 of SQLite::Counter::Simple (from Perl distribution SQLite-Counter-Simple), released on 2021-06-21.

=head1 SYNOPSIS

From Perl:

 use SQLite::Counter::Simple qw(increment_sqlite_counter get_sqlite_counter);

 # increment and get the dafault counter
 my $res;
 $res = increment_sqlite_counter(); # => [200, "OK", 1]
 $res = increment_sqlite_counter(); # => [200, "OK", 2]

 # dry-run mode
 $res = increment_sqlite_counter(-dry_run=>1); # => [200, "OK (dry-run)", 3]
 $res = increment_sqlite_counter(-dry_run=>1); # => [200, "OK (dry-run)", 3]

 # specify database path and counter name, and also the increment
 $res = increment_sqlite_counter(path=>"/home/ujang/myapp.db", counter=>"counter1"); # => [200, "OK", 1]
 $res = increment_sqlite_counter(path=>"/home/ujang/myapp.db", counter=>"counter1", increment=>10); # => [200, "OK", 11]

 # get the current value of counter
 $res = get_sqlite_counter();               # => [200, "OK", 3, {'cmdline.exit_code'=>0}]
 $res = get_sqlite_counter(counter=>'foo'); # => [200, "OK", undef, {'cmdline.exit_code'=>1}]

From command-line (install L<App::SQLiteCounterSimpeUtils>):

 # increment the dafault counter
 % increment-sqlite-counter
 1
 % increment-sqlite-counter
 2

 # dry-run mode
 % increment-sqlite-counter --dry-run
 3
 % increment-sqlite-counter --dry-run
 3

 # specify database path and counter name, and also the increment
 % increment-sqlite-counter ~/myapp.db counter1
 1
 % increment-sqlite-counter ~/myapp.db counter1 -i 10
 11

=head1 DESCRIPTION


This module provides simple counter using SQLite as the storage. The logic is
simple; this module just uses row of a table to store a counter. You can
implement this yourself, but this module provides the convenience of
incrementing or getting the value of a counter using a single function call or
a single CLI script invocation.

=head1 FUNCTIONS


=head2 dump_sqlite_counters

Usage:

 dump_sqlite_counters(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return all the counters in a SQLite database as a hash.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<path> => I<filename>

Database path.

If not specified, will default to $HOME/counter.db. If file does not exist, will
be created by DBD::SQLite.

If you want an in-memory database (that will be destroyed after your process
exits), use C<:memory:>.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 get_sqlite_counter

Usage:

 get_sqlite_counter(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get the current value of a counter in a SQLite database.

Undef (exit code 1 in CLI) can be returned if counter does not exist.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<counter> => I<str>

Counter name, defaults to "default" if not specified.

=item * B<path> => I<filename>

Database path.

If not specified, will default to $HOME/counter.db. If file does not exist, will
be created by DBD::SQLite.

If you want an in-memory database (that will be destroyed after your process
exits), use C<:memory:>.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 increment_sqlite_counter

Usage:

 increment_sqlite_counter(%args) -> [$status_code, $reason, $payload, \%result_meta]

Increment a counter in a SQLite database and return the new incremented value.

The first time a counter is created, it will be set to 0 then incremented to 1,
and 1 will be returned. The next increment will increment the counter to two and
return it.

If dry-run mode is chosen, the value that is returned is the value had the
counter been incremented, but the counter will not be actually incremented.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<counter> => I<str>

Counter name, defaults to "default" if not specified.

=item * B<increment> => I<int> (default: 1)

Specify by how many should the counter be incremented.

=item * B<path> => I<filename>

Database path.

If not specified, will default to $HOME/counter.db. If file does not exist, will
be created by DBD::SQLite.

If you want an in-memory database (that will be destroyed after your process
exits), use C<:memory:>.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 METHODS

Aside from the functional interface, this module also provides the OO interface.

=head2 new

Constructor.

Usage:

 my $counter = SQLite::Counter::Simple->new(%args);

Known arguments (C<*> marks required argument):

=over

=item * path

Database path, defaults to C<$HOME/counter.db>.

=back

=head2 increment

Increment counter.

Usage:

 my $newval = $counter->increment(%args);

Arguments:

=over

=item * counter

Counter name, defaults to C<default>.

=item * increment

Increment, defaults to 1.

=back

=head2 get

Get current value of a counter.

Usage:

 my $val = $counter->get(%args);

Arguments:

=over

=item * counter

Counter name, defaults to C<default>.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SQLite-Counter-Simple>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SQLite-Counter-Simple>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SQLite-Counter-Simple>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<SQLite::KeyValueStore::Simple>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
