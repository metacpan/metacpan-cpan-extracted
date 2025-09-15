use Test::More;
use Mojolicious::Lite;
use lib 'lib';

# Test missing required configuration
eval {
    plugin 'Inertia' => {};
};
like($@, qr/version/, 'Dies when version is missing');

eval {
    plugin 'Inertia' => { version => '1.0.0' };
};
like($@, qr/layout/, 'Dies when layout is missing');

# Test with valid configuration
eval {
    plugin 'Inertia' => {
        version => '1.0.0',
        layout => '<div></div>'
    };
};
is($@, '', 'Lives with required configuration');

# Test with file-based layout (Mojo::File object)
eval {
    use Mojo::File;

    # Create fixtures directory if it doesn't exist
    my $dir = Mojo::File->new('t/fixtures');
    $dir->make_path unless -d $dir;

    my $file = Mojo::File->new('t/fixtures/layout.html');
    $file->spew('<div id="app" data-page="<%= $data_page %>"></div>');

    plugin 'Inertia' => {
        version => '2.0.0',
        layout => $file
    };

    unlink 't/fixtures/layout.html';
    rmdir 't/fixtures';
};
is($@, '', 'Lives with Mojo::File layout');

done_testing();