#!/usr/bin/perl

use strict;
use DBI;
use Log::Log4perl;
Log::Log4perl::init( 'log4perl.conf' );

use SPOPS::Initialize;

my $DBI_DSN  = 'DBI:Pg:dbname=test';
my $DBI_USER = 'username';
my $DBI_PASS = 'password';

my ( $DBH );

END {
    remove_demo_table();
}

{
    create_demo_table();
    fill_demo_table();

    my $config = {
      'demo' => {
         class               => 'My::Demo',
         isa                 => [ 'SPOPS::DBI' ],
         base_table          => 'spops_find_defaults',
         id_field            => 'email',
         field_discover      => 'yes',
         rules_from          => [ 'SPOPS::Tool::DBI::DiscoverField',
                                  'SPOPS::Tool::DBI::FindDefaults' ],
         find_default_id     => 'test@test.com',
         find_default_field  => [ 'language', 'country' ],
      },
    };
    SPOPS::Initialize->process({ config => $config });

    my $demo = My::Demo->new();
    print "Default for language: ($demo->{language})\n",
          "Default for country:  ($demo->{country})\n";
}


sub create_demo_table {
    My::Demo::global_datasource_handle();
    my $sql = <<DEMO;
CREATE TABLE spops_find_defaults (
  email       varchar(50) not null primary key,
  language    char(2) null,
  country     varchar(20) null
)
DEMO
    $DBH->do( $sql );
}


sub fill_demo_table {
    my $sql = <<'NEW';
INSERT INTO spops_find_defaults ( email, language, country )
VALUES                          ( 'test@test.com', 'en', 'USA' )
NEW
    $DBH->do( $sql );
}

sub remove_demo_table {
    $DBH->do( 'DROP TABLE spops_find_defaults' );
}


sub My::Demo::global_datasource_handle {
    return $DBH if ( $DBH );
    $DBH = DBI->connect( $DBI_DSN, $DBI_USER, $DBI_PASS,
                         { RaiseError => 1, PrintError => 0 } );
    die "Cannot connect! $DBI::errstr" unless ( $DBH );
    return $DBH;
}
