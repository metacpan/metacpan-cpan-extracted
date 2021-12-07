package SDL2::Utils {

    # FFI utilities
    use strict;
    use warnings;
    use experimental 'signatures';
    use base 'Exporter::Tiny';
    our @EXPORT = qw[attach define deprecate has enum ffi is threads_wrapped load_lib];
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
    sub threads_wrapped () {    # Fake thread safe

        #loaded_libs('api_wrapper');
        1;
    }
    my $loaded_libs;

    sub loaded_libs ($name) {
        defined $loaded_libs->{$name} ? 1 : 0;
    }
    my %libs;
    my %prereq = (

        # Windows... this matters in Windows...
        SDL2_image  => [qw[SDL2 jpeg png16 tiff webp zlib1]],
        SDL2_ttf    => [qw[SDL2 freetype]],
        api_wrapper => [qw[SDL2 SDL2_mixer]],
        SDL2_mixer  => [qw[]],                                  # TODO
        freetype    => [qw[zlib1]]
    );

    sub load_lib ($name) {
        $libs{all}{$name} // return;                # This should be a fatal error
        load_lib($_) for @{ $prereq{$name} // [] }; # Recurse!
        my $_cdd = "\0" x 1024;                     # for Windows and SDL2_ttf
        CORE::state $SetDllDirectoryA;              # https://github.com/BindBC/bindbc-sdl/issues/10
        CORE::state $GetDllDirectoryA;
        if ( $^O eq 'MSWin32' ) {
            if ( !defined $SetDllDirectoryA ) {
                ffi()->lib( 'Kernel32.dll', undef );
                $SetDllDirectoryA = ffi()->function( SetDllDirectoryA => ['string'] => 'bool' );
            }
            if ( !defined $GetDllDirectoryA ) {
                ffi()->lib( 'Kernel32.dll', undef );
                $GetDllDirectoryA
                    = ffi()->function( GetDllDirectoryA => [ 'int', 'string' ] => 'int' );
            }
            $_cdd = undef if !$GetDllDirectoryA->call( length $_cdd, $_cdd );
            $SetDllDirectoryA->call(
                Path::Tiny->new( $libs{all}{$name} )->parent->absolute->stringify );
        }

        #warn sprintf 'Loading %s => %s', $name, $libs{all}{$name} // '[missing]';
        ffi()->lib( $libs{all}{$name} );
        $SetDllDirectoryA->call($_cdd) if $^O eq 'MSWin32' && defined $_cdd;
        $loaded_libs = {
            map {
                path($_)->basename(qw[.so .dylib .dll]) =~ m[^(?:lib)?(.+)(\-.+)?$];
                $1 => $_
            } grep {defined} ffi()->lib()
        };
    }

    sub ffi () {
        CORE::state $ffi;
        if ( !defined $ffi ) {
            my $distdir = Path::Tiny->new( dist_dir('SDL2-FFI') );
            my $root    = path(__FILE__)->absolute->parent(3)->realpath;
            #
            my @libs = (
                $distdir->child('lib')->children(qr[\.(so|dylib|dll)$]),
                $distdir->child('bin')->children(qr[\.(so|dylib|dll)$])
            );
            my %loaded_libs = map {
                path($_)->basename(qw[.so .dylib .dll]) =~ m[^((?:lib)?(.+?)(\-\d+)?)$];
                $2 => $_
            } @libs;
            %libs = (
                sdl => {
                    map {
                        path($_)->basename(qw[.so .dylib .dll]) =~ m[^((?:lib)?(.+?)(\-\d+)?)$];
                        $2 => $_
                    } map { /SDL/ ? $loaded_libs{$_} : () } keys %loaded_libs
                },
                api_wrapper =>
                    [ sort map { /api_wrapper/ ? $loaded_libs{$_} : () } keys %loaded_libs ],
                pre => [
                    sort map { /^(?:lib)?(?!.*(SDL|thread).+).+$/ ? $loaded_libs{$_} : () }
                        keys %loaded_libs
                ],
                all => \%loaded_libs
            );

            #$lines // return;
            if ( defined(&Test2::V0::diag) ) {
                my $lines = $distdir->child('config.ini');
                my ( $cflags, $lflags )
                    = $lines->is_file ? $lines->lines_raw( { chomp => 1 } ) :
                    ( '', '' );    # hope for the best!
                $cflags = '-I' . $distdir->child( 'include', 'SDL2' )->relative . ' ' . $cflags;
                $lflags = '-L' . $distdir->child('lib')->absolute . ' ' . $lflags;
                my $Win32 = $^O eq 'MSWin32';
                #
                eval { Test2::V0::diag( 'dist_dir: ' . $distdir ) };
                warn $@ if $@;
                eval { Test2::V0::diag( 'libs: ' . $lflags ) };
                warn $@ if $@;
                eval { Test2::V0::diag( 'cflags: ' . $cflags ) };
                warn $@ if $@;
                require Data::Dump;
                eval { Test2::V0::diag( 'libs: ' . join '; ', @libs ); };

                #Data::Dump::ddx(
                #    \{ api => 2, experimental => 2, lib => [ Alien::libsdl2->dynamic_libs ] } );
            }
            {
                $ffi = FFI::Platypus->new(
                    api          => 2,
                    experimental => 2,
                    lib          => [

                        #$libs{all}{thread_wrapper}
                        #SDL2.dll
                        #SDL2_image
                        #SDL2_mixer
                        #SDL2_ttf
                        #SDL2_gfx
                        #SDL2_ttf
                        #@{ $libs{pre} }, @{ $libs{sdl} }, @{ $libs{wrapper} },
                    ]
                );

                #warn join ', ', $ffi->lib;
                #$loaded_libs
                #    = { map { path($_)->basename(qw[.so .dylib .dll]) =~ m[^lib(.+)$]; $1 => 1 }
                #        $ffi->lib };
                #		use Data::Dump;
                #
                #ddx $loaded_libs;
                FFI::C->ffi($ffi);
            }
        }
        $ffi;
    }

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
        $package = 'SDL2::FFI' unless

            # Known knowns
            $package eq 'SDL2::Image' ||
            $package eq 'SDL2::TTF'   ||
            $package eq 'SDL2::Mixer' ||
            $package eq 'SDL2::GFX';
        #
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
            no strict 'refs';
            push @{ ${"${package}::EXPORT_TAGS"}{$_tag} },
                sort map { ref $_ ? ref $_ eq 'CODE' ? $_->() : $_->[0] : $_ } @{ $args{$tag} };
        }
    }

    sub attach (%args) {
        my ($package) = caller();
        $package = 'SDL2::FFI' unless

            # Known knowns
            $package eq 'SDL2::Image' ||
            $package eq 'SDL2::TTF'   ||
            $package eq 'SDL2::Mixer' ||
            $package eq 'SDL2::GFX';
        for my $tag ( sort keys %args ) {
            for my $func ( sort keys %{ $args{$tag} } ) {

                #use Data::Dump;
                #warn sprintf 'ffi->attach( %s => %s);', $func,
                #    Data::Dump::dump( @{ $args{$tag}{$func} } )
                #    if ref $args{$tag}{$func}[1] && ref $args{$tag}{$func}[1] eq 'ARRAY'
                #;
                my $perl = $func;
                $perl =~ s[^Bundle_][];
                ffi->attach( [ $func => $package . '::' . $perl ] => @{ $args{$tag}{$func} } );
                no strict 'refs';
                push @{ ${"${package}::EXPORT_TAGS"}{$tag} }, $perl

                    #@{ ${"${package}::{EXPORT_TAGS}{$tag}"} }, $perl;
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
        $package = 'SDL2::FFI' unless

            # Known knowns
            $package eq 'SDL2::Image' ||
            $package eq 'SDL2::TTF'   ||
            $package eq 'SDL2::Mixer' ||
            $package eq 'SDL2::GFX';
        for my $tag ( keys %args ) {

            #print $_->[0] . ' ' for sort { $a->[0] cmp $b->[0] } @{ $Defines{$tag} };
            #no strict 'refs';
            ref $_->[1] eq 'CODE' ?

                #constant->import( $package . '::' .$_->[0] => $_->[1]->() ) : #
                sub { no strict 'refs'; *{ $package . '::' . $_->[0] } = $_->[1] }
                ->() :
                constant->import( $package . '::' . $_->[0] => $_->[1] )
                for @{ $args{$tag} };
            no strict 'refs';
            push    #@{

                #${"${package}::EXPORT_TAGS"}{$tag}
                #},
                @{ ${"${package}::EXPORT_TAGS"}{$tag} },
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
    #
    ffi();    # auto-init
};
1;
