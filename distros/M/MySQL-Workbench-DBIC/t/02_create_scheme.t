#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use FindBin ();

BEGIN {
	use_ok( 'MySQL::Workbench::DBIC' );
}

my $bin         = $FindBin::Bin;
my $file        = $bin . '/test.mwb';
my $namespace   = 'MyApp::DB';
my $output_path = $bin . '/Test';

my $foo = MySQL::Workbench::DBIC->new(
    file        => $file,
    namespace   => $namespace,
    output_path => $output_path,
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
ok( -e $subpath . '/DBIC_Schema/Result/Gefa_User.pm', 'Gefa_User' );
ok( -e $subpath . '/DBIC_Schema/Result/UserRole.pm', 'UserRole' );
ok( -e $subpath . '/DBIC_Schema/Result/Role.pm', 'Role' );

my $module  = $subpath . '/DBIC_Schema/Result/Role.pm';
my $content = do { local ( @ARGV, $/ ) = $module; <> };
like $content, qr{use base qw\(DBIx::Class\)}, 'Check correct inheritance';
like $content, qr{->load_components\( qw/PK::Auto Core/ \)}, 'Check correct component loading';

my $schema_content = do {
    local ( @ARGV, $/ ) = $subpath . '/DBIC_Schema.pm';
    <>;
};

like $schema_content, qr/->load_namespaces;/;

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

