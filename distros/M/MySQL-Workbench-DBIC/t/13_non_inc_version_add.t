#!perl -T

use strict;
use warnings;

use Test::More;
use FindBin ();

BEGIN {
	use_ok( 'MySQL::Workbench::DBIC' );
}

#use MySQL::Workbench::DBIC::FakeDBIC;

my $bin         = $FindBin::Bin;
my $file        = $bin . '/uppercase.mwb';
my $namespace   = 'MyApp::DB';
my $output_path = $bin . '/Test';

my $foo = MySQL::Workbench::DBIC->new(
    file        => $file,
    output_path => $output_path,
    namespace   => $namespace,
    version_add => 2,
    uppercase   => 1,
    schema_name => 'Schema',
    column_details => 1,
);

isa_ok( $foo, 'MySQL::Workbench::DBIC', 'object is type M::W::D' );

if( -e $output_path ){
    rmtree( $output_path );
}

$foo->create_schema;

(my $path = $namespace) =~ s!::!/!;

my $subpath = $output_path . '/' . $path;
ok( -e $subpath , 'Path ' . $subpath . ' created' );
ok( -e $subpath . '/Schema.pm', 'Schema' );
ok( -e $subpath . '/Schema/Result/UserGroups.pm', 'UserGroups' );

my $lib_path = _untaint_path($output_path);

my $version;
eval {
    require MyApp::DB::Schema;
    $version = MyApp::DB::Schema->VERSION;
} or diag $@;
is $version, 2, 'check version';

$foo->create_schema;
eval{
    delete $INC{"MyApp/DB/Schema.pm"};
    require MyApp::DB::Schema;
    $version = MyApp::DB::Schema->VERSION;
} or diag $@;
is $version, 4, 'check version 4';

$foo->create_schema;
eval{
    delete $INC{"MyApp/DB/Schema.pm"};
    require MyApp::DB::Schema;
    $version = MyApp::DB::Schema->VERSION;
} or diag $@;
is $version, 6, 'check version 6';

eval{
    rmtree( $output_path );
    $output_path = _untaint_path( $output_path );
    rmdir $output_path;
};

done_testing();

sub rmtree{
    my ($path) = @_;
    $path = _untaint_path( $path );
    opendir my $dir, $path or die $!;
    while( my $entry = readdir $dir ){
        next if $entry =~ /^\.?\.$/;
        my $file = File::Spec->catfile( $path, $entry );
        $file = _untaint_path( $file );
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

sub _untaint_path{
    my ($path) = @_;
    ($path) = ( $path =~ /(.*)/ );
    # win32 uses ';' for a path separator, assume others use ':'
    my $sep = ($^O =~ /win32/i) ? ';' : ':';
    # -T disallows relative directories in the PATH
    $path = join $sep, grep !/^\./, split /$sep/, $path;
    return $path;
}
