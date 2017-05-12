use strict;
use warnings;

use File::Basename;
use File::Find;
use File::Temp;
use Log::Any::Adapter ( 'Stdout', log_level => 'debug' );
use Template::Overlay;
use Template::Resolver;
use Test::More tests => 20;

BEGIN { use_ok('Template::Overlay') }

my $test_dir = dirname( File::Spec->rel2abs($0) );

sub test_dir {
    return File::Spec->catdir( $test_dir, @_ );
}

sub test_file {
    return File::Spec->catfile( $test_dir, @_ );
}

sub overlay {
    my ( $config, $overlays, $no_base, %options ) = @_;

    my $dir = File::Temp->newdir();
    Template::Overlay->new(
        $no_base ? $dir : test_dir('base'),
        Template::Resolver->new($config),
        key => 'T'
    )->overlay( $overlays, to => $dir, %options );

    my %results = ();
    find(
        sub {
            if ( -f $File::Find::name && $File::Find::name =~ /^$dir\/(.*)$/ ) {
                $results{$1} = do { local ( @ARGV, $/ ) = $_; <> };
            }
        },
        $dir
    );
    return \%results;
}

sub spurt {
    my ( $content, $file, %options ) = @_;
    my $write_mode = $options{append} ? '>>' : '>';
    open( my $handle, $write_mode, $file )
        || croak("unable to open [$file]: $!");
    print( $handle $content );
    close($handle);
}

sub slurp {
    my ($file) = @_;
    return do { local ( @ARGV, $/ ) = $file; <> };
}

my $config = {
    what   => { this   => { 'is'    => 'im not sure' } },
    todays => { random => { thought => 'something awesome' } }
};
my $results = overlay( $config, test_dir('overlay1') );
like( $results->{'a.txt'}, qr/This is a test\.(?:\r|\n|\r\n)/, 'overlay1 a.txt' );
like(
    $results->{'subdir/b.txt'},
    qr/Random thought for today is: something awesome(?:\r|\n|\r\n)/,
    'overlay1 subdir/b.txt'
);
like( $results->{'c.txt'}, qr/Another file full of nonsense\.(?:\r|\n|\r\n)/, 'overlay1 c.txt' );

$config = {
    what   => { this   => { 'is'    => 'im not sure' } },
    todays => { random => { thought => 'something awesome' } }
};
$results = overlay( $config, test_dir('overlay2') );
like( $results->{'a.txt'}, qr/This is a im not sure\.(?:\r|\n|\r\n)/, 'overlay2 a.txt' );
like(
    $results->{'subdir/b.txt'},
    qr/Random thought for today is: fumanchu\.(?:\r|\n|\r\n)/,
    'overlay2 subdir/b.txt'
);
like( $results->{'c.txt'}, qr/Another file full of nonsense\.(?:\r|\n|\r\n)/, 'overlay2 c.txt' );

$config = {
    what   => { this   => { 'is'    => 'im not sure' } },
    todays => { random => { thought => 'something awesome' } }
};
$results = overlay( $config, [ test_dir('overlay1'), test_dir('overlay2') ] );
like( $results->{'a.txt'}, qr/This is a im not sure\.(?:\r|\n|\r\n)/, 'overlay1,overlay2 a.txt' );
like(
    $results->{'subdir/b.txt'},
    qr/Random thought for today is: something awesome(?:\r|\n|\r\n)/,
    'overlay1,overlay2 subdir/b.txt'
);
like(
    $results->{'c.txt'},
    qr/Another file full of nonsense\.(?:\r|\n|\r\n)/,
    'overlay1,overlay2 c.txt'
);

$config = {
    what   => { this   => { 'is'    => 'im not sure' } },
    todays => { random => { thought => 'something awesome' } }
};
$results = overlay( $config, [ test_dir('overlay2'), test_dir('overlay1') ] );
like( $results->{'a.txt'}, qr/This is a im not sure\.(?:\r|\n|\r\n)/, 'overlay2,overlay1 a.txt' );
like(
    $results->{'subdir/b.txt'},
    qr/Random thought for today is: something awesome(?:\r|\n|\r\n)/,
    'overlay2,overlay1 subdir/b.txt'
);
like(
    $results->{'c.txt'},
    qr/Another file full of nonsense\.(?:\r|\n|\r\n)/,
    'overlay2,overlay1 c.txt'
);

$results = overlay( $config, test_dir('overlay1'), 1 );
like(
    $results->{'subdir/b.txt'},
    qr/Random thought for today is: something awesome(?:\r|\n|\r\n)/,
    'overlay1 subdir/b.txt no base'
);

{
    my $callback_called;
    $results = overlay(
        $config,
        test_dir('overlay1'),
        1,
        resolver => sub {
            my ( $template, $file ) = @_;
            $callback_called = 1;
            spurt( "foo", $file );
            return 1;
        }
    );
    ok( $callback_called, 'callback called, processing stopped' );
    is( $results->{'subdir/b.txt'}, 'foo', 'callback overlay1 subdir/b.txt no base' );

    $callback_called = 0;
    $results         = overlay(
        $config,
        test_dir('overlay1'),
        1,
        resolver => sub {
            my ( $template, $file ) = @_;
            $callback_called = 1;
            return 0;
        }
    );
    ok( $callback_called, 'callback called, processing proceeded' );
    like(
        $results->{'subdir/b.txt'},
        qr/Random thought for today is: something awesome(?:\r|\n|\r\n)/,
        'callback override overlay1 subdir/b.txt no base'
    );
}

{
    my $temp_dir = File::Temp->newdir();
    my $base_dir = File::Spec->catdir( $temp_dir, 'base' );
    mkdir($base_dir);
    my $template_dir = File::Spec->catdir( $temp_dir, 'template' );
    mkdir($template_dir);
    my $overlay_dir = File::Spec->catdir( $temp_dir, 'overlay' );
    mkdir($overlay_dir);

    my $base_file = File::Spec->catfile( $base_dir, 'file.txt' );
    spurt( "foo", $base_file );
    chmod( 0644, $base_file );
    my $template_file = File::Spec->catfile( $template_dir, 'file.txt' );
    spurt( "bar", $template_file );
    chmod( 0755, $template_file );

    my $old_umask = umask(0027);
    eval {
        Template::Overlay->new( $base_dir, Template::Resolver->new( {} ) )
            ->overlay( $template_dir, to => $overlay_dir );
    };
    my $error = $@;
    umask($old_umask);
    ok( !$error, 'permission overlay' );
    my $overlay_file = File::Spec->catfile( $overlay_dir, 'file.txt' );
    is( "100750",
        sprintf( '%04o', ( stat($overlay_file) )[2] ),
        'mode set correctly when found in both base and template'
    );
}
