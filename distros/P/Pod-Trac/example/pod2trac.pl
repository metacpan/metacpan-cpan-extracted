#!/usr/bin/perl -w

use strict;
use lib ( '../lib' );
use Pod::Trac;
use YAML ();
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

=head1 DESCRIPTION

A simple command line tool for adding your POD to a Trac.

Create a YAML config file, in  ~/.pod2trac, with the following

trac_name:
    url: http://full/url/trac
    user: your_user
    passwd: your_passwd

=cut

our $CONFFILE = "$ENV{HOME}/.pod2trac";
our %config   = ();
our %args;
my ( $passwd, $trac_url, $login );

GetOptions( \%args, "path=s", "file=s", "trac_name=s", "filter=s@", "help",
            "config=s", )
    or pod2usage( 2 );

$CONFFILE = $args{ config } if $args{ config };

pod2usage( 0 ) if $args{ help };

if ( !$args{ 'trac_name' } ) {
    print "You need to specify your trac name\n";
    pod2usage( 0 );
    exit;
}

%config = %{ YAML::LoadFile( $CONFFILE ) || {} };
foreach my $key ( keys %config ) {
    if ( $key eq $args{ trac_name } ) {
        $trac_url = $config{ $key }->{ url };
        $login    = $config{ $key }->{ user };
        $passwd   = $config{ $key }->{ passwd };
    }
}

if ( !defined $trac_url ) {
    print
        "Can't find you trac name in your config, here are yours trac name:\n";
    foreach my $key ( keys %config ) {
        print "\t - $key\n";
    }
    exit;
}

my $trac = Pod::Trac->new(
              { trac_url => $trac_url, login => $login, passwd => $passwd } );

if ( $args{ path } ) {
    $trac->from_path( { path   => $args{ path },
                        filter => $args{ filter } } );
    foreach my $page ( @{ $trac->{ created_path } } ) {
        print_result( $$page{ 'pod_rev' }, $$page{ 'pod_url' } );
    }
}

if ( $args{ file } ) {
    $trac->from_file( { file => $args{ file } } );
    print_result( $trac->pod_rev, $trac->pod_url );
}

sub print_result {
    my ( $rev, $url ) = @_;
    if ( $rev == 0 ) {
        print "new page created : " . $url . "\n";
    } else {
        print "page updated : " . $url . " (rev " . $rev . ")\n";
    }
}

=head1 NAME

pod2trac.pl - a command line for adding POD to Trac

=head1 SYNOPSIS

    pod2trac.pl --path=~/svk/local/ --trac_name=mymodules
    pod2trac.pl --path=~/svk/local/ --trac_name=mycompany --filter=pm --filter=pl
    pod2trac.pl --file=~/svk/local/MyModule/lib/MyModule.pm --trac_name=mycompany
    
=cut

