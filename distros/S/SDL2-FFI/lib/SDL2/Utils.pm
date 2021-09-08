package SDL2::Utils {

    # FFI utilities
    use strictures 2;
    use experimental 'signatures';
    use base 'Exporter::Tiny';
    our @EXPORT = qw[attach define deprecate has enum ffi is threads_wrapped];
    use Alien::libsdl2;
    use FFI::CheckLib;
    use FFI::Platypus 1.46;
    use FFI::Platypus::Memory qw[malloc strcpy free];
    use FFI::C;
    use FFI::C::Def;
    use FFI::C::ArrayDef;
    use FFI::C::StructDef;
    use FFI::C::UnionDef;
    use FFI::Platypus::Closure;
    use File::Spec::Functions qw[catdir canonpath rel2abs];
    use Path::Tiny qw[path];
    use File::Share qw[dist_dir];
    use Config;
    use SDL2::Utils::Type::Enum;
    use Ref::Util qw( is_ref is_plain_arrayref is_plain_hashref );

    sub deprecate ($str) {
        warnings::warn( 'deprecated', $str ) if warnings::enabled('deprecated');
    }

    #sub ver() {    # TODO: Remove in favor of SDL2::version
    #    CORE::state $ver;
    #    $ver // ffi()->function( SDL_GetVersion => ['SDL_Version'] )
    #        ->call( $ver = SDL2::Version->new() );
    #    $ver;
    #}
    #ddx( Alien::libsdl2->dynamic_libs );
    my $thread_safe = 0;
    sub threads_wrapped () {$thread_safe}    # Fake thread safe

    sub ffi () {
        CORE::state $ffi;
        if ( !defined $ffi ) {
            use FFI::Build;
            use FFI::Build::File::C;
            if ( defined(&Test2::V0::diag) ) {
                my $Win32 = $^O eq 'MSWin32';
                #
                #skip_all 'requires a shared object or DLL'
                #    unless Alien::libsdl2->dynamic_libs;
                #
                #  nasty hack
                #$ENV{LD_LIBRARY_PATH}   = Alien::libsdl2->dist_dir . '/lib';
                #$ENV{DYLD_LIBRARY_PATH} = Alien::libsdl2->dist_dir . '/lib';
                #
                eval { Test2::V0::diag( 'dist_dir: ' . Alien::libsdl2->dist_dir . '/lib' ) };
                warn $@ if $@;
                eval { Test2::V0::diag( 'libs: ' . Alien::libsdl2->libs ) };
                warn $@ if $@;
                eval { Test2::V0::diag( 'cflags: ' . Alien::libsdl2->cflags ) };
                warn $@ if $@;
                eval { Test2::V0::diag( 'cflags static: ' . Alien::libsdl2->cflags_static ) };
                warn $@ if $@;
                eval {
                    Test2::V0::diag( 'Dynamic libs: ' . join ':', Alien::libsdl2->dynamic_libs );
                };
                warn $@ if $@;
                eval { Test2::V0::diag( 'bin dir: ' . join( ' ', Alien::libsdl2->bin_dir ) ) };
                warn $@ if $@;
            }
            my $lib = undef;
            if (1) {
                my $root = path(__FILE__)->absolute->parent(3)->realpath;
                my $dir;    # eval { dist_dir('SDL2-FFI') };
                $dir //= $root->child('share')->realpath;
                my $c = $root->child('ffi/bundle.c');
                if ( defined(&Test2::V0::diag) ) {
                    eval { Test2::V0::diag( 'c file: ' . $c . ' | ' . ( -f $c ? '1' : '0' ) ) };
                }
                my $build = FFI::Build->new(
                    'bundle',
                    dir     => $dir,
                    alien   => ['Alien::libsdl2'],
                    source  => [$c],
                    libs    => [ Alien::libsdl2->libs_static() // Alien::libsdl2->dynamic_libs() ],
                    verbose => 2
                );
                $lib
                    = ( ( !-f $build->file->path ) ||
                        ( ( [ stat $build->file->path ]->[9] < [ stat $c ]->[9] ) ) ) ?
                    $build->build :
                    $build->file->path;

                #$lib
                #    = -f $build->file->path && -f $root->child('ffi/sdl2.c') &&
                #    [ stat $build->file->path ]->[9]
                #    >= [ stat( $root->child('ffi/sdl2.c') ) ]->[9] ? $build->file : $build->build;
                #    warn $lib;
                $thread_safe = defined $lib ? $lib : ();
                if ( defined(&Test2::V0::diag) ) {
                    eval { Test2::V0::diag( 'lib: ' . $lib . ' | ' . ( -f $lib ? '1' : '0' ) ); };
                }
            }
            {
                $ffi = FFI::Platypus->new(
                    api          => 2,
                    experimental => 2,
                    lib          => [ Alien::libsdl2->dynamic_libs, $lib, ]
                );
                FFI::C->ffi($ffi);
            }

            #$thread_safe = $ffi->bundle();
            #$lib //= $ffi->bundle;
            #if ( defined(&Test2::V0::diag) ) {
            #    eval {
            #        Test2::V0::diag( 'bundle: ' . $lib->path . ' | ' . ( -f $lib ? '1' : '0' ) );
            #    };
            #}
        }
        $ffi;
    }
    ffi();    # auto-init

    sub enumX {
        (undef) = shift;
        my $name   = defined $_[0] && !is_ref $_[0]           ? shift        : undef;
        my @values = defined $_[0] && is_plain_arrayref $_[0] ? @{ shift() } : ();
        my %config = defined $_[0] && is_plain_hashref $_[0]  ? %{ shift() } : ();
        my ( $class, $filename ) = caller;
        unless ( defined $name ) {
            $name = lcfirst [ split /::/, $class ]->[-1];
            $name =~ s/([A-Z]+)/'_' . lc($1)/ge;
            $name .= "_t";
        }
        my $ffi = FFI::C::_ffi_get($filename), $config{package} ||= $class;
        my @maps;
        $config{maps} = \@maps;
        my $rev = $config{rev} ||= 'str';

        #use Data::Dump;
        #ddx [$name, $rev, \%config, \@values];
        ffi->load_custom_type( 'SDL2::Utils::Type::Enum', $name, \%config, @values );
        my ( $str_lookup, $int_lookup, $type ) = @maps;

        #ddx [$name, $rev, $str_lookup, $int_lookup, $type];
        require FFI::C::Def;
        ffi->def(
            'FFI::C::EnumDef',
            $name,
            FFI::C::EnumDef->new(
                str_lookup => $str_lookup,
                int_lookup => $int_lookup,
                type       => $type,
                rev        => $rev,
            )
        );
    }

    sub enum (%args) {
        my ($package) = caller();
        $package = 'SDL2::FFI';
        for my $tag ( keys %args ) {

#use Data::Dump;
#ddx $args{$tag} if $tag eq 'WindowShapeMode';
#use Data::Dump;
#ddx $args{$tag};
#ddx @{$args{$tag}};
#my $enum =
#FFI::C->enum( $tag => $args{$tag}, { package => $package } );
#ffi->load_custom_type('SDL2::Utils::Type::Enum', $tag => { rev=>'int', package => $package, maps => \@maps } => $args{$tag} );
            enumX(
                ffi,
                $tag => $args{$tag},
                { rev => 'dualvar', package => $package, type => 'int', casing => 'keep' }
            );

            #ffi->load_custom_type(
            #    '::Enum',
            #    $tag,
            #    {ref => 'int', package => $package },
            #    @{$args{$tag}}
            #  #{ rev => 'int', package => 'Foo', prefix => 'FOO_' },
            #);
            my $_tag = $tag;                                     # Simple rules:
            $_tag =~ s[^SDL_][];                                 # No SDL_XXXXX
            $_tag = lcfirst $_tag unless $_tag =~ m[^.[A-Z]];    # Save GLattr

            #ddx $enum if  $tag eq 'WindowShapeMode';
            #            warn $_tag if $tag eq 'WindowShapeMode';
            push @{ $SDL2::FFI::EXPORT_TAGS{$_tag} },
                sort map { ref $_ ? ref $_ eq 'CODE' ? $_->() : $_->[0] : $_ } @{ $args{$tag} };
        }
    }

    sub enumD (%args) {
        my ($package) = caller();
        $package = 'SDL2::FFI';
        for my $tag ( keys %args ) {
            use Data::Dump;

#ddx $args{$tag};    # if $tag eq 'WindowShapeMode';
#use Data::Dump;
#warn $tag;
#ddx $args{$tag};
#ddx @{$args{$tag}};
#my $enum =
#FFI::C->enum( $tag => $args{$tag}, { package => $package } );
#ffi->load_custom_type('::Enum', $tag => { package => $package } => [$args{$tag}] );
#ffi->load_custom_type('SDL2::Utils::Type::Enum' => $tag => { ref => 'int', package => $package, casing => 'keep' }
#		, $args{$tag}
#);
            warn $tag;
            ffi->load_custom_type(
                'SDL2::Utils::Type::Enum', $tag, { rev => 'dualvar', package => $package },
                @{ $args{$tag} }

                    #{ rev => 'int', package => 'Foo', prefix => 'FOO_' },
            );
            my $_tag = $tag;                                     # Simple rules:
            $_tag =~ s[^SDL_][];                                 # No SDL_XXXXX
            $_tag = lcfirst $_tag unless $_tag =~ m[^.[A-Z]];    # Save GLattr

            #ddx $enum if  $tag eq 'WindowShapeMode';
            #            warn $_tag if $tag eq 'WindowShapeMode';
            push @{ $SDL2::FFI::EXPORT_TAGS{$_tag} },
                sort map { ref $_ ? ref $_ eq 'CODE' ? $_->() : $_->[0] : $_ } @{ $args{$tag} };
        }
    }

    sub attach (%args) {
        my ($package) = caller();
        $package = 'SDL2::FFI';
        for my $tag ( sort keys %args ) {
            for my $func ( sort keys %{ $args{$tag} } ) {

                #warn sprintf 'ffi->attach( %s => %s);', $func,
                #    Data::Dump::dump( @{ $args{$tag}{$func} } )
                #    if ref $args{$tag}{$func}[1] && ref $args{$tag}{$func}[1] eq 'ARRAY';
                my $perl = $func;
                $perl =~ s[^Bundle_][];
                ffi->attach( [ $func => $package . '::' . $perl ] => @{ $args{$tag}{$func} } );
                push @{ $SDL2::FFI::EXPORT_TAGS{$tag} }, $perl;
            }
        }
    }
    my %is;

    sub is ($is) {
        my ($package) = caller;
        $is{$package} = $is;
    }
    sub get_is ($package) { $is{$package} // '' }

    sub has (%args) {    # Should be hash-like
        my ($package) = caller;
        my $type = $package;
        $type =~ s[^SDL2::][SDL_];
        $type =~ s[::][_]g;

        #$class =~ s[^SDL_(.+)$]['SDL2::' . ucfirst $1]e;
        #warn sprintf '%-20s => %-20s%s', $name, $class, (
        #   -f sub ($package) { $package =~ m[::(.+)]; './lib/SDL2/' . $1 . '.pod' }
        #        ->($class) ? '' : ' (undocumented)'
        #);
        my @args = (
            ffi,
            name        => $type,       # C type
            class       => $package,    # package
            nullable    => 1,
            trim_string => 1,
            members     => \@_          # Keep order rather than use %args
        );
        get_is($package) eq 'Union' ? FFI::C::UnionDef->new(@args) : FFI::C::StructDef->new(@args);
    }

    sub define (%args) {
        my ($package) = caller();
        $package = 'SDL2::FFI';
        for my $tag ( keys %args ) {

            #print $_->[0] . ' ' for sort { $a->[0] cmp $b->[0] } @{ $Defines{$tag} };
            #no strict 'refs';
            ref $_->[1] eq 'CODE' ?

                #constant->import( $package . '::' .$_->[0] => $_->[1]->() ) : #
                sub { no strict 'refs'; *{ $package . '::' . $_->[0] } = $_->[1] }
                ->() :
                constant->import( $package . '::' . $_->[0] => $_->[1] )
                for @{ $args{$tag} };
            push @{ $SDL2::FFI::EXPORT_TAGS{$tag} },
                sort map { ref $_ ? $_->[0] : $_ } @{ $args{$tag} };
        }
    }
    #
    sub _tokenize_in ( $str, $pointers = 1 ) {    # TODO: reconciliation between this and _out
        my @ret;
        $str =~ s{
		\%
		\d*?
		(?<type> (?:[\+-]?[di]|0|x|X|u|f|F|e|E|a|A|g|G|n|p|s|c|lc|\d\[.+?\]))
 	}{
		push @ret, _conversion($+{type}, $pointers )}gexsm;
        @ret;
    }

    sub _tokenize_out ( $str, $pointers = 1 ) {
        my @ret;
        $str =~ s[
		%[\^\-\+\d\.#]*?(?<len>(?:\*.)?\*)?(?<type>[csdioxXufFeEaAgGnp])
 	][
		push @ret, _conversion($+{type}, $pointers, $+{len} // ())]gexsm;
        @ret;
    }

    sub _conversion ( $conv, $pointers = 1, $len = '' ) {
        my $count = () = $len =~ m[(\*)]msg;
        my $retval
            = $conv eq 'c' ? 'char' : $conv eq 's' ? 'string' : $conv eq '[' ? 'string' :    # set
            $conv eq 'd'   ? ( $pointers ? 'int*'   : 'int' ) :
            $conv eq 'i'   ? ( $pointers ? 'int*'   : 'int' ) :
            $conv eq 'u'   ? ( $pointers ? 'uint*'  : 'uint' ) :
            $conv eq 'o'   ? ( $pointers ? 'int*'   : 'int' ) :     # octal
            $conv eq 'x'   ? ( $pointers ? 'string' : 'int' ) :     # hex
            $conv eq 'X'   ? ( $pointers ? 'string' : 'int' ) :     # hex
            $conv eq 'n'   ? ( $pointers ? 'int*'   : 'int' ) :     # num of chars read so far
            $conv eq 'a'   ? ( $pointers ? 'float*' : 'float' ) :
            $conv eq 'A'   ? ( $pointers ? 'float*' : 'float' ) :
            $conv eq 'e'   ? ( $pointers ? 'float*' : 'float' ) :
            $conv eq 'E'   ? ( $pointers ? 'float*' : 'float' ) :
            $conv eq 'f'   ? ( $pointers ? 'float*' : 'float' ) :
            $conv eq 'F'   ? ( $pointers ? 'float*' : 'float' ) :
            $conv eq 'g'   ? ( $pointers ? 'float*' : 'float' ) :
            $conv eq 'G'   ? ( $pointers ? 'float*' : 'float' ) :
            $conv eq 'p'   ? 'opaque' :
            $conv eq 'lc'  ? 'wide_string' :
            $conv =~ /^\d/ ? 'string' :
            'broken: ' . $conv;
        $len ? ( ( map {'int'} 1 .. $count ), $retval ) : $retval;
    }
};
1;
