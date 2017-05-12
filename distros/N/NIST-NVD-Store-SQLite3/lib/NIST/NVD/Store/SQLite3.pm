package NIST::NVD::Store::SQLite3;

use strict;
use warnings;

use NIST::NVD::Store::Base;

use base qw{NIST::NVD::Store::Base};

our @ISA;
push @ISA, qw{NIST::NVD::Store::Base};

use Carp(qw(carp confess cluck));

use Storable qw(nfreeze thaw);
use DBI;
use Time::HiRes qw( gettimeofday );

=head1 NAME

NIST::NVD::Store::SQLite3 - SQLite3 store for NIST::NVD

=head1 VERSION

Version 1.00.00

=cut

our $VERSION = '1.00.00';

my %query = (
    cpe_create => qq{
CREATE TABLE IF NOT EXISTS cpe (
  id      INTEGER PRIMARY KEY AUTOINCREMENT,
  urn     VARCHAR(64) CONSTRAINT uniq_urn UNIQUE ON CONFLICT FAIL,

  part     CHAR,
  vendor   VARCHAR(16),
  product  VARCHAR(16),
  version  VARCHAR(16),
  updt     VARCHAR(16),
  edition  VARCHAR(16),
  language VARCHAR(4)
)},
    cve_create => qq{
CREATE TABLE IF NOT EXISTS cve (
  id      INTEGER PRIMARY KEY AUTOINCREMENT,
  score   REAL,
  cve_id  VARCHAR(16) CONSTRAINT uniq_cve_id UNIQUE ON CONFLICT FAIL,
  cve_dump BLOB
)},
    cwe_create => qq{
CREATE TABLE IF NOT EXISTS cwe (
  id      INTEGER PRIMARY KEY AUTOINCREMENT,
  cwe_id  VARCHAR(16) CONSTRAINT uniq_cwe_id UNIQUE ON CONFLICT FAIL,
  cwe_dump BLOB
)},
    cpe_cve_map_create => qq{
CREATE TABLE IF NOT EXISTS cpe_cve_map (
  id      INTEGER PRIMARY KEY AUTOINCREMENT,

  cpe_id INTEGER,
  cve_id INTEGER,
  CONSTRAINT uniq_cpe_cve UNIQUE ( cpe_id, cve_id ) ON CONFLICT FAIL
)},
    cpe_cwe_map_create => qq{
CREATE TABLE IF NOT EXISTS cpe_cwe_map (
  id      INTEGER PRIMARY KEY AUTOINCREMENT,

  cpe_id INTEGER,
  cwe_id INTEGER,
  CONSTRAINT uniq_cpe_cwe UNIQUE ( cpe_id, cwe_id ) ON CONFLICT IGNORE
)},
    cve_cwe_map_create => qq{
CREATE TABLE IF NOT EXISTS cve_cwe_map (
  id      INTEGER PRIMARY KEY AUTOINCREMENT,

  cve_id INTEGER,
  cwe_id VARCHAR(64),
  CONSTRAINT uniq_cve_cwe UNIQUE ( cve_id, cwe_id ) ON CONFLICT IGNORE
)},
    websec_create => qq{
CREATE TABLE IF NOT EXISTS cpe_websec_score (
  id     INTEGER PRIMARY KEY AUTOINCREMENT,

  cpe_urn VARCHAR(64) UNIQUE,
  cat_a0 REAL,
  cat_a1 REAL,
  cat_a2 REAL,
  cat_a3 REAL,
  cat_a4 REAL,
  cat_a5 REAL,
  cat_a6 REAL,
  cat_a7 REAL,
  cat_a8 REAL,
  cat_a9 REAL,
  cat_a10 REAL

)},
    verify_cwe_pkid => qq{
SELECT cwe_id,id FROM cwe WHERE id=?
},
    cve_for_cpe_select => qq{
SELECT cve.cve_id
  FROM cpe_cve_map,cve
 WHERE cpe_cve_map.cpe_id=?
   AND cpe_cve_map.cve_id=cve.id
ORDER BY cve.cve_id
},
    cwe_for_cpe_select => qq{
SELECT cwe.cwe_id
  FROM cpe_cwe_map,cwe
 WHERE cpe_cwe_map.cpe_id=?
   AND cpe_cwe_map.cwe_id=cwe.id
ORDER BY cwe.cwe_id
},
    get_cpe_id_select => qq{
SELECT id FROM cpe WHERE cpe.urn=?
},
    get_cve_id_select => qq{
SELECT id FROM cve WHERE cve.cve_id=?
},
    get_cwe_id_select => qq{
SELECT id FROM cwe WHERE cwe.cwe_id=?
},
    get_cve_select => qq{
SELECT cve_dump FROM cve WHERE cve.cve_id=?
},
    get_websec_score_select_by_cpe => qq{
SELECT cat_a0, cat_a1, cat_a2, cat_a3, cat_a4, cat_a5, cat_a6, cat_a7,
  cat_a8, cat_a9, cat_a10 FROM cpe_websec_score WHERE cpe_urn=?
},
    get_cve_id_select_by_pkey => qq{
SELECT id,cve_id FROM cve WHERE id=?
},
    get_cve_id_select_by_friendly => qq{
SELECT id,cve_id FROM cve WHERE cve_id=?
},
    get_cwe_select => qq{
SELECT id,cwe_dump FROM cwe WHERE cwe.cwe_id=?
},
    put_cve_idx_cpe_insert => qq{
INSERT INTO cpe_cve_map (cpe_id,cve_id)
VALUES ( ?, ? )
},
    put_cwe_idx_cpe_insert => qq{
INSERT INTO cpe_cwe_map (cpe_id,cwe_id)
VALUES ( ?, ? )
},
    put_cwe_idx_cve_insert => qq{
INSERT INTO cve_cwe_map (cve_id,cwe_id)
VALUES ( ?, ? )
},
    put_cve_insert => qq{
INSERT INTO cve ( cve_dump, score, cve_id ) VALUES (?, ?, ?)
},
    put_cve_update => qq{
UPDATE cve SET cve_dump=?, score=? WHERE cve.id=?
},
    put_cwe_insert => qq{
INSERT INTO cwe ( cwe_dump, cwe_id ) VALUES (?, ?)
},
    put_cwe_update => qq{
UPDATE cwe SET cwe_dump=? WHERE cwe.id=?
},
    put_cpe_insert => qq{
INSERT INTO cpe ( urn,part,vendor,product,version,updt,edition,language )
VALUES( ?,?,?,?,?,?,?,? )
}

);

my %sth = ();

=head1 SYNOPSIS

$q =
  eval { NIST::NVD::Query->new( store => 'SQLite3', database => $db_file, ); };


=head1 SUBROUTINES/METHODS

=head2 new

    my $NVD_Storage_SQLite3 = NIST::NVD::Store::SQLite3->new(
        store     => 'SQLite3',
        database  => '/path/to/database.sqlite',
    );

=cut

sub new {
    my ( $class, %args ) = @_;
    $class = ref $class || $class;

    #    my $self = $class->SUPER::new(%args);

    my $self = bless { store => $args{store} }, $class;

    my $store = $args{store};

    unless ( exists $args{database} && $args{database} ) {
        confess('database argument is required, but was not passed');
        return;
    }

    $self->{$store} = $self->_connect_db( database => $args{database} );

    $self->{sqlite} = $self->{SQLite3};

    $self->{vuln_software} = {};

    foreach my $statement (
        qw( put_cpe_insert
        cve_for_cpe_select cwe_for_cpe_select
        put_cve_idx_cpe_insert
        put_cwe_idx_cpe_insert
        put_cwe_idx_cve_insert
        put_cve_insert put_cve_update
        put_cwe_insert put_cwe_update
        get_cpe_id_select
        get_cve_id_select get_cve_select
        get_cwe_id_select get_cwe_select
        get_cve_id_select_by_pkey
        get_cve_id_select_by_friendly
        get_websec_score_select_by_cpe
        )
      )
    {
        $sth{$statement} = $self->{sqlite}->prepare( $query{$statement} )
          or die "couldn't prepare statement '$statement'";
    }
    my $fail = 0;

    return if $fail;

    return $self;
}

sub _connect_db {
    my ( $self, %args ) = @_;

    my $dbh = DBI->connect( "dbi:SQLite:dbname=$args{database}", "", "" );

    foreach my $statement (
        qw(
        cpe_create websec_create
        cve_cwe_map_create
        cve_create cpe_cve_map_create
        cwe_create cpe_cwe_map_create
        verify_cwe_pkid
        )
      )
    {

        my $query = $query{$statement};

        $sth{$statement} //= $dbh->prepare($query);
        $sth{$statement}->execute();
    }

    return $dbh;
}

=head2 get_cve_for_cpe

=cut

my $cpe_urn_re = qr{^(cpe:/(.)(:[^:]+){2,6})$};

sub get_cve_for_cpe {
    my ( $self, %args ) = @_;

    my $cpe = $args{cpe};

    return unless $cpe;

    my $cpe_pkey_id;
    if ( $cpe =~ /^\d+$/ ) {
        $cpe_pkey_id = $cpe;
    }
    else {
        ( my ( $cpe, @parts ) ) = ( $args{cpe} =~ $cpe_urn_re );
        $cpe_pkey_id = $self->_get_cpe_id($cpe);
    }

    $sth{cve_for_cpe_select}->execute($cpe_pkey_id);

    my $cve_id = [];

    while ( my $row = $sth{cve_for_cpe_select}->fetchrow_hashref() ) {
        push( @$cve_id, $row->{'cve_id'} );
    }

    return $cve_id;
}

=head2 get_cwe_for_cpe

=cut

sub get_cwe_for_cpe {
    my ( $self, %args ) = @_;

    my $cpe = $args{cpe};

    return unless $cpe;

    my $cpe_pkey_id;
    if ( $cpe =~ /^\d+$/ ) {
        $cpe_pkey_id = $cpe;
    }
    else {
        ( my ( $cpe, @parts ) ) = ( $args{cpe} =~ $cpe_urn_re );
        $cpe_pkey_id = $self->_get_cpe_id($cpe);
    }

    $sth{cwe_for_cpe_select}->execute($cpe_pkey_id);

    my $cwe_id = [];

    while ( my $row = $sth{cwe_for_cpe_select}->fetchrow_hashref() ) {
        push( @$cwe_id, $row->{'cwe_id'} );
    }

    return $cwe_id;
}

my %cve_id_cache;

sub _get_cve_id {
    my ( $self, $cve_id ) = @_;

    return @{ $cve_id_cache{$cve_id} } if exists $cve_id_cache{$cve_id};

    my $sth;
    my $query;

    if ( $cve_id =~ /^\d+$/ ) {
        $sth = $sth{get_cve_id_select_by_pkey};
    }
    elsif ( $cve_id =~ /^CVE-\d+-\d+/ ) {
        $sth = $sth{get_cve_id_select_by_friendly};
    }
    else {
        confess "cve id malformed\n";
        die;
    }

    $sth->execute($cve_id);
    my $row = $sth->fetchrow_hashref();
    return unless $row;

    $cve_id_cache{$cve_id} = [ $row->{id}, $row->{cve_id} ];

    return ( $row->{id}, $row->{cve_id} );
}

my %cwe_id_cache;

sub _get_cwe_id {
    my ( $self, $cwe_id ) = @_;

    return @{ $cwe_id_cache{$cwe_id} } if exists $cwe_id_cache{$cwe_id};

    my $sth;

    if ( $cwe_id =~ /^\d+$/ ) {
        $sth = $self->{sqlite}->prepare('SELECT id,cwe_id FROM cwe WHERE id=?');

    }
    elsif ( $cwe_id =~ /^CWE-\d+/ ) {

        $sth =
          $self->{sqlite}->prepare('SELECT id,cwe_id FROM cwe WHERE cwe_id=?');
    }
    else {
        cluck "cwe id malformed\n";
        return;
    }

    $sth->execute($cwe_id);
    my $row = $sth->fetchrow_hashref();

    unless ($row) {
        return;
    }

    $cwe_id_cache{$cwe_id} = [ $row->{qw{id cwe_id}} ];
    \

      return ( $row->{qw{id cwe_id}} );
}

sub _get_cpe_id {
    my ( $self, $cpe_urn ) = @_;

    return $self->{cpe_map}->{$cpe_urn}
      if ( exists $self->{cpe_map}->{$cpe_urn} );

    $sth{get_cpe_id_select}->execute($cpe_urn);

    # TODO: Assert that this query only returns one result
    my $rows = 0;
    while ( my $row = $sth{get_cpe_id_select}->fetchrow_hashref() ) {
        carp
"multiple ($rows) results for value intended to be unique.  cpe_urn: [$cpe_urn]\n"
          if ( $rows != 0 );
        $self->{cpe_map}->{$cpe_urn} = $row->{id};
    }

    return $self->{cpe_map}->{$cpe_urn};
}

sub _get_query {
    my ( $self, $query_name ) = @_;

    return $query{$query_name}
      if ($query_name);

    return %query if wantarray;

    return \%query;
}

sub _get_sth {
    my ( $self, $query_name ) = @_;

    return unless exists $query{$query_name};

    if ($query_name) {
        $sth{$query_name} //= $self->{sqlite}->prepare( $query{$query_name} );
        return $sth{$query_name};
    }

    return %sth if wantarray;

    return \%sth;
}

sub _prepare {

}

=head2 get_cve


=cut

sub get_cve {
    my ( $self, %args ) = @_;

    $sth{get_cve_select}->execute( $args{cve_id} );

    my $row = $sth{get_cve_select}->fetchrow_hashref();

    my $frozen = $row->{cve_dump};

    my $entry = eval { thaw $frozen };
    if (@$) {
        carp "Storable::thaw had a major malfunction.";
        return;
    }

    return $entry;
}

my %injection     = ( OWASP => 'A1', );
my %xss           = ( OWASP => 'A2', );
my %authn_session = ( OWASP => 'A3', );

my %latest_OWASP_ten = (
    'A1' => {
        id      => 'CWE-810',
        members => [ 'CWE-78', 'CWE-88', 'CWE-89', 'CWE-90', 'CWE-91', ],
    },
    'A2' => {
        id      => 'CWE-811',
        members => [ 'CWE-79', ],
    },

    'A3' => {
        id      => 'CWE-812',
        members => [ 'CWE-287', 'CWE-306', 'CWE-307', 'CWE-798', 'CWE-798', ],
    },
    'A4' => {
        id => 'CWE-813',
        members =>
          [ 'CWE-22', 'CWE-434', 'CWE-639', 'CWE-829', 'CWE-862', 'CWE-863' ]
    },
    'A5' => { id => 'CWE-814', members => ['CWE-352'] },
    'A6' => {
        id => 'CWE-815',
        members =>
          [ 'CWE-209', 'CWE-219', 'CWE-250', 'CWE-538', 'CWE-552', 'CWE-732', ]
    },
    'A7' => {
        id      => 'CWE-816',
        members => [ 'CWE-311', 'CWE-312', 'CWE-326', 'CWE-327', 'CWE-759', ]
    },
    'A8' => {
        id      => 'CWE-817',
        members => [ 'CWE-284', 'CWE-862', 'CWE-863', ]
    },
    'A9' => {
        id      => 'CWE-818',
        members => [ 'CWE-311', 'CWE-319', ]
    },
    'A10' => {
        id      => 'CWE-819',
        members => [ 'CWE-601', ]
    },
);

my %owasp_idx;

foreach my $cat (qw( A1 A2 A3 A4 A5 A6 A7 A8 A9 A10 )) {
    foreach my $cwe_id ( @{ $latest_OWASP_ten{$cat}->{members} } ) {
        $owasp_idx{$cwe_id} = $cat;
    }
}

=head2 get_cwe

  my $cwe_dump = $self->get_cwe( id => $cwe_row->{id} );
  or
  my $cwe_dump = $self->get_cwe( cwe_id => $cwe_row->{cwe_id} );

=cut

sub get_cwe {
    my ( $self, %args ) = @_;

    my $sth;

    my $arg;

    if ( exists $args{id} ) {
        die "id [$args{id}] is malformed" unless $args{id} =~ /^\d+$/;
        $sth = $self->{sqlite}->prepare('SELECT cwe_dump FROM cwe WHERE id=?');
        $arg = $args{id};
    }
    elsif ( exists $args{cwe_id} ) {
        die "cwe_id [$args{cwe_id}] is malformed"
          unless $args{cwe_id} =~ /^CWE-\d+/;
        $sth =
          $self->{sqlite}->prepare('SELECT cwe_dump FROM cwe WHERE cwe_id=?');
        $arg = $args{cwe_id};
    }

    $sth->execute($arg);

    my $frozen = $sth->fetchrow_hashref()->{cwe_dump};

    my $data = eval { thaw $frozen };
    if (@$) {
        carp "Storable::thaw had a major malfunction.";
        return;
    }

    return $data;
}

=head2 put_cve_idx_cpe

  my %vuln_software = ( $cpe_urn0 => [ $cve_id0,$cve_id42,... ],
                        $cpe_urn1 => [ $cve_id1,$cve_id24,... ],
  #                     ...,
                        $cpe_urnN => [ $cve_id2,$cve_id3,... ],
                       );
  $Updater->put_cve_idx_cpe( \%vuln_software );

=cut

my %uniq_cve_idx_cpe;

sub put_cve_idx_cpe {
    my ( $self, $vuln_software ) = @_;

    my @params;
    while ( my ( $cpe_urn, $cve_id ) = ( each %$vuln_software ) ) {
        my $cpe_pkey_id = $self->_get_cpe_id($cpe_urn);

        foreach my $id (@$cve_id) {
            my ( $cve_pkey, $cve_friendly ) = $self->_get_cve_id($id);
            next unless $cve_pkey;
            next if $uniq_cve_idx_cpe{$cpe_pkey_id}->{$cve_pkey}++;
            push( @params, [ $cpe_pkey_id, $cve_pkey ] );
        }
    }

    $self->{sqlite}->do("BEGIN IMMEDIATE TRANSACTION");
    $sth{put_cve_idx_cpe_insert}->execute(@$_) foreach (@params);
    $self->{sqlite}->commit() or die $$self->{sqlite}->errstr;
    return;
}

=head2 put_cwe_idx_cpe

  my %vuln_software = ( $cpe_urn0 => [ $cwe_id0,$cwe_id42,... ],
                        $cpe_urn1 => [ $cwe_id1,$cwe_id24,... ],
  #                     ...,
                        $cpe_urnN => [ $cwe_id2,$cwe_id3,... ],
                       );
  $Updater->put_cwe_idx_cpe( \%weaknesses );

=cut

my %uniq_cwe_idx_cpe;

sub put_cwe_idx_cpe {
    my ( $self, $weaknesses ) = @_;

    my $initial_cwe_ids = $self->get_cwe_ids();

    my (%cpe_pkey_id) = map { $_ => $self->_get_cpe_id($_) } keys %$weaknesses;

    my @params;
    while ( my ( $cpe_urn, $cwe_id ) = ( each %$weaknesses ) ) {
        my $cpe_pkey_id = $cpe_pkey_id{$cpe_urn};

        foreach my $id (@$cwe_id) {
            my $cwe_pkey_id = $initial_cwe_ids->{$id};

            unless ($cwe_pkey_id) {

                #                print STDERR "no data for [$id]\n";
                print 'x';
                next;
            }

            next if $uniq_cwe_idx_cpe{$cpe_pkey_id}->{$cwe_pkey_id}++;
            push( @params, [ $cpe_pkey_id, $cwe_pkey_id ] );
        }
    }

    $self->{sqlite}->do("BEGIN IMMEDIATE TRANSACTION");
    $sth{put_cwe_idx_cpe_insert}->execute(@$_) foreach (@params);
    $self->{sqlite}->commit();
    return;
}

=head2 update_websec_idx_cpe

  $Updater->update_websec_idx_cpe({ cpe_urn[$i] => [ $cwe_id[20], $cwe_id[7], $cwe_id[235], ... $cwe_id[$n], ],
                                    cpe_urn[$j] => [ $cwe_id[42], $cwe_id[$k], $cwe_id[72], ... $cwe_id[$j], ],
                                    ... => });

=cut

sub update_websec_idx_cpe {
    my ($self) = @_;

    # walk through each cpe urn

    my $dbh = $self->{sqlite};

    my $q       = "SELECT id, urn FROM cpe";
    my $cpe_sth = $dbh->prepare($q);

    $q = "SELECT cve_id FROM cpe_cve_map WHERE cpe_id=?";
    my $cve_sth = $dbh->prepare($q);

    $q = "SELECT score FROM cve WHERE id=?";
    my $cve_score_sth = $dbh->prepare($q);

    $q = "SELECT cwe_id FROM cve_cwe_map WHERE cve_id=?";
    my $cwe_sth = $dbh->prepare($q);

    my $cwe_idx_cpe_sth = $self->_get_sth('put_cwe_idx_cpe_insert');

    $q =
      (     "INSERT INTO cpe_websec_score ("
          . "cpe_urn,cat_a0,cat_a1,cat_a2,cat_a3,cat_a4,cat_a5,cat_a6,cat_a7,cat_a8,cat_a9,cat_a10"
          . ") VALUES ("
          . "?,?,?,?,?,?,?,?,?,?,?,?"
          . ")" );
    my $score_sth = $dbh->prepare($q);

    $cpe_sth->execute();

    my @idx_args = ();

    my $websec_score = {};

    while ( my $cpe_row = $cpe_sth->fetchrow_hashref() ) {

        # for each cpe, find all CVEs
        $cve_sth->execute( $cpe_row->{id} );
        while ( my $cve_row = $cve_sth->fetchrow_hashref() ) {

            $cve_score_sth->execute( $cve_row->{cve_id} );
            my $cve_score_row = $cve_score_sth->fetchrow_hashref();

            my $score = $cve_score_row->{score};

            my ( $cve_pkey, $cve_friendly ) =
              $self->_get_cve_id( $cve_row->{cve_id} );

            # for each CVE, find all CWEs
            $cwe_sth->execute($cve_friendly);

            while ( my $cwe_row = $cwe_sth->fetchrow_hashref() ) {
                my $cwe_id = $cwe_row->{cwe_id};
                push( @idx_args, [ $cpe_row->{id}, $cwe_id ] );

                my $owasp_cat = $owasp_idx{$cwe_id} // 'other';

                push(
                    @{ $websec_score->{ $cpe_row->{urn} }->{$owasp_cat} },
                    {
                        cwe_id => $cwe_id,
                        cve_id => $cve_friendly,
                        score  => $score,
                    },
                );
            }

        }
    }

    my @websec_score;
    foreach my $cpe_urn ( keys %$websec_score ) {
        my $score = $websec_score->{$cpe_urn};
        my @score;
        foreach my $cat (qw( other A1 A2 A3 A4 A5 A6 A7 A8 A9 A10 )) {
            if ( exists $score->{$cat} ) {
                my $final = 0;
                foreach my $s ( @{ $score->{$cat} } ) {
                    $final = $s->{score} if $s->{score} > $final;
                }
                push( @score, $final );
            }
            else {
                push( @score, 0 );
            }
        }
        push( @websec_score, [ $cpe_urn, @score ] );
    }

    $self->{sqlite}->do("BEGIN IMMEDIATE TRANSACTION");
    $score_sth->execute(@$_)       foreach @websec_score;
    $cwe_idx_cpe_sth->execute(@$_) foreach @idx_args;
    $self->{sqlite}->commit();

}

=head2 put_cpe


=cut

my %inserted_cpe;

sub put_cpe {
    my ( $self, $cpe_urn ) = @_;

    $cpe_urn = [$cpe_urn] unless ( ref $cpe_urn eq 'ARRAY' );

    my %cpe_urn = map { $_ => 1 } @$cpe_urn;
    my $query   = 'SELECT id,urn FROM cpe';
    my $sth     = $self->{sqlite}->prepare($query);

    while ( my $row = $sth->fetchrow_hashref() ) {
        delete $cpe_urn{ $row->{cpe_urn} }
          if exists $cpe_urn{ $row->{cpe_urn} };
    }

    my @params;
    foreach my $urn ( keys %cpe_urn ) {
        next if $inserted_cpe{$urn}++;

        my (
            $prefix,  $nada,   $part,    $vendor, $product,
            $version, $update, $edition, $language
        ) = split( m{[/:]}, $urn );

        push(
            @params,
            [
                $urn,     $part,   $vendor,  $product,
                $version, $update, $edition, $language
            ]
        );
    }

    $self->{sqlite}->do('BEGIN IMMEDIATE TRANSACTION');
    $sth{put_cpe_insert}->execute(@$_) foreach @params;
    $self->{sqlite}->commit();
}

=head2 put_cve


=cut

sub put_cve {

}

=head2 put_nvd_entries


=cut

sub put_nvd_entries {
    my ( $self, $entries ) = @_;

    my @insert_args;
    my @update_args;

    while ( my ( $cve_id, $orig_entry ) = ( each %$entries ) ) {
        my $entry = {};

        foreach my $preserve ( $self->_important_fields() ) {
            $entry->{$preserve} = $orig_entry->{$preserve}
              if exists $orig_entry->{$preserve};
        }

        my $frozen = nfreeze($entry);

        my $score =
          $entry->{'vuln:cvss'}->{'cvss:base_metrics'}->{'cvss:score'};
        my ( $pkey, $friendly ) = $self->_get_cve_id($cve_id);
        my $sth;
        my $cve_indexed = 0;

        # If the CVE is already in the database, update the record
        if ($pkey) {
            push( @update_args, [ $frozen, $score, $cve_id ] );
        }
        else {
            push( @insert_args, [ $frozen, $score, $cve_id ] );
        }

    }

    $self->{sqlite}->do("BEGIN IMMEDIATE TRANSACTION");
    $sth{put_cve_update}->execute(@$_) foreach @update_args;
    $sth{put_cve_insert}->execute(@$_) foreach @insert_args;
    $self->{sqlite}->commit();

}

=head2 put_cwe

  $result = $self->put_cwe( cwe_id   => 'CWE-42',
                            cwe_dump => $cwe_dump );

=cut

my $commit_buffer = {};

sub put_cwe {
    my ( $self, %args ) = @_;

    my $cwe_id   = $args{cwe_id};
    my $cwe_dump = $args{cwe_dump};

    if ( exists $args{transactional} ) {
        push( @{ $commit_buffer->{put_cwe_insert} }, [ $cwe_dump, $cwe_id ] );
    }
    else {
        $sth{put_cwe_insert}->execute( $cwe_dump, $cwe_id );
    }

    return;
}

=head2 put_cwe_idx_cve

  $result = $store->put_cwe_idx_cve({ $cve_id[0] => $entry[0],
                                      $cve_id[1] => $entry[1],
                                      # ...
                                      $cve_id[$n] => $entry[$n],
                                     });

=cut

sub put_cwe_idx_cve {
    my ( $self, $entries ) = @_;

    my @cwe_idx_args;
    my $num_cwes = 0;
    while ( my ( $cve_id, $entry ) = ( each %$entries ) ) {
        my ( $pkey, $friendly ) = $self->_get_cve_id($cve_id);

        $num_cwes += scalar @{ $entry->{'vuln:cwe'} }
          if exists $entry->{'vuln:cwe'};

        # index the cve->cwe relation
        foreach my $cwe_id ( @{ $entry->{'vuln:cwe'} } ) {

            my ( $cwe_friendly, $cwe_pkey );

            if ( $cwe_id =~ /^CWE-\d+$/ ) {
                $cwe_friendly = $cwe_id;
            }
            else {
                ( $cwe_pkey, $cwe_friendly ) = $self->_get_cwe_id($cwe_id);
            }

            next unless $cwe_friendly;

            push( @cwe_idx_args, [ $cve_id, $cwe_friendly ] );
        }
    }

    $self->{sqlite}->do("BEGIN IMMEDIATE TRANSACTION");
    $sth{put_cwe_idx_cve_insert}->execute(@$_) foreach @cwe_idx_args;
    $self->{sqlite}->commit();

}

sub _commit {
    my ( $self, $buffer_name ) = @_;

    $self->{sqlite}->do('BEGIN IMMEDIATE TRANSACTION');
    foreach my $row ( @{ $commit_buffer->{$buffer_name} } ) {
        my (@bound) = @$row;
        $sth{$buffer_name}->execute(@bound);
    }
    $self->{sqlite}->commit();
    delete $commit_buffer->{$buffer_name};
}

=head2 get_websec_by_cpe

  my $result = $store->get_websec_by_cpe( 'cpe:/a:apache:tomcat:6.0.28' );
  while( my $websec = shift( @{$result->{websec_results}} ) ){
    print( "$websec->{key} - $websec->{category}: ".
           "$websec->{score}\n" );
  }

=cut

my %cat_name = (
    cat_a0  => 'Other',
    cat_a1  => 'Injection',
    cat_a2  => 'Cross-Site Scripting (XSS)',
    cat_a3  => 'Broken Authentication and Session Management',
    cat_a4  => 'Insecure Direct Object References',
    cat_a5  => 'Cross-Site Request Forgery (CSRF)',
    cat_a6  => 'Security Misconfiguration',
    cat_a7  => 'Insecure Cryptographic Storage',
    cat_a8  => 'Failure to Restrict URL Access',
    cat_a9  => 'Insufficient Transport Layer Protection',
    cat_a10 => 'Unvalidated Redirects and Forwards',
);

sub get_websec_by_cpe {
    my ( $s, $self, $cpe ) = @_;

    my @websec_results;
    my %results = ( websec_results => \@websec_results );

    my $sth = $sth{get_websec_score_select_by_cpe};

    $sth->execute($cpe);

    my $row = $sth->fetchrow_hashref();

    foreach my $key (
        qw(cat_a0 cat_a1 cat_a2 cat_a3 cat_a4
        cat_a5 cat_a6 cat_a7 cat_a8 cat_a9 cat_a10)
      )
    {
        push(
            @websec_results,
            {
                category => $cat_name{$key},
                score    => $row->{$key},
                key      => $key
            }
        );
    }

    return %results if wantarray;

    return \%results;
}

=head2 get_cwe_ids

  $result = $self->get_cwe_ids();
  while( my( $cwe_id, $cwe_pkey_id ) = each %$result ){
    ...
  }

=cut

sub get_cwe_ids {
    my ($self) = @_;

    my $result = {};

    my $sth = $self->{sqlite}->prepare("SELECT cwe_id,id FROM cwe");

    $sth->execute();

    while ( my $row = $sth->fetchrow_hashref() ) {
        $result->{ $row->{cwe_id} } = $row->{id};
    }

    return $result;
}

=head2 put_cwe_data

$cwe_data = { View             => $view_data,
              Category         => $category_data,
              Weakness         => $weakness_data,
              Compound_Element => $compound_data,
            };

$NVD_Updater->put_cwe_data($cwe_data);

=cut

sub put_cwe_data {
    my ( $self, $weakness_data ) = @_;

    my @insert_entries;
    my @update_entries;

    my $insert_sth = $sth{put_cwe_insert};
    my $update_sth = $sth{put_cwe_update};

    my $initial_cwe_ids = $self->get_cwe_ids();

    my $count = 0;
    foreach my $element (qw(View Category Weakness Compound_Element)) {
        my $data = $weakness_data->{$element};
        my %cwe_pkey_id;

        while ( my ( $k, $entry ) = ( each %$data ) ) {

            my ( $cwe_pkey_id, $cwe_id ) = $self->_get_cwe_id($k);

            $self->{cwe_pkey_id}->{$cwe_id} = $cwe_pkey_id if $cwe_id;

            my $frozen = nfreeze($entry);

            if ($cwe_pkey_id) {
                push( @update_entries, [ $frozen, $cwe_pkey_id ] );
            }
            elsif ( $k =~ /^CWE-\d+$/ ) {
                push( @insert_entries, [ $frozen, $cwe_id ] );
            }
            else {
                carp "cwe id [$k] is unrecognized.\n";
            }
            print STDERR '.' if ( ++$count % 100 == 0 );
        }
    }

    #    $self->{sqlite}->do("BEGIN IMMEDIATE TRANSACTION");
    #    $insert_sth->execute(@$_) foreach @insert_entries;
    #    $update_sth->execute(@$_) foreach @update_entries;
    #    $self->{sqlite}->commit();

}

sub _important_fields {
    return qw(
      vuln:cve-id
      vuln:cvss
      vuln:cwe
      vuln:discovered-datetime
      vuln:published-datetime
      vuln:discovered-datetime
      vuln:last-modified-datetime
      vuln:security-protection
      vuln:vulnerable-software-list
    );

}

=head1 AUTHOR

C.J. Adams-Collier, C<< <cjac at f5.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-nist-nvd-store-sqlite3 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=NIST-NVD-Store-SQLite3>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc NIST::NVD::Store::SQLite3


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=NIST-NVD-Store-SQLite3>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/NIST-NVD-Store-SQLite3>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/NIST-NVD-Store-SQLite3>

=item * Search CPAN

L<http://search.cpan.org/dist/NIST-NVD-Store-SQLite3/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 F5 Networks, Inc.

CVE(r) and CWE(tm) are marks of The MITRE Corporation and used here with
permission.  The information in CVE and CWE are copyright of The MITRE
Corporation and also used here with permission.

Please include links for CVE(r) <http://cve.mitre.org/> and CWE(tm)
<http://cwe.mitre.org/> in all reproductions of these materials.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of NIST::NVD::Store::SQLite3
