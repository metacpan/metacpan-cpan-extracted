#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use FindBin ();

BEGIN {
	use_ok( 'MySQL::Workbench::DBIC' );
}

my $bin         = $FindBin::Bin;
my $file        = $bin . '/view.mwb';
my $namespace   = 'MyApp::DB';
my $output_path = $bin . '/Test' . $$;

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
ok( -e $subpath . '/DBIC_Schema/Result/table1.pm', 'table1' );
ok( -e $subpath . '/DBIC_Schema/Result/table2.pm', 'table2' );
ok( -e $subpath . '/DBIC_Schema/Result/view1.pm', 'view1' );
ok( -e $subpath . '/DBIC_Schema/Result/view2.pm', 'view2' );

my $module  = $subpath . '/DBIC_Schema/Result/view2.pm';
my $content = do { local ( @ARGV, $/ ) = $module; <> };

like $content, qr{__PACKAGE__->table_class\('DBIx::Class::ResultSource::View'\);}, 'view result source';
like $content, qr{__PACKAGE__->result_source_instance->view_definition\(}, 'definition';
like $content, qr{
 CREATE \s+ VIEW \s+ `view2` \s+ AS \s+
    SELECT \s+ table1.cidr, \s+ col2, \s+ col3 \s+
    FROM \s+ table1 \s+
        INNER \s+ JOIN \s+ table2 \s+
            ON \s+ table1.cidr \s+ = \s+ table2.cidr;
}x, "SQL definition";

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

