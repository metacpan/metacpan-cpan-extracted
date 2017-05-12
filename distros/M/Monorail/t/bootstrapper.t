#!perl

use Test::Spec;
use Test::Deep;

use Monorail::Bootstrapper;

describe 'A monorail bootstrapper' => sub {
    my ($sut, $output);

    before each => sub {
        open(my $output_fh, ">", \$output);
        $sut = Monorail::Bootstrapper->new(
            out_filehandle    => $output_fh,
            dbix_schema_class => 'My::Schema',
            dbix_schema_dsn   => 'dbi:SQLite:dbname=:memory:',
        );
    };

    it 'is creatable' => sub {
        cmp_deeply($sut, isa('Monorail::Bootstrapper'));
    };

    it 'can create a perl script' => sub {
        $sut->write_script_file;

    #    diag($output);
        pass();
    };
};

runtests;
