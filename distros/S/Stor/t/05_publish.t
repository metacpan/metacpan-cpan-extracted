use strict;
use Test::More 0.98;

use Mock::Quick;

plan tests => 3;

use_ok('Stor');

my @storages = (Path::Tiny->tempdir(), Path::Tiny->tempdir(), Path::Tiny->tempdir(), Path::Tiny->tempdir(),);

my $sha = '557a65161f86c41c0672111dd7bdfc145b1068c6363596f8094af7d99106d16e';

subtest 'get without publish' => sub {
    my $stor = Stor->new(
        statsite      => qobj(),
        storage_pairs => [
            [ $storages[0]->stringify(), $storages[1]->stringify(), ],
            [ $storages[2]->stringify(), $storages[3]->stringify(), ],
        ],
    );

    my %render;
    my $c = qobj(
        param  => qmeth    { $sha },
        app    => qobj(log => qobj()),
        render => qmeth    { (undef, %render) = @_ },
        chi => qobj(
            get => qmeth { undef },
        ),
    );

    $stor->get($c);

    is_deeply(
        \%render,
        {
            status => 404,
            text =>
"Caught failure::stor::filenotfound: File '557a65161f86c41c0672111dd7bdfc145b1068c6363596f8094af7d99106d16e' not found\n"
        }
    );

    done_testing(1);
};

subtest 'get with publish' => sub {
    my $stor = Stor->new(
        statsite      => qobj(),
        storage_pairs => [
            [ $storages[0]->stringify(), $storages[1]->stringify(), ],
            [ $storages[2]->stringify(), $storages[3]->stringify(), ],
        ],
        rmq_publish_code => sub {
            is($_[0], $sha, 'publish');
        }
    );

    my %render;
    my $c = qobj(
        param  => qmeth    { $sha },
        app    => qobj(log => qobj()),
        render => qmeth    { (undef, %render) = @_ },
        chi => qobj(
            get => qmeth { undef },
        ),
    );

    $stor->get($c);

    is_deeply(
        \%render,
        {
            status => 404,
            text =>
"Caught failure::stor::filenotfound: File '557a65161f86c41c0672111dd7bdfc145b1068c6363596f8094af7d99106d16e' not found\n"
        }
    );

    done_testing(2);
};
