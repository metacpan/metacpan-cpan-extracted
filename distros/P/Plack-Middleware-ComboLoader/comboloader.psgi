#!/usr/bin/env perl

use strict;
use warnings;

use Plack::Builder;
use Plack::App::File;

use Path::Class;
use Cwd;

use Data::Dump;
dd(\%ENV);

my $root = $ARGV[0] || getcwd;

my $app = Plack::App::File->new(root => $root)->to_app;

my $parent = Path::Class::Dir->new( $root );
my %roots  = ();

foreach my $child ( $parent->children ) {
    if ( -d $child && $child->basename !~ /^\./ ) {
        $roots{$child->basename} = $child;
        print "Serving " . $child->basename . " as a combo root\n";
    }
}

builder {
    enable "Plack::Middleware::ComboLoader",
        roots => \%roots;
    $app;
};

