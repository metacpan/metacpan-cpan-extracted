package Salvation::TC::Parser::PP;

use strict;
use warnings;
use boolean;

our $VERSION = 0.12;

=head2 tokenize_type_str_impl( Str str, Maybe[HashRef( Bool :loose )] options? )

Разбирает строку с именем типа C<str> и возвращает ArrayRef[HashRef]
с найденными токенами.

Краткое описание опций в C<options>:

=over

=item loose

Не выполнять дополнительных проверок возможности токена на основе внешних данных.

=back

=cut

sub tokenize_type_str_impl {

    my ( $class, $str, $options ) = @_;

    $options //= {};

    $str =~ s/\s+/ /gs;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;

    my @chars = split( //, $str );
    my @stack = ();
    my $word  = '';
    my $parameterizable_type = '';

    while( defined( my $char = shift( @chars ) ) ) {

        next if( $char eq ' ' );

        if( ( $char eq '[' ) && ( $word ne 'Maybe' ) ) {

            if( $options -> { 'loose' } ) {

                $parameterizable_type = $word;

            } else {

                $parameterizable_type = $class -> load_parameterizable_type_class( $word );

                die( "Can't parameterize type ${word}" ) if( $parameterizable_type eq '' );
            }
        }

        if( $char eq '|' ) {

            if( $word eq '' ) {

                unless(
                    exists $stack[ $#stack ] -> { 'maybe' }
                    || exists $stack[ $#stack ] -> { 'class' }
                    || exists $stack[ $#stack ] -> { 'signed' }
                    || exists $stack[ $#stack ] -> { 'length' }
                ) {

                    die( 'Invalid type string' );
                }

            } else {

                push( @stack, { type => $word } );

                $word = '';
            }

        } elsif( $char eq '[' ) {

            my $cnt    = 1;
            my $substr = '';

            while( defined( my $subchar = shift( @chars ) ) ) {

                ++$cnt if( $subchar eq '[' );
                --$cnt if( $subchar eq ']' );

                last if( $cnt == 0 );

                $substr .= $subchar;
            }

            die( 'Invalid type parameterization' ) if( ( $substr eq '' ) || ( $word eq '' ) );

            if( $parameterizable_type eq '' ) {

                push( @stack, { maybe => tokenize_type_str_impl( $class, $substr, $options ) } );

            } else {

                push( @stack, {
                    class => $parameterizable_type,
                    param => tokenize_type_str_impl( $class, $substr, $options ),
                    base  => tokenize_type_str_impl( $class, $word, $options ),
                } );

                $parameterizable_type = '';
            }

            $word = '';

        } elsif( $char eq '(' ) {

            if( $word eq '' ) {

                unless( exists $stack[ $#stack ] -> { 'class' } ) {

                    die( 'Invalid type description' );
                }

            } else {

                push( @stack, { type => $word } );
                $word = '';
            }

            my $cnt    = 1;
            my $substr = $char;

            while( defined( my $subchar = shift( @chars ) ) ) {

                ++$cnt if( $subchar eq '(' );
                --$cnt if( $subchar eq ')' );

                $substr .= $subchar;

                last if( $cnt == 0 );
            }

            die( 'Invalid signature' ) if( $substr eq '' );

            push( @stack, {
                signed => {
                    type => pop( @stack ),
                    signature => tokenize_signature_str_impl( $class, $substr, $options ),
                    source => $substr,
                }
            } );

        } elsif( $char eq '{' ) {

            if( $word ne '' ) {

                push( @stack, { type => $word } );
                $word = '';
            }

            my $substr = '';

            while( defined( my $subchar = shift( @chars ) ) ) {

                last if( $subchar eq '}' );

                $substr .= $subchar;
            }

            $substr =~ s/\s+//g;

            my ( $min, $max ) = ( undef, undef );

            if( $substr =~ m/^(0|[1-9][0-9]*),(0|[1-9][0-9]*)$/ ) {

                ( $min, $max ) = ( $1, $2 );

            } elsif( $substr =~ m/^(0|[1-9][0-9]*),$/ ) {

                $min = $1;

            } elsif( $substr =~ m/^(0|[1-9][0-9]*)$/ ) {

                ( $min, $max ) = ( $1 )x2;

            } else {

                die( 'Invalid length limits' );
            }

            push( @stack, {
                length => {
                    type => pop( @stack ),
                    min => $min,
                    max => $max,
                }
            } );

        } else {

            $word .= $char;
        }
    }

    push( @stack, { type => $word } ) if( $word ne '' );

    return { data => \@stack, opts => { strict => 0 } };
}

=head2 tokenize_signature_str_impl( Str str, Maybe[HashRef] options? )

Разбирает строку с подписью C<str> и возвращает ArrayRef[HashRef]
с найденными токенами.

Набор опций в C<options> и их значений эквивалентен оному для C<tokenize_type_str_impl>.

=cut

sub tokenize_signature_str_impl {

    my ( $class, $str, $options ) = @_;

    $options //= {};

    $str =~ s/\s+/ /gs;

    die( "Invalid signature: ${str}" ) if( $str !~ m/^\s*\(\s*(.+?)\s*\)\s*$/ );

    $str = $1;

    my @chars = split( //, $str );
    my @stack = ();
    my @seq   = ( 'type', 'name', 'delimiter' );
    my %word  = ();

    my %opened_parens = (
        '{' => 0,
        '(' => 0,
        '[' => 0,
    );

    my %closed_parens = (
        '}' => '{',
        ')' => '(',
        ']' => '[',
    );

    my $delimiter_re = qr/^[\s,]$/;
    my $strict_signature = 0;

    while( defined( my $item_type = shift( @seq ) ) ) {

        my $word = '';

        if( $item_type eq 'type' ) {

            while( defined( my $char = shift( @chars ) ) ) {

                ++$opened_parens{ $char } if( exists $opened_parens{ $char } );
                --$opened_parens{ $closed_parens{ $char } } if( exists $closed_parens{ $char } );

                if( $char =~ $delimiter_re ) {

                    my $word_end = true;

                    while( my ( $key, $value ) = each( %opened_parens ) ) {

                        $word_end = false if( $word_end && $value != 0 );
                    }

                    if( $word_end ) {

                        while( defined( my $subchar = shift( @chars ) ) ) {

                            if( $subchar !~ $delimiter_re ) {

                                unshift( @chars, $subchar );
                                last;
                            }
                        }

                        last;
                    }
                }

                if(
                    ( scalar( @stack ) == 0 ) && ( $word eq '' )
                    && ( $char eq '!' ) && ( $strict_signature == 0 )
                ) {

                    $strict_signature = 1;

                    while( defined( my $subchar = shift( @chars ) ) ) {

                        if( $subchar !~ $delimiter_re ) {

                            unshift( @chars, $subchar );
                            last;
                        }
                    }

                } else {

                    $word .= $char;
                }
            }

            die( 'Invalid type string' ) if( $word eq '' );

        } elsif( $item_type eq 'name' ) {

            while( defined( my $char = shift( @chars ) ) ) {

                if( $char =~ $delimiter_re ) {

                    while( defined( my $subchar = shift( @chars ) ) ) {

                        if( $subchar !~ $delimiter_re ) {

                            unshift( @chars, $subchar );
                            last;
                        }
                    }

                    last;
                }

                $word .= $char;
            }

            die( 'Invalid parameter name' ) if( $word eq '' );

        } elsif( $item_type eq 'delimiter' ) {

            my ( $type, $name ) = delete @word{ 'type', 'name' };

            die( 'Invalid signature' ) if( ( $type eq '' ) || ( $name eq '' ) );

            $type = tokenize_type_str_impl( $class, $type, $options );
            $name = tokenize_signature_parameter_str( $name );

            push( @stack, {
                type => $type,
                param => $name,
            } );

            push( @seq, $item_type );

            last if( scalar( @chars ) == 0 );
            next;
        }

        $word{ $item_type } = $word;

        push( @seq, $item_type );
    }

    return { data => \@stack, opts => { strict => $strict_signature } };
}

=head2 tokenize_signature_parameter_str( Str $str )

Разбирает строку с именем параметра C<$str> и возвращает HashRef, представляющий
токен.

=cut

sub tokenize_signature_parameter_str {

    my ( $str ) = @_;

    my %out = ();
    my $first_char = substr( $str, 0, 1 );

    if( $first_char eq ':' ) {

        $out{ 'named' } = true;
        $str = substr( $str, 1 );

    } else {

        $out{ 'positional' } = true;
    }

    my $last_char = substr( $str, -1, 1 );

    if( $last_char eq '!' ) {

        $out{ 'required' } = true;
        $str = substr( $str, 0, -1 );

    } elsif( $last_char eq '?' ) {

        $out{ 'optional' } = true;
        $str = substr( $str, 0, -1 );

    } elsif( $out{ 'positional' } ) {

        $out{ 'required' } = true;

    } elsif( $out{ 'named' } ) {

        $out{ 'optional' } = true;
    }

    $out{ 'name' } = $str;

    return \%out;
}

1;

__END__
