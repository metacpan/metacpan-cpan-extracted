#! /usr/bin/env perl
use v5.10.1;
use warnings;
use strict;

use Data::Dumper; $Data::Dumper::Indent = 1; $Data::Dumper::Sortkeys = 1;
use DBI;
use Perl5::CoreSmokeDB::Schema;

use Getopt::Long;
my %option = (
    dsn           => 'dbi:SQLite:dbname=p5coresmoke',
    username      => undef,
    password      => \&_read_password,
    password_read => undef,
    options       => {},
);
GetOptions(\%option => qw{
    dsn=s
    username|U=s
    password|p
    options=s%
});

die Dumper( get_databases(%option) );
my $schema = Perl5::CoreSmokeDB::Schema->connect(
    db_connect(%option, ignore_version => 1)
);

sub db_connect {
    my %args = @_;

    my $options = $args{options};
    for my $key (keys %args) {
        next if $key =~ m{^ (?: dsn | username | password_read | password_read ) $}x;
        $options->{$key} = $args{$key};
    }
    return (
        $args{dsn},
        $args{username} // undef,
        $args{password_read} // undef,
        $options,
    );
}

sub get_databases {
    my %args = @_;
    my $dsn = $args{dsn};

    if ($dsn =~ m{^ dbi:Pg: }x) {
        my ($db_attr) = $dsn =~ m{(?<db_attr>dbname|database|db)(?==)}
            ? $+{db_attr}
            : 'dbname';
        $dsn =~ s{$db_attr = (.+) (?=;|$)}{dbname=postgres}x;
        print "Temp dsn: $dsn\n";
    }

    my $dbh = DBI->connect($dsn, $args{username}//undef, $args{password_read}//undef);
    my @sources = $dbh->data_sources();
    $dbh->disconnect();

    return \@sources;
}

sub _read_password {
    eval "use Term::ReadKey";
    if ($@) {
        die "--password cannot read password: install Term::ReadKey";
    }
    print "Enter password: ";
    ReadMode('noecho');
    chomp(my $password = ReadLine(0));
    ReadMode('restore');

    $option{password_read} = $password;
}
