#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use FindBin ();
use File::Copy;
use File::Path qw(make_path);

BEGIN {
	use_ok( 'MySQL::Workbench::DBIC' );
}

use MySQL::Workbench::DBIC::FakeDBIC;

my $bin         = $FindBin::Bin;
my $file        = $bin . '/test.mwb';
my $namespace   = 'MyApp::DB';
my $output_path = $bin . '/Test' . $$;

my $foo = MySQL::Workbench::DBIC->new(
    file           => $file,
    namespace      => $namespace,
    output_path    => $output_path,
    column_details => 1,
);
isa_ok( $foo, 'MySQL::Workbench::DBIC', 'object is type F::D::D' );

if( -e $output_path ){
    rmtree( $output_path );
}

my $result_path     = $output_path . '/MyApp/DB/DBIC_Schema/Result';
make_path( $result_path );

copy $bin . '/Role.pm', $result_path . '/Role.pm' or die $!;

$foo->create_schema;

(my $path = $namespace) =~ s!::!/!;

my $subpath = $output_path . '/' . $path;
my $role_class = $subpath . '/DBIC_Schema/Result/Role.pm';

ok -e $role_class;

my $check = q~print "This is some custom code!";~;

my $content = do{ local (@ARGV, $/) = $role_class; <> };
like $content, qr/\Q$check\E/;

eval{
    rmtree( $output_path );
    rmdir $output_path;
};

done_testing();

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

