package SQL::Abstract::Builder;

use v5.14;
use DBIx::Simple;
use SQL::Abstract::More;
use List::Util qw(reduce);
use Hash::Merge qw(merge);
Hash::Merge::set_behavior('RETAINMENT_PRECEDENT');

use Exporter qw(import);
our @EXPORT_OK = qw(query build include);

# ABSTRACT: Quickly build & query relational data
our $VERSION = 'v0.1.1'; # VERSION

sub _refp {
    return unless defined $_[0];
    return @{$_[0]} if ref $_[0] eq ref [];
    return @_;
}

sub _rollup {
    my %row = @_;
    my @fields = grep {m/\w+:\w+/} keys %row;
    for (@fields) {
        my ($t,$c) = split ':';
        $row{$t}{$c} = delete $row{$_};
    }
    %row;
}

sub _smerge {
    my ($a,$b) = @_;
    for (keys $b) {
        $a->{$_} = $b->{$_} unless defined $a->{$_};
        next if $a->{$_} eq $b->{$_};
        $a->{$_} = [_refp $a->{$_}] unless ref $a->{$_} eq ref [];
        push @{$a->{$_}}, _refp $b->{$_};
    }
    return $a;
}

sub query (&;@) {
    my @db = (shift)->();
    my $dbh = ref $db[0] eq 'DBIx::Simple' ? $db[0] : DBIx::Simple->connect(@db);
    my ($key,%row);
    $row{$_->{$key}} = _smerge $row{$_->{$key}}, $_ for map {{_rollup %$_}}
    map {my @q;($key,@q) = $_->(); $dbh->query(@q)->hashes} @_;
    values %row;
}

sub build (&;@) {
    my ($fn,@includes) = @_;
    my %params = $fn->();
    my $table = $params{'-from'};
    $params{'-columns'} = [map {"$table.$_"} _refp $params{'-columns'}];
    my $key = delete $params{'-key'};
    my $a = SQL::Abstract::More->new;
    map {
        my %p = %{merge \%params, {$_->()}};
        $p{'-from'} = [-join =>
            map {ref $_ eq ref sub {} ? ($_->($table,$key)) : $_ } _refp $p{'-from'}
        ];
        sub {$key, $a->select(%p)};
    } @includes;
}

sub include (&;@) {
    my ($fn,@rest) = @_;
    my %params = $fn->();
    my ($jtable,$jfield) = @params{qw(-from -key)};
    $params{'-columns'} = [
        map {"$jtable.$_|'$jtable:$_'"}
        _refp $params{'-columns'}
    ];
    $params{'-from'} = sub {"=>{$_[0].$_[1]=$jtable.$jfield}",$jtable};
    delete $params{'-key'};
    return sub {%params}, @rest;
}

1;

__END__
=head1 NAME

SQL::Abstract::Builder - Builds and executers relational queries

=head1 SYNOPSIS

    my @docs = query {"dbi:mysql:$db",$user} build {
        -columns => [qw(id foo bar)],
        -from => 'table1',
        -key => 'id',
    } include {
        -columns => [qw(id baz glarch)],
        -from => 'table2',
        -key => 'table1_id',
    } include {
        -columns => [qw(id alfa)],
        -from => 'table3',
        -key => 'table1_id',
    };

=head1 DESCRIPTION

It gives you a very simple way to define fetch documents (rows and related
children) from your relational DB (instead of just rows).

=head1 METHODS

=head2 query

Executes the built query. Takes either a L<DBIx::Simple> connection or the same
arguments that are valid for C<DBIx::Simple->connect>.

=head3 Usage

    my @docs = query {"dbi:mysql:$db",$user} ...
    # OR
    my @docs = query {$dbh} ...

=head2 build

Builds the query assuming the given table is the base.

=head3 Usage

    my @refs = build { ... } ...

=head2 include

Includes the results of a C<JOIN> on the given table when built.

=head3 Usage

    my @refs = build { ... } include { ... }
