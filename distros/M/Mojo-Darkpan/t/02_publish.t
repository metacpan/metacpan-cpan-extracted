use strict;
use warnings;
use Test::More 0.98;
use Test::Mojo;
use Archive::Tar;
use File::Temp ();
use Mojo::File qw(path);
use Mojo::IOLoop;
use MIME::Base64 qw(encode_base64);

my $work = path( File::Temp::tempdir( CLEANUP => 1 ) );
my $repo = $work->child('repo')->make_path;

$ENV{DARKPAN_DIRECTORY} = $repo->to_string;
delete $ENV{$_} for grep { /^DARKPAN_(AUTH|CONFIG|PATH|COMPRESS)/ } keys %ENV;

# build a minimal distribution tarball
sub dist {
    my ( $name, $version, $package ) = @_;
    my $tar = Archive::Tar->new;
    ( my $file = $package ) =~ s{::}{/}g;
    $tar->add_data( "$name-$version/lib/$file.pm",
        "package $package;\nour \$VERSION = '$version';\n1;\n" );
    $tar->add_data( "$name-$version/META.json",
        qq({"name":"$name","version":"$version","meta-spec":{"version":2}}) );
    my $out = $work->child("$name-$version.tar.gz");
    $tar->write( $out->to_string, COMPRESS_GZIP );
    return $out;
}

sub wait_for_index {
    my $index = $repo->child( 'modules', '02packages.details.txt.gz' );
    my $deadline = time + 30;
    Mojo::IOLoop->one_tick until -f $index || time > $deadline;
    return -f $index;
}

my $t = Test::Mojo->new('Mojo::Darkpan');

subtest 'publish without a module' => sub {
    $t->post_ok('/publish')->status_is(400)->content_like(qr/bad or missing parameters/);
};

subtest 'publish an uploaded file creates the index' => sub {
    my $tarball = dist( 'Foo-Bar', '0.01', 'Foo::Bar' );

    $t->post_ok( '/publish' => form =>
          { HIDDENNAME => 'test', pause99_add_uri_httpupload => { file => $tarball->to_string } } )
      ->status_is(200)->content_is('OK');

    ok -f $repo->child(qw(authors id T TE TEST Foo-Bar-0.01.tar.gz)), 'archive stored under the uppercased author';
    ok wait_for_index(), 'index created by the reindex subprocess';
};

subtest 'publish by module path updates the index' => sub {
    my $tarball = dist( 'Foo-Bar', '0.02', 'Foo::Bar' );
    $t->post_ok( '/publish' => form => { module => $tarball->to_string, author => 'test' } )
      ->status_is(200)->content_is('OK');

    ok -f $repo->child(qw(authors id T TE TEST Foo-Bar-0.02.tar.gz)), 'second version stored';
};

subtest 'list shows packages and other versions' => sub {
    my $tarball = dist( 'Foo-BarBaz', '1.00', 'Foo::BarBaz' );
    $t->post_ok( '/publish' => form => { module => $tarball->to_string, author => 'test' } )
      ->status_is(200);

    $t->get_ok('/list')->status_is(200);
    my $list = $t->tx->res->json;

    my $bar  = $list->{'T/TE/TEST/Foo-Bar-0.02.tar.gz'};
    my $baz  = $list->{'T/TE/TEST/Foo-BarBaz-1.00.tar.gz'};
    ok $bar && $baz, 'the latest release of each distribution is listed';
    ok !$list->{'T/TE/TEST/Foo-Bar-0.01.tar.gz'}, 'superseded release is not listed on its own';
    is $bar->{version}, '0.02', 'version';
    is_deeply $bar->{other_versions}, ['Foo-Bar-0.01.tar.gz'],
      'other_versions holds only earlier releases of the same distribution';
    is_deeply $baz->{other_versions}, [], 'similarly named distribution has no other versions';
};

subtest 'basic auth' => sub {
    local $ENV{DARKPAN_AUTH_REALM}    = 'test';
    local $ENV{DARKPAN_AUTH_username} = 'user';
    local $ENV{DARKPAN_AUTH_password} = 'secret';

    my $auth = sub { { Authorization => 'Basic ' . encode_base64( $_[0], '' ) } };
    my $tarball = dist( 'Auth-Dist', '0.01', 'Auth::Dist' );
    my %form    = ( module => $tarball->to_string, author => 'test' );

    $t->post_ok( '/publish' => form => \%form )->status_is(401);
    ok !-f $repo->child(qw(authors id T TE TEST Auth-Dist-0.01.tar.gz)), 'nothing stored without credentials';

    $t->post_ok( '/publish' => $auth->('user:wrong') => form => \%form )->status_is(401);

    $t->post_ok( '/publish' => $auth->('user:secret') => form => \%form )->status_is(200)->content_is('OK');
    ok -f $repo->child(qw(authors id T TE TEST Auth-Dist-0.01.tar.gz)), 'stored with credentials';

    $t->get_ok('/list')->status_is(401);
    $t->get_ok( '/list' => $auth->('user:secret') )->status_is(200);
};

done_testing;
