#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Perl::Critic::MergeProfile;

main();

sub main {

    my $class = 'Perl::Critic::MergeProfile';

    note('write file');
    {
        my $obj = $class->new();

        my $input_string    = "global_1=global_val1\n[Policy1]\npolicy_1=policy_val1";
        my $expected_string = "global_1=global_val1\n\n[Policy1]\npolicy_1=policy_val1\n";
        $obj->read_string($input_string);

        my $tempdir = tempdir();
        my $file    = "$tempdir/file.ini";

        ok( $obj->write($file), 'write returns true' );
        is( _cat($file), $expected_string, '... and wrote the correct file' );

        #
        $obj->read_string('global_1=global_val1b');
        $expected_string = "global_1=global_val1b\n\n[Policy1]\npolicy_1=policy_val1\n";

        ok( $obj->write($file), 'write returns true' );
        is( _cat($file), $expected_string, '... and wrote the correct file' );
    }

    note('not initialized');
    {
        my $tempdir = tempdir();
        my $file    = "$tempdir/file.ini";

        my $obj = $class->new();
        like( exception { $obj->write($file) }, qr{No policy exists to write}, 'write_string throws an error (not initialized)' );

        $obj->{_config} = 'hello world';
        like( exception { $obj->write($file) }, qr{No policy exists to write}, 'write_string throws an error (not an object)' );

        $obj->{_config} = bless {}, 'Local::HelloWorld';
        like( exception { $obj->write($file) }, qr{No policy exists to write}, 'write_string throws an error (wrong object)' );
    }

    note('Config::Tiny error');
    {
        my $tempdir = tempdir();
        my $file    = "$tempdir/file.ini";

        my $obj = $class->new();

        my $input_string = "global_1=global_val1\n[Policy1]\npolicy_1=policy_val1";
        $obj->read_string($input_string);

        ${ $obj->{_config} }{"Invalid\nsection\nname"} = {};

        like( exception { $obj->write($file) }, qr{.*}, 'write throws an error if write of Config::Tiny fails' );
    }

    #
    done_testing();

    exit 0;
}

sub _cat {
    my ($file) = @_;

    if ( open my $fh, '<', $file ) {
        {
            local $/;
            my $content = <$fh>;
            return $content if close $fh;
        }
    }

    BAIL_OUT("Cannot read file '$file': $!");
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
