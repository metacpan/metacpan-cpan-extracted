package SDL2::Utils {

    # FFI utilities
    use strictures 2;
    use experimental 'signatures';
    use base 'Exporter::Tiny';
    our @EXPORT = qw[attach define deprecate has enum ffi];
    use Alien::libsdl2;
    use FFI::CheckLib;
    use FFI::Platypus 1.46;
    use FFI::Platypus::Memory qw[malloc strcpy free];
    use FFI::C;
    use FFI::C::Def;
    use FFI::C::ArrayDef;
    use FFI::C::StructDef;
    use FFI::Platypus::Closure;

    sub deprecate ($str) {
        warnings::warn( 'deprecated', $str ) if warnings::enabled('deprecated');
    }

    sub ffi () {
        CORE::state $ffi;
        if ( !defined $ffi ) {
            $ffi = FFI::Platypus->new(
                api          => 1,
                experimental => 2,
                lib          => [ Alien::libsdl2->dynamic_libs ]
            );
            FFI::C->ffi($ffi);
        }
        $ffi;
    }

    sub enum (%args) {
        my ($package) = caller();
        $package = 'SDL2::FFI';
        for my $tag ( keys %args ) {
            FFI::C->enum( $tag => $args{$tag}, { package => $package } );
            my $_tag = $tag;                                     # Simple rules:
            $_tag =~ s[^SDL_][];                                 # No SDL_XXXXX
            $_tag = lcfirst $_tag unless $_tag =~ m[^.[A-Z]];    # Save GLattr
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
                ffi->attach( [ $func => $package . '::' . $func ] => @{ $args{$tag}{$func} } );
                push @{ $SDL2::FFI::EXPORT_TAGS{$tag} }, $func;
            }
        }
    }

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
        FFI::C::StructDef->new(
            ffi,
            name     => $type,       # C type
            class    => $package,    # package
            nullable => 1,
            members  => \@_          # Keep order rather than use %args
        );
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
};
1;
