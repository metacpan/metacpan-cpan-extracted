#!perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use FindBin qw/ $Bin /;
use File::Find;
use File::Slurper qw/ read_text /;
use File::Spec::Functions qw/ catfile /;
use Swagger2;
use Swagger2::Markdown;

my %files;

find(
    {
        wanted => sub {
            if ( /\.md$/ ) {
                my $swagger_file = $File::Find::name;
                $swagger_file =~ s/\.md$/.yaml/;
                $swagger_file =~ s/api_blueprint/swagger/;

                $files{ $File::Find::name } = $swagger_file;
            }
        },
        no_chdir => 1
    },
    catfile( $Bin,qw/ api_blueprint / ),
);

plan skip_all => "No api_blueprint files?" if ! %files;

foreach my $api_blueprint_file ( sort keys %files ) {

    my $expected = read_text( $api_blueprint_file );
    my $swagger  = Swagger2->new->load( $files{ $api_blueprint_file } );
    my $s2md     = Swagger2::Markdown->new( swagger2 => $swagger );

    my $got = $s2md->api_blueprint;

    TODO: {
        local $TODO = $api_blueprint_file =~ /data_structures/
            ? "Broken by recent Swagger2 changes" : undef;
        is_string( $got,$expected,$files{ $api_blueprint_file } )
            || note $got;
    }
}

done_testing();

# vim: ts=4:sw=4:et
