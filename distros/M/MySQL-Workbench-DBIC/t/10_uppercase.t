#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;
use FindBin ();

BEGIN {
	use_ok( 'MySQL::Workbench::DBIC' );
}

my $bin         = $FindBin::Bin;
my $file        = $bin . '/uppercase.mwb';
my $namespace   = 'MyApp::DB';
my $output_path = $bin . '/Test';

my $foo = MySQL::Workbench::DBIC->new(
    file        => $file,
    namespace   => $namespace,
    output_path => $output_path,
    uppercase   => 1,
);

isa_ok( $foo, 'MySQL::Workbench::DBIC', 'object is type M::W::D' );

if( -e $output_path ){
    rmtree( $output_path );
}

$foo->create_schema;

(my $path = $namespace) =~ s!::!/!;

my $subpath = $output_path . '/' . $path;
ok( -e $subpath , 'Path created' );
ok( -e $subpath . '/DBIC_Schema.pm', 'Schema' );
ok( -e $subpath . '/DBIC_Schema/Result/Users.pm', 'Users' );
ok( -e $subpath . '/DBIC_Schema/Result/UserGroups.pm', 'UserGroups' );
ok( -e $subpath . '/DBIC_Schema/Result/Groups.pm', 'Groups' );

eval{
    rmtree( $output_path );
    rmdir $output_path;
};

sub rmtree{
    my ($path) = @_;
    opendir my $dir, $path or die $!;
    while( my $entry = readdir $dir ){
        next if $entry =~ /^\.?\.$/;
        my $file = File::Spec->catfile( $path, $entry );
        if( -d $file ){
            rmtree( $file );
            rmdir $file;
        }
        else{
            unlink $file;
        }
    }
    closedir $dir;
}

