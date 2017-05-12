#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use File::Spec;
use File::Basename;
use File::Temp qw(tempfile);
use JSON;

use_ok 'OTRS::OPM::Maker::Command::sopm';

diag $OTRS::OPM::Maker::Command::sopm::VERSION;

my $dir       = File::Spec->rel2abs( dirname __FILE__ );
my $json_file = File::Spec->catfile( $dir, 'Test.json' );
my $json      = do{ local (@ARGV, $/ ) = $json_file; <> };
my $perl      = JSON->new->decode( $json );

delete $perl->{database};

my @files = <$dir/*.sopm>;
unlink @files;

my @files_check = <$dir/*.sopm>;
ok !@files_check;

my @checks = (
    {
        database => [
            {
                "type"=> "TableCreate",
                "version"=> 0,
                "name"=> "opar_test",
                "columns"=> [
                    { "name"=> "id", "required"=> "true", "auto_increment"=> "true", "type"=> "INT", "primary_key"=> "true" },
                ],
            }
        ],
        exception => 'INT is not allowed in TableCreate. Allowed types: BIGINT, DATE, DECIMAL, INTEGER, LONGBLOB, SMALLINT, VARCHAR',
    },
    {
        database => [
            {
                "type"=> "ColumnAdd",
                "version"=> 0,
                "name"=> "opar_test",
                "columns"=> [
                    { "name"=> "id", "required"=> "true", "auto_increment"=> "true", "type"=> "ANYTHING", "primary_key"=> "true" },
                ],
            }
        ],
        exception => 'ANYTHING is not allowed in ColumnAdd. Allowed types: BIGINT, DATE, DECIMAL, INTEGER, LONGBLOB, SMALLINT, VARCHAR',
    },
    {
        database => [
            {
                "type"=> "ColumnChange",
                "version"=> 0,
                "name"=> "opar_test",
                "columns"=> [
                    { "name"=> "id", "required"=> "true", "auto_increment"=> "true", "type"=> "INT", "primary_key"=> "true" },
                ],
            }
        ],
        exception => 'INT is not allowed in ColumnChange. Allowed types: BIGINT, DATE, DECIMAL, INTEGER, LONGBLOB, SMALLINT, VARCHAR',
    },
);

for my $test ( @checks ) {
    $perl->{database} = $test->{database};

    my ($fh, $conf) = tempfile( CLEANUP => 0 );
    my $json_conf   = JSON->new->encode( $perl );
    print $fh $json_conf;
    close $fh;

    my $string = $test->{exception};
    throws_ok{ OTRS::OPM::Maker::Command::sopm::execute( undef, { config => $conf }, [ $dir ] ) } qr/\Q$string\E/, $string;

    unlink $conf;
    ok !-e $conf;
}

done_testing();
