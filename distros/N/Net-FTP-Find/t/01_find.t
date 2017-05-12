#!perl
##!perl -T

use strict;
use warnings;

use Test::More;

use Test::FTP::Server;
use Test::TCP;
use File::Basename;

use Net::FTP::Find;
use File::Find;
use Cwd;

my $user = 'testid';
my $pass = 'testpass';

sub run_test {
    my ( $port, $target, $start_directory ) = @_;

    my $ftp = Net::FTP::Find->new( 'localhost', Port => $port );
    ok( $ftp, 'Create an object' );
    ok( $ftp->login( $user, $pass ), 'Login' );

    $ftp->cwd($start_directory) if $start_directory;

    foreach my $k ( '__PACKAGE__::name', '__PACKAGE__::dir', '_' ) {
        ( my $k_ftp = $k ) =~ s/__PACKAGE__/Net::FTP::Find/;
        ( my $k_fs  = $k ) =~ s/__PACKAGE__/File::Find/;
        foreach my $no_chdir ( 0 .. 1 ) {
            foreach my $bydepth ( 0 .. 1 ) {
                no strict 'refs';

                my %files_ftp = ();
                my $status    = $ftp->find(
                    {   'wanted' => sub {
                            $files_ftp{$$k_ftp} = 1,;
                        },
                        'no_chdir' => $no_chdir,
                        'bydepth'  => $bydepth,
                    },
                    $target
                );
                ok( $status,
                    "Return value (no_chdir => $no_chdir, bydepth => $bydepth)"
                );

                my %files_fs = ();
                my $orig_cwd = getcwd();
                chdir($start_directory) if $start_directory;
                find(
                    {   'wanted' => sub {
                            $files_fs{$$k_fs} = 1;
                        },
                        'no_chdir' => $no_chdir,
                        'bydepth'  => $bydepth,
                    },
                    $target
                );
                chdir($orig_cwd) if $start_directory;

                is_deeply( \%files_ftp, \%files_fs,
                    "\$$k_ftp (no_chdir => $no_chdir, bydepth => $bydepth)" );
            }
        }
    }

    {
        my %files_ftp = ();
        my $status    = $ftp->find(
            {   'wanted' => sub {
                    $files_ftp{$_} = 1;
                },
                'no_chdir'  => 1,
                'max_depth' => 1,
            },
            $target
        );
        ok( $status, "Return value: max_depth" );
        is_deeply(
            \%files_ftp,
            {   "$target"         => 1,
                "$target/testdir" => 1,
            },
            'max_depth'
            )
    }

    {
        my %files_ftp = ();
        my $status    = $ftp->find(
            {   'wanted' => sub {
                    $files_ftp{$_} = 1;
                },
                'no_chdir'  => 1,
                'min_depth' => 0,
            },
            $target
        );
        ok( $status, "Return value: min_depth" );
        is_deeply(
            \%files_ftp,
            {   "$target/testdir"              => 1,
                "$target/testdir/0"            => 1,
                "$target/testdir/testfile.txt" => 1,
            },
            'min_depth'
        );
    }

    ok( $ftp->quit, 'Quit' );
}

test_tcp(
    server => sub {
        my $port = shift;

        Test::FTP::Server->new(
            'users' => [
                {   'user' => $user,
                    'pass' => $pass,
                    'root' => '/',
                }
            ],
            'ftpd_conf' => {
                'port'              => $port,
                'daemon mode'       => 1,
                'run in background' => 0,
            },
        )->run;
    },
    client => sub {
        my $port = shift;

        subtest 'Absolute path' => sub {
            ( my $target = Cwd::realpath(__FILE__) ) =~ s/\.t$//;
            run_test( $port, $target );
        };

        subtest 'Relative path' => sub {
            ( my $target = Cwd::realpath(__FILE__) ) =~ s/\.t$//;
            run_test( $port, basename($target), dirname($target) );
        };
    }
);

done_testing;

1;
