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

#diag $output_path;

my $foo = MySQL::Workbench::DBIC->new(
    file           => $file,
    namespace      => $namespace,
    output_path    => $output_path,
    column_details => 1,
);
isa_ok( $foo, 'MySQL::Workbench::DBIC', 'object is type M::W::D' );

if( -e $output_path ){
    rmtree( $output_path );
}

(my $path       = $namespace) =~ s!::!/!;
my $subpath     = $output_path . '/' . $path;
my $result_path = $subpath . '/DBIC_Schema/Result';

make_path( $result_path );

copy $bin . '/Role.pm', $result_path . '/Role.pm' or die $!;
copy $bin . '/DBIC_Schema.pm', $subpath . '/DBIC_Schema.pm' or die $!;

$foo->create_schema;

my $role_class = $result_path . '/Role.pm';

ok -e $role_class;

my $check = q~print "This is some custom code!";~;

my $content = do{ local (@ARGV, $/) = $role_class; <> };
like $content, qr/\Q$check\E/;

my $schema_content = do { local (@ARGV, $/) = $subpath . '/DBIC_Schema.pm'; <> };
like $schema_content, qr/VERSION = 0.02/;
like $schema_content, qr/\Q$check\E/;

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

