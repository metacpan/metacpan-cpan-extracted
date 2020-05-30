#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use FindBin ();
use Test::LongString;

use MySQL::Workbench::DBIC;

my $bin         = $FindBin::Bin;
my $file        = $bin . '/test.mwb';
my $namespace   = 'MyApp::DB';
my $output_path = $bin . '/Test' . $$;

my $foo = MySQL::Workbench::DBIC->new(
    file        => $file,
    output_path => $output_path,
    namespace   => $namespace,
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
ok( -e $subpath . '/DBIC_Schema/Result/Gefa_User.pm', 'Gefa_User' );
ok( -e $subpath . '/DBIC_Schema/Result/UserRole.pm', 'UserRole' );
ok( -e $subpath . '/DBIC_Schema/Result/Role.pm', 'Role' );

my $content = do{ local (@ARGV, $/) = $subpath . '/DBIC_Schema/Result/UserRole.pm'; <> };
like_string $content, qr/sub sqlt_deploy_hook/;

like_string $content,
    qr/add_index\( \s* 
        type \s*   => \s* "normal", \s*
        name \s*   => \s* "fk_Gefa_User_has_Role_Role1_idx", \s*
        fields \s* => \s* \['RoleID'\]
    /xms;

like_string $content, qr/
    ^=head1 \s+ DEPLOYMENT \s+
    ^=head2 \s+ sqlt_deploy_hook \s+
    ^These \s indexes \s are \s added \s to \s the \s table \s during \s deployment \s+
    ^=over \s+ 4 \s+
    ^=item \s \* \s fk_Gefa_User_has_Role_Role1_idx \s+
    ^=item \s \* \s fk_Gefa_User_has_Role_Gefa_User_idx \s+
    ^=back \s+
    ^=cut
/xms;

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

