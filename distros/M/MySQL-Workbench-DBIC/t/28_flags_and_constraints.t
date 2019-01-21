#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use FindBin ();
use Test::LongString;

use MySQL::Workbench::DBIC;

my $bin             = $FindBin::Bin;
my $file            = $bin . '/flags.mwb';
my $namespace       = 'MyApp::DB';
my $output_path     = $bin . '/Test' . $$;

my $foo = MySQL::Workbench::DBIC->new(
    file           => $file,
    output_path    => $output_path,
    namespace      => $namespace,
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
ok( -e $subpath . '/DBIC_Schema.pm', 'Schema' );
ok( -e $subpath . '/DBIC_Schema/Result/role.pm', 'Role' );

my $content = do{ local (@ARGV, $/) = $subpath . '/DBIC_Schema/Result/role.pm'; <> };

like_string $content, qr{>add_unique_constraint\(\s*
    Rolename_UNIQUE \s+ => \s+ \[qw/Rolename/\]
}xms;

like_string $content, qr{
    RoleID \s+ => .*?
        extra \s+ => \s+ \{ \s*
            unsigned \s+ => \s+ 1, \s*
            zerofill \s+ => \s+ 1 \s*
        \}
}xms;

like_string $content, qr{
    Rolename \s+ => .*?
        extra \s+ => \s+ \{ \s*
            binary \s+ => \s+ 1 \s*
        \}
}xms;

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
