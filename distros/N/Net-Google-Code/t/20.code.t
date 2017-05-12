#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;
use Test::MockModule;
use FindBin qw/$Bin/;
use File::Slurp;
use_ok('Net::Google::Code');

my $homepage_file     = "$Bin/sample/20.code.html";
my $downloads_file    = "$Bin/sample/20.code.downloads.html";
my $download_file     = "$Bin/sample/10.download.html";

my $wikis_file    = "$Bin/sample/11.wikis.html";
my $wiki_svn_file = "$Bin/sample/11.TestPage.wiki";
my $wiki_file = "$Bin/sample/11.TestPage.html";

my $mock = Test::MockModule->new('Net::Google::Code');
$mock->mock(
    'fetch',
    sub {
        shift;
        my $url = shift;
        if ( $url =~ /downloads/ ) {
            read_file( $downloads_file );
        }
        elsif ( $url =~ /wiki/ ) {
            read_file( $wikis_file );
        }
        else {
            read_file( $homepage_file );
        }
    }
);

my $mock_downloads = Test::MockModule->new('Net::Google::Code::Download');
$mock_downloads->mock( 'fetch', sub { read_file($download_file) } );

my $name = 'net-google-code';
my $project = Net::Google::Code->new( project => $name );

is( $project->base_url, "http://code.google.com/p/$name/", 'default url' );
is( $project->base_svn_url, "http://$name.googlecode.com/svn/", 'svn url' );
is( $project->project, $name, 'project name' );

$project->load;
is_deeply( $project->owners, ['sunnavy'] );
is_deeply( $project->members, [ 'jessev', 'fayland' ] );
like $project->description, qr/Net\:\:Google\:\:Code/;
is_deeply( $project->labels, [ 'perl' ] );
is $project->summary, 'a simple client library for google code';

isa_ok( $project->issue,    'Net::Google::Code::Issue' );
isa_ok( $project->download, 'Net::Google::Code::Download' );
isa_ok( $project->wiki,     'Net::Google::Code::Wiki' );


# test downloads
$project->load_downloads;
is( scalar @{ $project->downloads }, 2, 'have 2 downloads' );
my $download = $project->downloads->[1];
isa_ok( $download, 'Net::Google::Code::Download' );
is( $download->name, 'Net-Google-Code-0.01.tar.gz', 'download name' );
is( $download->size, '37.4 KB', 'download size' );


# test wikis
my $mock_wiki = Test::MockModule->new('Net::Google::Code::Wiki');
$mock_wiki->mock(
    'fetch',
    sub {
        shift;
        my $url = shift;
        if ( $url =~ /svn/ ) {
            read_file($wiki_svn_file);
        }
        else {
            read_file($wiki_file);
        }
    }
);
$project->load_wikis;
is( scalar @{ $project->wikis }, 1, 'have 1 wiki' );
my $wiki = $project->wikis->[0];
is( $wiki->name, 'TestPage', 'wiki name' );
is( $wiki->summary, 'One-sentence summary of this page.', 'wiki summary' );
