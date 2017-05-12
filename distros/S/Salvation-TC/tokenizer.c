#ifndef _TOKENIZER_C_
#define _TOKENIZER_C_

#include "tokenizer.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>

#define E_STR_INVALID_SIGNATURE "Invalid signature: "
#define E_STR_CANT_PARAMETERIZE_TYPE "Can't parameterize type "
#define E_STR_INVALID_TYPE_STRING_IN_SIGNATURE "Invalid type string in signature: "
#define E_STR_INVALID_PARAMETER_NAME_IN_SIGNATURE "Invalid parameter name in signature: "
#define E_STR_TYPE_OR_PARAMETER_NAME_MISSING_IN_SIGNATURE "Type or parameter name missing in signature: "
#define E_STR_UNEXPECTED_END_OF_INPUT_IN_SIGNATURE "Unexpected end of input in signature: "

static inline void push_stack( intptr_t ** stack, int length, intptr_t token ) {

    if( length > 0 ) *stack = realloc( *stack, ( length + 1 ) * sizeof( intptr_t ) );

    (*stack)[ length ] = token;
}

static inline void append( char ** s, char c ) {

    int len = strlen( *s );
    *s = realloc( *s, len + 2 );

    (*s)[ len ] = c;
    (*s)[ len + 1 ] = '\0';
}

static inline char * copy_str( char * s ) {

    int len = strlen( s );
    char buf[ len ];

    strcpy( buf, s );

    return strdup( buf );
}

static inline short is_space( char chr ) {

    return ( ( ( chr == ' ' ) || ( chr == '\n' ) || ( chr == '\r' ) || ( chr == '\t' ) ) ? 1 : 0 );
}

static inline short is_delim( char chr ) {

    return ( ( chr == ',' ) ? 1 : 0 );
}

static inline short is_digit( char chr ) {

    return ( (
        ( chr == '1' ) || ( chr == '2' ) || ( chr == '3' ) || ( chr == '4' )
        || ( chr == '5' ) || ( chr == '6' ) || ( chr == '7' ) || ( chr == '8' )
        || ( chr == '9' ) || ( chr == '0' )
    ) ? 1 : 0 );
}

static my_stack_t * tokenize_signature_str( char * class, const char * s, tokenizer_options_t * options );

static inline char * zero_str() {

    char * word = malloc( 1 );

    word[ 0 ] = '\0';

    return word;
}

static my_stack_t * tokenize_type_str( char * class, const char * s, tokenizer_options_t * options ) {

    intptr_t * stack = malloc( sizeof( *stack ) );
    char * word = zero_str();
    char * parameterizable_type = zero_str();
    int stack_size = 0;
    int pos = 0;
    int length = strlen( s );

    while( pos < length ) {

        char chr = s[ pos ++ ];

        if( is_space( chr ) ) continue;

        if( ( chr == '[' ) && ( strcmp( word, "Maybe\0" ) != 0 ) ) {

            free( parameterizable_type );

            if( options -> loose != 0 ) {

                parameterizable_type = copy_str( word );

            } else {

                parameterizable_type = call_load_parameterizable_type_class( class, word );

                if( strlen( parameterizable_type ) == 0 ) {

                    free_stack_arr( stack, stack_size );
                    char * _s = malloc( strlen( E_STR_CANT_PARAMETERIZE_TYPE ) + strlen( word ) + 1 );
                    sprintf( _s, "%s%s", E_STR_CANT_PARAMETERIZE_TYPE, word );
                    p_die( _s );
                }
            }
        }

        if( chr == '|' ) {

            if( strlen( word ) == 0 ) {

                if( stack_size == 0 ) {

                    free_stack_arr( stack, stack_size );
                    p_die( "Invalid type string: | can't be a first character of type name\n" );

                } else {

                    abstract_type_t * token = (abstract_type_t*)(stack[ stack_size - 1 ]);
                    short token_type = token -> token_type;

                    if( !(
                        ( token_type == TOKEN_TYPE_MAYBE )
                        || ( token_type == TOKEN_TYPE_PARAMETRIZABLE )
                        || ( token_type == TOKEN_TYPE_SIGNED )
                        || ( token_type == TOKEN_TYPE_LENGTH )
                    ) ) {

                        free_stack_arr( stack, stack_size );
                        p_die( "Invalid type string: | should follow a type name\n" );
                    }
                }

            } else {

                basic_type_t * token = malloc( sizeof( *token ) );

                token -> base.token_type = TOKEN_TYPE_BASIC;
                token -> type = word;

                push_stack( &stack, stack_size, (intptr_t)token );
                ++stack_size;

                word = zero_str();
            }

        } else if( chr == '[' ) {

            int cnt = 1;
            char * substr = zero_str();

            while( pos < length ) {

                char subchr = s[ pos ++ ];

                if( subchr == '[' ) ++cnt;
                if( subchr == ']' ) --cnt;

                if( cnt == 0 ) break;

                append( &substr, subchr );
            }

            if( ( strlen( substr ) == 0 ) || ( strlen( word ) == 0 ) ) {

                free_stack_arr( stack, stack_size );
                p_die( "Invalid type parameterization: no type name or no parameter name\n" );
            }

            if( strlen( parameterizable_type ) == 0 ) {

                maybe_type_t * token = malloc( sizeof( *token ) );

                token -> base.token_type = TOKEN_TYPE_MAYBE;

                my_stack_t * _stack = tokenize_type_str( class, substr, options );
                if( _stack == 0 ) return 0;
                token -> stack = _stack;

                push_stack( &stack, stack_size, (intptr_t)token );
                ++stack_size;

            } else {

                parameterizable_type_t * token = malloc( sizeof( *token ) );

                token -> base.token_type = TOKEN_TYPE_PARAMETRIZABLE;
                token -> class = parameterizable_type;

                my_stack_t * _param = tokenize_type_str( class, substr, options );;
                if( _param == 0 ) return 0;
                token -> param = _param;

                my_stack_t * _stack = tokenize_type_str( class, word, options );
                if( _stack == 0 ) return 0;
                token -> stack = _stack;

                push_stack( &stack, stack_size, (intptr_t)token );
                ++stack_size;

                parameterizable_type = zero_str();
            }

            free( word );
            word = zero_str();
            free( substr );

        } else if( chr == '(' ) {

            if( strlen( word ) == 0 ) {

                if( stack_size == 0 ) {

                    free_stack_arr( stack, stack_size );
                    p_die( "Invalid type description: ( can't be a first character of type name\n" );

                } else {

                    abstract_type_t * token = (abstract_type_t*)(stack[ stack_size - 1 ]);
                    short token_type = token -> token_type;

                    if( !(
                        ( token_type == TOKEN_TYPE_PARAMETRIZABLE )
                    ) ) {

                        free_stack_arr( stack, stack_size );
                        p_die( "Invalid type description: ( should follow a type name\n" );
                    }
                }

            } else {

                basic_type_t * token = malloc( sizeof( *token ) );

                token -> base.token_type = TOKEN_TYPE_BASIC;
                token -> type = word;

                push_stack( &stack, stack_size, (intptr_t)token );
                ++stack_size;

                word = zero_str();
            }

            int cnt = 1;
            char * substr = zero_str();

            append( &substr, chr );

            while( pos < length ) {

                char subchr = s[ pos ++ ];

                if( subchr == '(' ) ++cnt;
                if( subchr == ')' ) --cnt;

                append( &substr, subchr );

                if( cnt == 0 ) break;
            }

            signed_type_t * token = malloc( sizeof( *token ) );

            token -> base.token_type = TOKEN_TYPE_SIGNED;

            my_stack_t * signature = tokenize_signature_str( class, substr, options );
            if( signature == 0 ) return 0;
            token -> signature = signature;

            token -> type = stack[ stack_size - 1 ];
            token -> source = substr;

            stack[ stack_size - 1 ] = (intptr_t)token;

        } else if( chr == '{' ) {

            if( strlen( word ) != 0 ) {

                basic_type_t * token = malloc( sizeof( *token ) );

                token -> base.token_type = TOKEN_TYPE_BASIC;
                token -> type = word;

                push_stack( &stack, stack_size, (intptr_t)token );
                ++stack_size;

                word = zero_str();
            }

            short has_min = 0;
            short has_max = 0;
            short got_delim = 0;

            char * min = zero_str();
            char * max = zero_str();

            while( pos < length ) {

                char subchr = s[ pos ++ ];

                if( subchr == '}' ) break;
                if( is_space( subchr ) ) continue;

                if( is_delim( subchr ) ) {

                    if( got_delim == 1 ) {

                        free_stack_arr( stack, stack_size );
                        p_die( "Invalid length limits: only one delimiter allowed\n" );
                    }

                    got_delim = 1;
                    continue;
                }

                if( is_digit( subchr ) ) {

                    if( got_delim == 0 ) {

                        append( &min, subchr );
                        has_min = 1;

                    } else {

                        append( &max, subchr );
                        has_max = 1;
                    }

                } else {

                    free_stack_arr( stack, stack_size );
                    p_die( "Invalid length limits: only digits allowed\n" );
                }
            }

            if( has_min == 0 ) {

                free_stack_arr( stack, stack_size );
                p_die( "Invalid length limits: lower limit is required\n" );
            }

            if( ( has_max == 0 ) && ( got_delim == 0 ) ) {

                free( max );
                max = copy_str( min );
                has_max = 1;
            }

            length_type_t * token = malloc( sizeof( *token ) );

            token -> base.token_type = TOKEN_TYPE_LENGTH;
            token -> has_min = has_min;
            token -> has_max = has_max;
            if( has_min == 1 ) token -> min = min; else free( min );
            if( has_max == 1 ) token -> max = max; else free( max );
            token -> type = stack[ stack_size - 1 ];

            stack[ stack_size - 1 ] = (intptr_t)token;

        } else {

            append( &word, chr );
        }
    }

    if( strlen( word ) != 0 ) {

        basic_type_t * token = malloc( sizeof( *token ) );

        token -> base.token_type = TOKEN_TYPE_BASIC;
        token -> type = word;

        push_stack( &stack, stack_size, (intptr_t)token );
        ++stack_size;

    } else {

        free( word );
    }

    free( parameterizable_type );

    my_stack_t * out = new_my_stack();

    out -> size = stack_size;
    out -> data = stack;

    return out;
}

typedef struct {

    int circle;
    int inner_curly;
    int inner_circle;
    int inner_square;

} brackets_state_t;

static inline void update_brackets_state( brackets_state_t * bs, char chr ) {

    if( chr == '(' ) if( ++(bs -> circle) > 1 ) ++(bs -> inner_circle);
    if( chr == '[' ) ++(bs -> inner_square);
    if( chr == '{' ) ++(bs -> inner_curly);

    if( chr == ')' ) if( --(bs -> circle) > 0 ) --(bs -> inner_circle);
    if( chr == ']' ) --(bs -> inner_square);
    if( chr == '}' ) --(bs -> inner_curly);
}

static inline short has_open_inner_brackets( brackets_state_t * bs ) {

    return ( (
        ( bs -> inner_curly == 0 )
        && ( bs -> inner_circle == 0 )
        && ( bs -> inner_square == 0 )
    ) ? 0 : 1 );
}

static inline signature_param_t * tokenize_signature_parameter_str( const char * s, tokenizer_options_t * options );

static my_stack_t * tokenize_signature_str( char * class, const char * s, tokenizer_options_t * options ) {

    intptr_t * stack = malloc( sizeof( *stack ) );
    int stack_size = 0;
    int pos = 0;
    int length = strlen( s );

    char * type = zero_str();
    char * name = zero_str();

    brackets_state_t brackets_state = {
        .circle = 0,
        .inner_curly = 0,
        .inner_circle = 0,
        .inner_square = 0
    };

    short seq = SIG_SEQ_MIN;
    short done = 0;
    short strict_signature = 0;

    while( pos <= length ) {

        if( seq == SIG_SEQ_ITEM_TYPE ) {

            while( pos < length ) {

                char chr = s[ pos ++ ];

                if( brackets_state.circle == 0 ) {

                    if( is_space( chr ) ) continue;
                }

                update_brackets_state( &brackets_state, chr );

                if( brackets_state.circle == 0 ) {

                    if( stack_size > 0 ) {

                        done = 1;
                        break;

                    } else {

                        free_stack_arr( stack, stack_size );
                        char * _s = malloc( strlen( E_STR_INVALID_SIGNATURE ) + strlen( s ) + 1 );
                        sprintf( _s, "%s%s", E_STR_INVALID_SIGNATURE, s );
                        p_die( _s );
                    }
                }

                if(
                    ( chr == '(' )
                    && ( brackets_state.inner_circle == 0 )
                    && ( brackets_state.circle == 1 )
                ) {
                    while( pos < length ) {

                        char subchr = s[ pos ++ ];

                        if( !is_space( subchr ) && !is_delim( subchr ) ) {

                            --pos;
                            break;
                        }
                    }

                    continue;
                }

                if(
                    ( is_space( chr ) || is_delim( chr ) )
                    && ! has_open_inner_brackets( &brackets_state )
                ) {
                    while( pos < length ) {

                        char subchr = s[ pos ++ ];

                        if( !is_space( subchr ) && !is_delim( subchr ) ) {

                            --pos;
                            break;
                        }
                    }

                    break;
                }

                if(
                    ( stack_size == 0 ) && ( strlen( type ) == 0 )
                    && ( chr == '!' ) && ( strict_signature == 0 )
                ) {

                    strict_signature = 1;

                    while( pos < length ) {

                        char subchr = s[ pos ++ ];

                        if( !is_space( subchr ) && !is_delim( subchr ) ) {

                            --pos;
                            break;
                        }
                    }

                } else {

                    append( &type, chr );
                }
            }

            if( done == 1 ) break;

            if( strlen( type ) == 0 ) {

                free_stack_arr( stack, stack_size );
                char * _s = malloc( strlen( E_STR_INVALID_TYPE_STRING_IN_SIGNATURE ) + strlen( s ) + 1 );
                sprintf( _s, "%s%s", E_STR_INVALID_TYPE_STRING_IN_SIGNATURE, s );
                p_die( _s );
            }

        } else if( seq == SIG_SEQ_ITEM_NAME ) {

            while( pos < length ) {

                char chr = s[ pos ++ ];

                update_brackets_state( &brackets_state, chr );

                if( is_space( chr ) || is_delim( chr ) || ( chr == ')' ) ) {

                    while( pos < length ) {

                        char subchr = s[ pos ++ ];

                        if( !is_space( subchr ) && !is_delim( subchr ) && ( chr != ')' ) ) {

                            --pos;
                            break;
                        }
                    }

                    break;
                }

                append( &name, chr );
            }

            if( strlen( name ) == 0 ) {

                free_stack_arr( stack, stack_size );
                char * _s = malloc( strlen( E_STR_INVALID_PARAMETER_NAME_IN_SIGNATURE ) + strlen( s ) + 1 );
                sprintf( _s, "%s%s", E_STR_INVALID_PARAMETER_NAME_IN_SIGNATURE, s );
                p_die( _s );
            }

        } else if( seq == SIG_SEQ_ITEM_DELIM ) {

            if( ( strlen( type ) == 0 ) || ( strlen( name ) == 0 ) ) {

                free_stack_arr( stack, stack_size );
                char * _s = malloc( strlen( E_STR_TYPE_OR_PARAMETER_NAME_MISSING_IN_SIGNATURE ) + strlen( s ) + 1 );
                sprintf( _s, "%s%s", E_STR_TYPE_OR_PARAMETER_NAME_MISSING_IN_SIGNATURE, s );
                p_die( _s );
            }

            signature_item_t * token = malloc( sizeof( *token ) );

            token -> base.token_type = TOKEN_TYPE_SIGNATURE_ITEM;

            my_stack_t * _type = tokenize_type_str( class, type, options );
            if( _type == 0 ) return 0;
            token -> type = _type;

            free( type );
            type = zero_str();

            signature_param_t * _param = tokenize_signature_parameter_str( name, options );
            if( _param == 0 ) return 0;
            token -> param = _param;

            free( name );
            name = zero_str();

            push_stack( &stack, stack_size, (intptr_t)token );
            ++stack_size;

            if( pos >= length ) break;
        }

        if( ++seq > SIG_SEQ_MAX ) seq = SIG_SEQ_MIN;
    }

    if( ( brackets_state.circle != 0 ) || has_open_inner_brackets( &brackets_state ) ) {

        free_stack_arr( stack, stack_size );
        char * _s = malloc( strlen( E_STR_UNEXPECTED_END_OF_INPUT_IN_SIGNATURE ) + strlen( s ) + 1 );
        sprintf( _s, "%s%s", E_STR_UNEXPECTED_END_OF_INPUT_IN_SIGNATURE, s );
        p_die( _s );
    }

    free( type );
    free( name );

    my_stack_t * out = new_my_stack();

    out -> size = stack_size;
    out -> data = stack;
    out -> opts -> strict_signature = strict_signature;

    return out;
}

static inline signature_param_t * tokenize_signature_parameter_str( const char * _s, tokenizer_options_t * options ) {

    char * s = copy_str( (char*)_s );
    signature_param_t * token = malloc( sizeof( *token ) );

    char first_char = s[ 0 ];
    int len = strlen( s );

    if( first_char == ':' ) {

        token -> named = 1;
        token -> positional = 0;

        --len;

        for( int i = 0; i < len; ++i ) s[ i ] = s[ i + 1 ];

        s[ len ] = '\0';
        s = realloc( s, len + 1 );

    } else {

        token -> named = 0;
        token -> positional = 1;
    }

    char last_char = s[ len - 1 ];

    if( last_char == '!' ) {

        token -> required = 1;
        token -> optional = 0;

        s[ len - 1 ] = '\0';
        s = realloc( s, len );

    } else if( last_char == '?' ) {

        token -> required = 0;
        token -> optional = 1;

        s[ len - 1 ] = '\0';
        s = realloc( s, len );

    } else if( token -> positional == 1 ) {

        token -> required = 1;
        token -> optional = 0;

    } else if( token -> named == 1 ) {

        token -> required = 0;
        token -> optional = 1;
    }

    token -> name = s;

    return token;
}

HV * perl_tokenize_type_str( char * class, const char * s, HV * options ) {

    my_stack_t * stack = tokenize_type_str( class, s, perl_to_options( options ) );

    HV * out = mortalize_hv( tokens_to_perl( stack ) );

    if( stack != 0 ) free_my_stack( stack );

    return out;
}

HV * perl_tokenize_signature_str( char * class, const char * s, HV * options ) {

    my_stack_t * stack = tokenize_signature_str( class, s, perl_to_options( options ) );

    HV * out = mortalize_hv( tokens_to_perl( stack ) );

    if( stack != 0 ) free_my_stack( stack );

    return out;
}

#endif /* end of include guard: _TOKENIZER_C_ */
