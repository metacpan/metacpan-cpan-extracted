#!perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

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
                $swagger_file =~ s/markdown/swagger/;

                $files{ $File::Find::name } = $swagger_file;
            }
        },
        no_chdir => 1
    },
    catfile( qw/ t markdown / ),
);

plan skip_all => "No markdown files?" if ! %files;

foreach my $markdown_file ( sort keys %files ) {

    my $expected = read_text( $markdown_file );
    my $swagger  = Swagger2->new->load( $files{ $markdown_file } );
    my $s2md     = Swagger2::Markdown->new( swagger2 => $swagger );

    my $got = $s2md->markdown;

    local $TODO = 'multiple types'
        if $markdown_file =~ /data_structures\.md/;

    is_string( $got,$expected,$files{ $markdown_file } )
        || note $got;
}

done_testing();

# vim: ts=4:sw=4:et
