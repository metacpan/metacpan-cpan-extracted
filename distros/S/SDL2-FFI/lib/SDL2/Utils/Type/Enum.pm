package SDL2::Utils::Type::Enum {    # Cribbed from FFI::Platypus::Type::Enum
    use strict;
    use warnings;
    use constant 1.32 ();
    use 5.008001;
    use Ref::Util qw( is_plain_arrayref is_plain_hashref is_ref );
    use Scalar::Util qw( dualvar );
    use Carp qw( croak );

    # ABSTRACT: Custom platypus type for dealing with C enumerated types
    our $VERSION  = '0.07';                # VERSION
    our @CARP_NOT = qw( FFI::Platypus );

    sub ffi_custom_type_api_1 {
        my %config = defined $_[2] && is_plain_hashref $_[2] ? %{ splice( @_, 2, 1 ) } : ();
        my ( undef, undef, @values ) = @_;
        my $index = 0;
        my %str_lookup;
        my %int_lookup;
        my $prefix = defined $config{prefix} ? $config{prefix} : '';
        $config{rev} ||= 'str';
        ( $config{rev} =~ /^(int|str|dualvar)$/ ) or
            croak("rev must be either 'int', 'str', or 'dualvar'");
        $config{casing} ||= 'upper';
        ( $config{casing} =~ /^(upper|keep)$/ ) or croak("casing must be either 'upper' or 'keep'");

        foreach my $value (@values) {
            my $name;
            my @aliases;
            if ( is_plain_arrayref $value) {
                my %opt;
                if ( @$value % 2 ) {
                    ( $name, %opt ) = @$value;
                }
                else {
                    ( $name, $index, %opt ) = @$value;
                }
                @aliases = @{ delete $opt{alias} || [] };
                croak("unrecognized options: @{[ sort keys %opt ]}") if %opt;
            }
            elsif ( !is_ref $value) {
                $name = $value;
            }
            else {
                croak("not a array ref or scalar: $value");
            }
            if ( $index < 0 ) {
                $config{type} ||= 'senum';
            }
            if ( my $packages = $config{package} ) {
                foreach my $package ( is_plain_arrayref $packages ? @$packages : $packages ) {
                    foreach my $name ( $name, @aliases ) {
                        my $full = join '::', $package,
                            $prefix . ( $config{casing} eq 'upper' ? uc($name) : $name );
                        no strict 'refs';
                        ref $index eq 'CODE' ? *{$full} = $index :
                            constant->import( $full, $index );
                    }
                }
            }
            croak("$name declared twice") if exists $str_lookup{$name};
            $int_lookup{$index} = $name unless exists $int_lookup{$index};
            $str_lookup{$_}     = $index for @aliases;
            $str_lookup{$name}  = $index++;
        }
        $config{type} ||= 'enum';
        if ( defined $config{maps} ) {
            if ( is_plain_arrayref $config{maps} ) {
                @{ $config{maps} } = ( \%str_lookup, \%int_lookup, $config{type} );
            }
            else {
                croak("maps is not an array reference");
            }
        }
        my %type = (
            native_type    => $config{type},
            perl_to_native => sub {
                exists $str_lookup{ $_[0] }     ? $str_lookup{ $_[0] } :
                    exists $int_lookup{ $_[0] } ? $_[0] :
                    croak("illegal enum value $_[0]");
            }
        );
        if ( $config{rev} eq 'str' ) {
            $type{native_to_perl} = sub {
                exists $int_lookup{ $_[0] } ? $int_lookup{ $_[0] } : $_[0];
            }
        }
        elsif ( $config{rev} eq 'dualvar' ) {
            $type{native_to_perl} = sub {
                exists $int_lookup{ $_[0] } ? dualvar( $_[0], $int_lookup{ $_[0] } ) : $_[0];
            };
        }
        \%type;
    }
    1;
}
