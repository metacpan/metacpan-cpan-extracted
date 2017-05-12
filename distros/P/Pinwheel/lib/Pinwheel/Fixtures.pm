package Pinwheel::Fixtures;

use strict;
use warnings;

use FindBin qw($Bin);
use File::Slurp;
use POSIX qw(strftime);
use YAML::Tiny;

use Pinwheel::Context;
use Pinwheel::Database qw(without_foreign_keys);
use Pinwheel::View::ERB;

our @ISA = qw(Exporter);
our @EXPORT = qw(fixtures scenario identify);
our @EXPORT_OK = qw(insert_fixtures empty_tables);


our $fixtures_path = "$Bin/../fixtures";
our $last_caller = '';
our $helpers;
my %ids;


sub fixtures
{
    my (@names) = @_;
    my ($caller) = caller();

    without_foreign_keys {
        if ($caller ne $last_caller) {
            empty_tables();
            $last_caller = $caller;
        }
        foreach my $table (@names) {
            insert_fixtures(_load_yaml("$fixtures_path/$table.yml"), $table);
        }
    };

    # For doctest niceness, otherwise the result is that of the commit
    return;
}

# See http://code.google.com/p/fixture-scenarios/
sub scenario
{
    my ($name, %opts) = @_;
    my (@dirs, $path);

    $last_caller = caller();
    $path = $fixtures_path;
    if (!exists($opts{'root'}) || $opts{'root'}) {
        push @dirs, $path;
    }
    foreach (split('/', $name)) {
        $path .= '/' . $_;
        push @dirs, $path;
    }

    without_foreign_keys {
        empty_tables();
        foreach $path (@dirs) {
            foreach (glob("$path/*.yml")) {
                /\/([^\/]+)\.yml$/;
                insert_fixtures(_load_yaml($_), $1);
            }
        }
    };

    # For doctest niceness, otherwise the result is that of the commit
    return;
}

sub empty_tables
{
    foreach my $table (Pinwheel::Database::tables()) {
        my $sth = Pinwheel::Database::prepare("DELETE FROM $table");
        $sth->execute();
    }
}

sub insert_fixtures
{
    my ($fixtures, $table) = @_;
    my ($sth, $info, %defaults, @keys);
    my ($label, $row, @fields, $columns, $values);

    $info = Pinwheel::Database::describe($table);
    foreach (keys %$info) {
        if ($_ =~ /^(?:cre|upd)ated_(?:at|on)$/) {
            # created_at/on and updated_at/on default to the current time
            $defaults{$_} = strftime('%Y-%m-%d %H:%M:%S', gmtime());
        } elsif ($_ =~ /_id$/ && $info->{$_}{type} =~ /^int\b/) {
            # Foreign keys can be supplied as labels
            push @keys, $_;
        }
    }

    $sth = {};
    while (($label, $row) = each(%$fixtures)) {
        $row = {%defaults, %$row};

        # If no id, generate one by hashing the label
        if (exists($info->{id}) && !exists($row->{id})) {
            $row->{id} = identify($label);
        }
        # Convert foreign keys supplied as labels
        foreach (@keys) {
            if ($row->{$_} && $row->{$_} =~ /[^0-9]/) {
                $row->{$_} = identify($row->{$_});
            }
        }

        @fields = keys %$row;
        $columns = join(', ', map { "`$_`" } @fields);
        unless ($sth->{$columns}) {
            $values = join(', ', ('?') x scalar(@fields));
            $sth->{$columns} = Pinwheel::Database::prepare(
                "REPLACE INTO $table ($columns) VALUES ($values)"
            );
        }
        $sth->{$columns}->execute(@{$row}{@fields});
    }
}

sub _load_yaml
{
    my ($filename) = @_;
    my ($data, $tmpl);

    $data = read_file($filename, binmode => ':raw');
    if ($data =~ /<%/) {
        _prepare_helpers() unless $helpers;
        $tmpl = Pinwheel::View::ERB::parse_template($data, $filename);
        $data = $tmpl->({}, {}, $helpers);
    }
    return YAML::Tiny->read_string($data)->[0];
}

sub _prepare_helpers
{
    my ($pkg, $fns);

    $fns = {};
    $pkg = \%Pinwheel::Helpers::Fixtures::;
    foreach (@{$pkg->{'EXPORT_OK'}}) {
        $fns->{$_} = \&{$pkg->{$_}} if $pkg->{$_};
    }

    $helpers = $fns;
}


sub identify
{
    my ($s) = @_;

    $ids{$s} = _hash($s) if !exists($ids{$s});
    return $ids{$s};
}


# Implementation of http://burtleburtle.net/bob/hash/evahash.html
sub _hash
{
    use integer;
    my ($s) = @_;
    my ($length, $a, $b, $c, $i, $j, @k);

    $length = length($s);
    $s .= "\0\0\0\0\0\0\0\0\0\0\0\0";
    @k = unpack('V' x (length($s) >> 2), $s);

    $i = 0;
    $j = ($length >> 2) - 3;
    $a = $b = 0x9e3779b9;
    $c = 0;
    while ($i <= $j) {
        $a += $k[$i++];
        $b += $k[$i++];
        $c += $k[$i++];
        ($a, $b, $c) = _mix($a, $b, $c);
    }

    $a += $k[$i++];
    $b += $k[$i++];
    $c += $length + ($k[$i++] << 8);
    ($a, $b, $c) = _mix($a, $b, $c);

    if ($c & 0x80000000) {
        $c = 0x80000000 - ($c & 0x7fffffff);
    } else {
        $c &= 0x7fffffff;
    }

    return $c;
}

sub _mix
{
    use integer;
    my ($a, $b, $c) = @_;

    $a = ($a - $b - $c) ^ (($c >> 13) & 0x0007ffff);
    $b = ($b - $c - $a) ^  ($a <<  8);
    $c = ($c - $a - $b) ^ (($b >> 13) & 0x0007ffff);
    $a = ($a - $b - $c) ^ (($c >> 12) & 0x000fffff);
    $b = ($b - $c - $a) ^  ($a << 16);
    $c = ($c - $a - $b) ^ (($b >>  5) & 0x07ffffff);
    $a = ($a - $b - $c) ^ (($c >>  3) & 0x1fffffff);
    $b = ($b - $c - $a) ^  ($a << 10);
    $c = ($c - $a - $b) ^ (($b >> 15) & 0x0001ffff);

    return ($a, $b, $c);
}


1;

__DATA__

=head1 NAME

Pinwheel::Fixtures

=head1 SYNOPSIS

    use Pinwheel::Fixtures;
    fixtures('episodes', 'brands', 'series', 'networks');
    scenario('radio4_empty_schedule');

The episodes.yml file might resemble:

    radio4:
      id: 1
      name: When Frogs Go Berserk
      short_description: This is the short description
      long_description: This is the long description of the episode
      pid: pid001
      series_id: 1
      position: 1

=head1 DESCRIPTION

Pinwheel::Fixtures provides a mechanism for loading YAML files into the database.
Database access is via the C<Pinwheel::Database> module.

The convention is the same as in Rails: the name of the YAML file is the name
of the database table.  The first element in the YAML is an identifier for the
tuple.  Each item for the tuple should be a row in the database using its
field name.

=head1 ROUTINES

=over 4

=item fixtures(NAMES)

TODO, properly document me.

This method is called to import the fixture data for the database tables
specified as a list of fieldnames.

=item scenario(NAME, OPTIONS)

TODO, properly document me.

Import a collection of fixtures in one go.  If called with an OPTIONS value of
C<< root => 0 >> then fixtures at the root of the fixture directory are
ignored.

=item $int = identify($string)

Hashes C<$string> to some integer.  This can be used to automatically pick IDs
that would normally be generated automatically by the database.

=item empty_tables()

Empties all the tables in the database.  (Specifically, uses C<DELETE> to do
so).

=item insert_fixtures($fixtures, $table)

Loads the data given by C<$fixtures> into the given database C<$table>.

Enumerates the columns in the given C<$table>.  Columns named
C<(created|updated)_(at|on)> are assigned a default of the current time.  Any
integer columns named like C<*_id> are deemed to be foreign keys.

For each C<$label, $row> in C<%$fixtures> (where C<$row> is a hash ref of
column name / value pairs):

=over 4

=item *

If the table has an 'id' column and there is no 'id' entry in C<$row>, the id
is filled in using C<identify($label)>.

=item *

For each column identified as a foreign key, if the value in C<$row> is
present but contains any non-digit characters, then the value is replaced by
C<identify($value)>.

=item *

The row is then written to the database (using REPLACE INTO).

=back

=back

=head1 EXPORTS

Exported by default: fixtures scenario identify

May be exported: insert_fixtures empty_tables

=head1 BUGS

The documentation doesn't describe how the fixtures are loaded, and how
'helpers' are used.  The synopsis mentions "the episodes.yaml" file, without
first mentioning that YAML is even used.

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut

