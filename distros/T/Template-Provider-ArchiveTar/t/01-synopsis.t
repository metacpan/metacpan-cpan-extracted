#!perl -w
use strict;
use Test::More;
use Template::Provider::ArchiveTar;

SKIP: {
    if( !eval { require Archive::Dir; 1 }) {
        plan skip_all => "Archive::Dir not found, skipping tests";
        exit
    };
    
    plan( tests => 2 );
};
my $dir = Archive::Dir->new( 't/' );

my $merged = Template::Provider::ArchiveTar->new({
    archive => Archive::Dir->new( 't/' ),
});

my($template,$error) = $merged->fetch('01-synopsis.t');
is $error, undef, "No error";
ok $template, "We have the content";