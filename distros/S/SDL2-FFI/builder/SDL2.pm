package builder::SDL2 {
    use strict;
    use warnings;
    use experimental 'signatures';
    use HTTP::Tiny;
    use Path::Tiny qw[path];
    use Archive::Extract;
    #
    use ExtUtils::CBuilder;
    #
    use Config;
    use Module::Build::Tiny;
    #
    use Carp::Always;
    use Alien::gmake;
    #
    $|++;
    #
    #$ENV{TSDL2} = './temp/';
    #
    my $basedir  = Path::Tiny->cwd;    #->child('sdl_libs');
    my $tempdir  = $ENV{TSDL2} ? $basedir->child( $ENV{TSDL2} ) : Path::Tiny->tempdir();
    my $sharedir = $basedir->child('share');

    #`rm -rf $sharedir`;
    #
    my $quiet = $ENV{QSDL2} // 0;
    #
    #die $sharedir;
    #
    my @libraries   = qw[SDL2 SDL2_image SDL2_mixer SDL2_ttf  SDL2_gfx];
    my %libversions = (                                                  # Allow custom lib versions
        SDL2       => $ENV{VSDL2}       // '2.0.16',
        SDL2_mixer => $ENV{VSDL2_mixer} // '2.0.4',
        SDL2_ttf   => $ENV{VSDL2_ttf}   // '2.0.15',
        SDL2_image => $ENV{VSDL2_image} // '2.0.5',
        SDL2_gfx   => $ENV{VSDL2_gfx}   // '1.0.4'
    );
    my %sdl2_urls = (
        SDL2       => 'https://www.libsdl.org/release/SDL2-%s%s',
        SDL2_mixer => 'https://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-%s%s',
        SDL2_ttf   => 'https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-%s%s',
        SDL2_image => 'https://www.libsdl.org/projects/SDL_image/release/SDL2_image-%s%s',
        SDL2_gfx   => 'https://github.com/a-hurst/sdl2gfx-builds/releases/download/%s/SDL2_gfx-%s%s'
    );
    my %override_urls = (    # Allow custom download URLs for libs (github releases, tags, etc.)
        ( defined $ENV{DSDL2}       ? ( SDL2       => $ENV{DSDL2} )       : () ),
        ( defined $ENV{DSDL2_mixer} ? ( SDL2_mixer => $ENV{DSDL2_mixer} ) : () ),
        ( defined $ENV{DSDL2_ttf}   ? ( SDL2_ttf   => $ENV{DSDL2_ttf} )   : () ),
        ( defined $ENV{DSDL2_image} ? ( SDL2_image => $ENV{DSDL2_image} ) : () ),
        ( defined $ENV{DSDL2_gfx}   ? ( SDL2_gfx   => $ENV{DSDL2_gfx} )   : () ),
        libwebp => 'http://storage.googleapis.com/downloads.webmproject.org/releases/webp/%s.tar.gz'
    );
    #
    my ( $cflags, $lflags )
        = $sharedir->child('config.ini')->is_file ?
        $sharedir->child('config.ini')->lines( { chomp => 1, count => 2 } ) :
        ();
    #
    sub SDL_Build () {
        my $action = @ARGV && $ARGV[0] =~ /\A\w+\z/ ? shift @ARGV : 'build';
        if ( $action eq 'build' ) {
            my $x64 = $Config{ptrsize} == 8;
            if (
                !$sharedir->is_dir

                #|| $sharedir->child('lib')->children < 4
            ) {
                buildDLLs( $^O, $x64 );
                build_api_wrapper( $^O, $x64 );
            }
            build_api_wrapper( $^O, $x64 ) if -d '.git';    # Always build during dev...
        }
        Module::Build::Tiny::Build();
    }

    sub SDL_Build_PL {
        my $meta = Module::Build::Tiny::get_meta();
        printf "Creating new 'Build' script for '%s' version '%s'\n", $meta->name, $meta->version;

        #my $dir = $meta->name eq 'Module-Build-Tiny' ? "use lib 'lib';" : '"./";';
        Module::Build::Tiny::write_file( 'Build',
            "#!perl\nuse lib '.';\nuse builder::SDL2;\nbuilder::SDL2::SDL_Build();\n" );
        Module::Build::Tiny::make_executable('Build');
        my @env
            = defined $ENV{PERL_MB_OPT} ?
            Module::Build::Tiny::split_like_shell( $ENV{PERL_MB_OPT} ) :
            ();
        Module::Build::Tiny::write_file( '_build_params',
            Module::Build::Tiny::encode_json( [ \@env, \@ARGV ] ) );
        $meta->save(@$_) for ['MYMETA.json'], [ 'MYMETA.yml' => { version => 1.4 } ];
    }

    sub buildDLLs ( $platform_name, $x64 ) {
        for my $d ( $tempdir, $sharedir ) {

            #$d->remove_tree( { safe => 0, verbose => !$quiet } );
            $d->mkpath( { verbose => !$quiet } );
        }
        $sharedir->child('lib')->mkpath( { verbose => !$quiet } );
        $sharedir->child('bin')->mkpath( { verbose => !$quiet } );
        if ( 'MSWin32' eq $platform_name ) {
            my $http = HTTP::Tiny->new;
            for my $lib (@libraries) {

                # Download zip archive containing library
                my $libversion = $libversions{$lib};

                # https://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.5-win32-x86.zip
                # https://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.52.0.5
                #my $liburl = sprintf $sdl2_urls{$lib},
                #    $lib eq 'SDL2_gfx' ?
                #    ( $libversion, $libversion, $x64 ? '-win32-x64.zip' : '-win32-x86.zip' ) :
                #    $lib ne 'SDL2' ? ( $libversion, $x64 ? '-win32-x64.zip' : '-win32-x86.zip' ) :
                #    ( 'devel-' . $libversion, '-mingw.tar.gz' );
                my $liburl = sprintf $sdl2_urls{$lib},
                    $lib eq 'SDL2_gfx' ?
                    ( $libversion, $libversion, $x64 ? '-win32-x64.zip' : '-win32-x86.zip' ) :
                    ( 'devel-' . $libversion, '-mingw.tar.gz' );
                printf 'Downloading %s %s... ', $lib, $libversion;
                my $sourcepath = fetch_source( $liburl,
                    $tempdir->child( Path::Tiny->new($liburl)->basename ) );
                if ($sourcepath) {
                    if ( $lib eq 'SDL2_gfx' ) {
                        warn 'HERE!!!!!!!!!!!!!!!!!!!!!';
                        warn $sourcepath->child('SDL2_gfx.dll')->absolute->stringify;
                        warn $sharedir->child( 'bin', 'SDL2_gfx.dll' )->absolute->stringify;

                        #sleep 120;
                        $sourcepath->child('SDL2_gfx.dll')
                            ->move( $sharedir->child( 'bin', 'SDL2_gfx.dll' ) );
                        $sharedir->child( 'bin', 'SDL2_gfx.dll' )->chmod('0755');

                        #sleep 120;
                    }
                    elsif ( $sourcepath->child('Makefile')->is_file ) {
                        my $orig_path = Path::Tiny->cwd->absolute;
                        chdir $sourcepath;

                        #system Alien::gmake->exe, 'install-package',
                        #    'arch=' . ( $x64 ? 'i686-w64-mingw32' : 'x86_64-w64-mingw32' ),
                        #    'prefix=' . $sharedir->absolute->stringify;
                        # collect files sizes
                        my $sizes
                            = $sourcepath->child( $x64 ? 'x86_64-w64-mingw32' : 'i686-w64-mingw32' )
                            ->visit(
                            sub {
                                my ( $path, $state ) = @_;
                                my $rel = $path->relative(
                                    $sourcepath->child(
                                        $x64 ? 'x86_64-w64-mingw32' : 'i686-w64-mingw32'
                                    )
                                );
                                my $dest = $sharedir->child($rel);
                                if ( $path->is_dir ) {
                                    warn $dest;

                                    #use Data::Dump;
                                    #ddx $dest->mkpath({ verbose => !$quiet, chmod => '0755' });
                                    return;
                                }
                                $dest->touchpath;
                                $path->copy( $sharedir->child($rel) );
                                $state->{$rel} = -s $path;
                            },
                            { recurse => 1 }
                            );
                        my $prefix = $sharedir->absolute->stringify;
                        $sharedir->child( 'bin', 'sdl2-config' )
                            ->edit_raw( sub {s[^prefix=.*][prefix=${prefix}]smg} );
                        $sharedir->child( 'bin', 'sdl2-config' )->chmod('0755');
                        $sharedir->child( 'lib', 'libSDL2.la' )
                            ->edit_raw( sub {s[^libdir=.*][prefix=${prefix}/lib]smg} );
                        $sharedir->child( 'lib', 'libSDL2main.la' )
                            ->edit_raw( sub {s[^libdir=.*][libdir=${prefix}/lib]smg} );
                        $sharedir->child( 'lib', 'pkgconfig', 'sdl2.pc' )
                            ->edit_raw( sub {s[^prefix=.*][prefix=${prefix}]smg} );
                        chdir $orig_path;
                    }
                    else {
                        #$sourcepath->child('Makefile')->is_file
                        #$sourcepath->child('SDL2_gfx.dll')->absolute->stringify;
                        #$sharedir->child( 'bin', 'SDL2_gfx.dll' )->absolute->stringify;
                        #sleep 120;
                        for my $kid ( $sourcepath->children(qr/.*\.dll/) ) {
                            warn $kid;
                            my $dest = $sharedir->child( 'bin', $kid->basename );
                            warn $dest;
                            $dest->touchpath;
                            $kid->copy($dest);
                            $dest->chmod('0755');
                        }
                    }
                }

                #else {
                #    die 'oops!';
                #}
            }
            $cflags
                = ( $x64 ? '-m64' : '-m32' ) .
                ' -Dmain=SDL_main -I' . $sharedir->child('include')->absolute .
                ' -I' . $sharedir->child( 'include', 'SDL2' )->absolute;
            $lflags = ( $x64 ? '-m64' : '-m32' ) . ' -L' .
                $sharedir->child('lib')->absolute . ' -lSDL2main -lSDL2 -lSDL2_mixer -mwindows ';

#' -Wl,--dynamicbase -Wl,--nxcompat -lm -ldinput8 -ldxguid -ldxerr8 -luser32 -lgdi32 -lwinmm -limm32 -lole32 -loleaut32 -lshell32 -lsetupapi -lversion -luuid ';
# TODO: store in config file:
# cflags = '-I'
#ld flags = '-lmingw32 -lSDL2main -lSDL2 -ggdb3 -O0 --std=c99 -lSDL2_image -lm  -Wall'
        }
        else {
            my $suffix = '.tar.gz';    # source code

            # Set required environment variables for custom prefix
            my %buildenv      = %ENV;
            my $pkgconfig_dir = $sharedir->child( 'lib', 'pkgconfig' );
            my $builtlib_dir  = $sharedir->child('lib');
            my $include_dir   = $sharedir->child('include');
            #
            $buildenv{PKG_CONFIG_PATH} .= $pkgconfig_dir->absolute;
            $buildenv{LD_LIBRARY_PATH} .= $builtlib_dir->absolute;
            $buildenv{LDFLAGS}         .= '-L' . $builtlib_dir->absolute;
            $buildenv{CPPFLAGS}
                .= '-I' . $include_dir->absolute . ' -I' . $include_dir->parent->absolute;
            #
            my $outdir = $sharedir->child('download');    #Path::Tiny->tempdir;
            $sdl2_urls{SDL2_gfx} = 'http://www.ferzkopp.net/Software/SDL2_gfx/SDL2_gfx-%s%s';
            for my $lib (@libraries) {
                my $libversion = $libversions{$lib};
                printf 'Downloading %s %s... ', $lib, $libversion;
                my $liburl = $override_urls{$lib} // sprintf $sdl2_urls{$lib}, $libversion, $suffix;
                my $libfolder  = $lib . '-' . $libversion;
                my $sourcepath = fetch_source( $liburl,
                    $tempdir->child( Path::Tiny->new($liburl)->basename ) );
                if ( !$sourcepath ) {
                    die 'something went wrong!';
                }

                # Check for any external dependencies and set correct build order
                my @dependencies;
                my @ignore = (
                    'libvorbisidec'    # only needed for special non-standard builds
                );
                my @build_first = qw[zlib harfbuzz];
                my @build_last  = qw[libvorbis opusfile flac];
                my $ext_dir     = $sourcepath->child('external');
                if ( $ext_dir->is_dir ) {
                    my @dep_dirs = $ext_dir->children();
                    my ( @deps_first, @deps, @deps_last );
                    for my $dep ( grep { $_->is_dir } @dep_dirs ) {
                        my $dep_path = $ext_dir->child($dep);
                        next if !$dep_path->is_dir;
                        my ( $depname, $depversion ) = split '-', $dep->basename;
                        next if grep { $_ eq $depname } @ignore;
                        if ( grep { $_ eq $depname } @build_first ) {
                            push @deps_first, $dep;
                        }
                        elsif ( grep { $_ eq $depname } @build_last ) {
                            push @deps_last, $dep;
                        }
                        else { push @deps, $dep }
                    }
                    @dependencies = ( @deps_first, @deps, @deps_last );
                }

                # Build any external dependencies
                my %extra_args
                    = ( opusfile => ['--disable-http'], freetype => ['--enable-freetype-config'] );
                for my $dep (@dependencies) {
                    my ( $depname, $depversion ) = split '-', $dep;
                    my $dep_path = $ext_dir->child($dep);
                    if ( defined $override_urls{$depname} ) {
                        printf "======= Downloading alternate source for %s =======\n", $dep;
                        my $liburl = sprintf $override_urls{$depname}, $dep;
                        path($dep_path)->move( $dep_path . '_bad' );
                        $dep_path
                            = fetch_source( $liburl,
                            $ext_dir->child( Path::Tiny->new($liburl)->basename ),
                            );
                    }
                    printf "======= Compiling %s dependency %s =======\n", $lib, $dep;
                    my $xtra_args;
                    if ( grep { $_ eq $depname } keys %extra_args ) {
                        $xtra_args = $extra_args{$depname};
                    }
                    die 'Error building ' . $dep
                        unless make_install_lib( $dep_path, $sharedir, \%buildenv, $xtra_args );
                    printf "\n======= %s built sucessfully =======\n", $dep;
                }

                # Build the library
                printf "======= Compiling %s %s =======\n", $lib, $libversion;
                my $xtra_args = ();
                $xtra_args = [ '--with-ft-prefix=' . $sharedir->absolute ] if $lib eq 'SDL2_ttf';
                die 'Error building ' . $lib
                    unless make_install_lib( $sourcepath, $sharedir, \%buildenv, $xtra_args );
                printf "\n======= %s %s built sucessfully =======\n", $lib, $libversion;
                chdir $basedir->absolute;
            }

            # TODO: store in config file
            #chdir $basedir->child('share', 'bin');
            #warn `./sdl2_config --prefix=%s --cflags`;
            #warn `./sdl2_config --prefix=%s --libs`;
            chdir $sharedir->child( 'lib', 'pkgconfig' );
            $ENV{PKG_CONFIG_PATH} .= $sharedir->child( 'lib', 'pkgconfig' )->absolute;
            $cflags = $sharedir->child('include')->absolute . ' ' .
                `pkg-config sdl2.pc SDL2_gfx.pc SDL2_image.pc SDL2_mixer.pc SDL2_ttf.pc --cflags`;
            chomp $cflags;
            $lflags
                = `pkg-config sdl2.pc SDL2_gfx.pc SDL2_image.pc SDL2_mixer.pc SDL2_ttf.pc --libs`;
            chomp $lflags;
            chdir $basedir->absolute;
        }
        $sharedir->child('config.ini')->spew_raw("$cflags\n$lflags");
    }

    sub make_install_lib ( $src_path, $prefix, $buildenv, $extra_args = () ) {
        my $orig_path = Path::Tiny->cwd->absolute;
        local %ENV = %$buildenv;
        chdir $src_path;
        my $success = 0;
        for my $cmd (
            [ './configure', ( $quiet ? '--silent' : () ), '--prefix=' . $prefix ],
            [ Alien::gmake->exe, ( $quiet ? '--silent' : () ), '-j10' ],
            [ Alien::gmake->exe, ( $quiet ? '--silent' : () ), 'install' ]
        ) {
            if ( $cmd->[0] eq './configure' && $extra_args ) {
                push @$cmd, @$extra_args;
            }
            $success = 1 if system(@$cmd) == 0;
            if ( $? == -1 ) {
                print "failed to execute: $!\n";
                last;
            }
            elsif ( $? & 127 ) {
                printf "child died with signal %d, %s coredump\n", ( $? & 127 ),
                    ( $? & 128 ) ? 'with' : 'without';
                last;
            }
            else {
                printf "child exited with value %d\n", $? >> 8;
            }
        }
        chdir $orig_path;
        return $success;
    }

    sub fetch_source ( $liburl, $outfile ) {
        CORE::state $http //= HTTP::Tiny->new();

        #printf '%s => %s ... ', $liburl, $outfile;
        $outfile->parent->mkpath;
        my $response = $http->mirror( $liburl, $outfile, {} );
        if ( $response->{success} ) {    #ddx $response;
            CORE::say 'okay';
            my $outdir = $outfile->parent

                #->child(
                #		$outfile->basename('.tar.gz', '.zip'))
                ;
            printf 'Extracting to %s... ', $outdir;
            my $ae = Archive::Extract->new( archive => $outfile );
            if ( $ae->extract( to => $outdir ) ) {
                CORE::say 'okay';
                return Path::Tiny->new( $ae->extract_path );
            }
            else {
                CORE::say 'oops!';
            }
        }
        else {
            CORE::say 'oops!';

            #warn $liburl;
            #use Data::Dump;
            #ddx($response);
        }
    }

    sub build_api_wrapper ( $platform_name, $x64 ) {
        my $c = $basedir->child( 'src', 'api_wrapper.cpp' );
        use FFI::Build;
        my $libperl = `perl -MExtUtils::Embed -e ldopts`;
        chomp $libperl;
        my $idk = `perl -MExtUtils::Embed -e ccopts`;
        chomp $idk;
        my $build = FFI::Build->new(
            'api_wrapper',
            cflags  => $idk . $cflags . ' -fPIC -I' . path( $Config{archlibexp}, 'CORE' ),
            dir     => $sharedir->child('lib')->absolute->stringify,
            libs    => $lflags . ( $platform_name eq 'MSWin32' ? $libperl : '' ),
            source  => [ $c->absolute->stringify ],
            verbose => $quiet ? 0 : 2
        );

        # $lib is an instance of FFI::Build::File::Library
        my $lib = $build->build;

        #my $ffi = FFI::Platypus->new( api => 1 );
        # The filename will be platform dependant, but something like libfrooble.so or frooble.dll
        #$ffi->lib( $lib->path );
        warn $lib;
        return $lib;
    }
}
1;
