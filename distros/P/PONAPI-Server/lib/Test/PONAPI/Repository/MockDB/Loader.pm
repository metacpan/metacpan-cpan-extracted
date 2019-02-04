# ABSTRACT: mock repository loader
package Test::PONAPI::Repository::MockDB::Loader;

use Moose;

use DBI;

has dbd => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_build_dbd',
);

use File::Temp qw/tempfile/;
sub _build_dbd {
    my ($fh, $path) = tempfile("MockDB.db.XXXXXXX", TMPDIR => 1, UNLINK => 1);
    close $fh;
    return "DBI:SQLite:dbname=$path";
}

has dbh => (
    is      => 'ro',
    isa     => 'DBI::db',
    lazy    => 1,
    builder => '_build_dbh',
);

sub _build_dbh {
    my $self = shift;
    DBI->connect( $self->dbd, '', '', { RaiseError => 1 } )
        or die $DBI::errstr;
}

sub load {
    my $self = shift;

    $self->dbh->do($_) for
        q< DROP TABLE IF EXISTS articles; >,
        q< CREATE TABLE IF NOT EXISTS articles (
             id            INTEGER     PRIMARY KEY AUTOINCREMENT,
             title         CHAR(64)    NOT NULL,
             body          TEXT        NOT NULL,
             created       DATETIME    NOT NULL   DEFAULT CURRENT_TIMESTAMP,
             updated       DATETIME    NOT NULL   DEFAULT CURRENT_TIMESTAMP,
             status        CHAR(10)    NOT NULL   DEFAULT "pending approval" ); >,

        map(qq< INSERT INTO articles (title, body, created, updated, status) VALUES $_>,
             q<("JSON API paints my bikeshed!", "The shortest article. Ever.",
              "2015-05-22 14:56:29", "2015-05-22 14:56:29", "ok" )>,
             q<("A second title", "The 2nd shortest article. Ever.",
              "2015-06-22 14:56:29", "2015-06-22 14:56:29", "ok" )>,
             q<("a third one", "The 3rd shortest article. Ever.",
              "2015-07-22 14:56:29", "2015-07-22 14:56:29", "pending approval" ); >),

        q< DROP TABLE IF EXISTS people; >,
        q< CREATE TABLE IF NOT EXISTS people (
             id            INTEGER     PRIMARY KEY,
             name          CHAR(64)    NOT NULL   DEFAULT "anonymous",
             age           INTEGER     NOT NULL   DEFAULT "100",
             gender        CHAR(10)    NOT NULL   DEFAULT "unknown" ); >,

        map(qq< INSERT INTO people (id, name, age, gender) VALUES $_>,
             q<(42, "John",  80, "male")>,
             q<(88, "Jimmy", 18, "male")>,
             q<(91, "Diana", 30, "female")>),

        q< DROP TABLE IF EXISTS rel_articles_people; >,
        q< CREATE TABLE IF NOT EXISTS rel_articles_people (
             id_articles   INTEGER     NOT NULL PRIMARY KEY,
             id_people     INTEGER     NOT NULL
        ); >,

        map(qq< INSERT INTO rel_articles_people (id_articles, id_people) VALUES $_>,
             q<(1, 42)>,
             q<(2, 88)>,
             q<(3, 91)>),

        q< DROP TABLE IF EXISTS comments; >,
        q< CREATE TABLE IF NOT EXISTS comments (
             id            INTEGER     PRIMARY KEY,
             body          TEXT        NOT NULL DEFAULT "" ); >,

        map(qq< INSERT INTO comments (id, body) VALUES $_>,
             q<(5,  "First!")>,
             q<(12, "I like XML better")>),

        q< DROP TABLE IF EXISTS rel_articles_comments; >,
        q< CREATE TABLE IF NOT EXISTS rel_articles_comments (
             id_articles   INTEGER     NOT NULL,
             id_comments   INTEGER     UNIQUE     NOT NULL ); >,

        map(qq< INSERT INTO rel_articles_comments (id_articles, id_comments) VALUES $_>,
             q<(2, 5)>,
             q<(2, 12)>);
}

__PACKAGE__->meta->make_immutable;
no Moose; 1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::PONAPI::Repository::MockDB::Loader - mock repository loader

=head1 VERSION

version 0.003003

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
