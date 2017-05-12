# -*-perl-*-

# $Id: 10_hash_file.t,v 3.1 2004/02/26 02:02:29 lachoy Exp $

use File::Copy;
use Test::More tests => 10;

do "t/config.pl";

sub clean_config { unlink( 't/test.perl' ); File::Copy::cp( 't/hash_file_test.perl', 't/test.perl' ); }
sub cleanup      { unlink( 't/test.perl' ); unlink( 't/test-new.perl' );  }

{
    require_ok( 'SPOPS::HashFile' );

    # Test for reading file in using 'read' permission
    {
        clean_config();
        my $config = eval { SPOPS::HashFile->new({ filename => 't/test.perl',
                                                   perm     => 'read' }) };
        ok( ! $@, 'HashFile read (read permission)' );
    }

    # Test for reading file in using 'write' permission
    {
        clean_config();
        my $config = eval { SPOPS::HashFile->new({ filename => 't/test.perl',
                                                   perm     => 'write' } ) };
        ok( ! $@, 'HashFile read (write permission)' );
    }

    # Tests for opening file that doesn't existing using 'new' permission
    # (we want the second one to fail)
    {
        clean_config();
        my $config = eval { SPOPS::HashFile->new({ filename => 't/not_exist.perl',
                                                   perm     => 'new' } ) };
        ok( ! $@, 'HashFile create (new permission)' );

        my $config_two = eval { SPOPS::HashFile->new( { filename => 't/not_exist.perl',
                                                        perm     => 'write' } ) };
        ok( $@ =~ /^Cannot create object without existing file or 'new' permission/,
            'HashFile create (write permission)' );
    }

    {
        clean_config();
        my $config = SPOPS::HashFile->new({ filename => 't/test.perl', 
                                            perm     => 'write' });
        $config->{smtp_host} = '192.168.192.1';
        $config->{dir}->{download} = '$BASE/downloads';
        eval { $config->save };
        ok( ! $@, 'HashFile save' );
    }

    {
        clean_config();
        my $config = SPOPS::HashFile->new({ filename => 't/test.perl',
                                            perm     => 'write' });
        eval { $config->remove };
        ok( ! $@ && ! -f 't/test.perl', 'HashFile remove' );
    }

    {
        clean_config();
        my $config = SPOPS::HashFile->new({ filename => 't/test.perl',
                                            perm     => 'read' });
        my $newconf = eval { $config->clone({ filename => 't/test-new.perl',
                                              perm     => 'new' }) };
        ok( ! $@, 'HashFile clone' );

        my $conf_obj    = tied %{ $config };
        my $newconf_obj = tied %{ $newconf };
        ok( $newconf_obj->{filename} ne $conf_obj->{filename} &&
            $newconf_obj->{perm}     ne $conf_obj->{perm}, 'HashFile clone compare' );

        $newconf->{dir}->{base} = '~/otherapp/spops.perl';
        eval { $newconf->save };
        ok( ! $@, 'Clone save' );
    }

    cleanup();
}
