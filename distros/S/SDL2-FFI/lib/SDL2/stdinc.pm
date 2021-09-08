package SDL2::stdinc 0.01 {
    use strictures 2;
    use experimental 'signatures';
    use SDL2::Utils;
    #
    use SDL2::iconv_t;
    #
    enum SDL_bool => [ [ SDL_FALSE => !1 ], [ SDL_TRUE => 1 ] ];
    use FFI::Platypus::Buffer qw[grow scalar_to_pointer];

    # Tricky memory stuff
    ffi->type( '(size_t)->opaque'        => 'SDL_malloc_func' );
    ffi->type( '(size_t,size_t)->opaque' => 'SDL_calloc_func' );
    ffi->type( '(opaque,size_t)->opaque' => 'SDL_realloc_func' );
    ffi->type( '(opaque)->void'          => 'SDL_free_func' );
    ffi->load_custom_type( '::WideString' => 'wstring', );
    ffi->load_custom_type( '::WideString' => 'wstring_w', access => 'write' );
    ffi->type( 'string' => 'wide_string' );
    ffi->load_custom_type( '::StringArray' => 'string_array' );
    #
    attach stdinc => {
        SDL_malloc  => [ ['size_t'], 'opaque' ],
        SDL_calloc  => [ [ 'size_t', 'size_t' ], 'opaque' ],
        SDL_realloc => [ [ 'opaque', 'size_t' ], 'opaque' ],
        SDL_free    => [ ['opaque'] ],
        #
        SDL_GetMemoryFunctions => [
            [ 'opaque*', 'opaque*', 'opaque*', 'opaque*' ] =>
                sub ( $inner, $malloc_func, $calloc_func, $realloc_func, $free_func ) {
                $inner->( $malloc_func, $calloc_func, $realloc_func, $free_func );
                $$malloc_func  = ffi->function( $$malloc_func,  ['size_t'], 'opaque' );
                $$calloc_func  = ffi->function( $$calloc_func,  [ 'size_t', 'size_t' ], 'opaque' );
                $$realloc_func = ffi->function( $$realloc_func, [ 'opaque', 'size_t' ], 'opaque' );
                $$free_func    = ffi->function( $$free_func, ['opaque'], );
            }
        ],
        SDL_SetMemoryFunctions => [
            [ 'SDL_malloc_func', 'SDL_calloc_func', 'SDL_realloc_func', 'SDL_free_func' ] =>
                sub ( $inner, $malloc_func, $calloc_func, $realloc_func, $free_func ) {
                if ( ref $malloc_func eq 'CODE' ) {
                    $malloc_func = ffi->closure($malloc_func);
                    $malloc_func->sticky;
                }
                if ( ref $calloc_func eq 'CODE' ) {
                    $calloc_func = ffi->closure($calloc_func);
                    $calloc_func->sticky;
                }
                if ( ref $realloc_func eq 'CODE' ) {
                    $realloc_func = ffi->closure($realloc_func);
                    $realloc_func->sticky;
                }
                if ( ref $free_func eq 'CODE' ) {
                    $free_func = ffi->closure($free_func);
                    $free_func->sticky;
                }
                $inner->( $malloc_func, $calloc_func, $realloc_func, $free_func );
            }
        ],
        SDL_GetNumAllocations => [ [], 'int' ],
        #
        SDL_getenv => [ ['string'],                    'string' ],
        SDL_setenv => [ [ 'string', 'string', 'int' ], 'int' ],
        #
        SDL_qsort => [
            [ 'opaque', 'size_t', 'size_t', '(opaque,opaque)->int' ] =>
                sub ( $inner, $ptr, $count, $size, $comp ) {
                my $wrapped = 0;
                if ( ref $comp eq 'CODE' ) {
                    $wrapped = 1;
                    $comp    = ffi->closure($comp);
                    $comp->sticky;
                }
                $inner->( $ptr, $count, $size, $comp );
                $comp->unstick if $wrapped;
            }
        ],
        #
        SDL_abs => [ ['int'], 'int' ],
        #
        SDL_isalpha  => [ ['int'], 'int' => sub ( $inner, $char ) { $inner->( ord $char ) } ],
        SDL_isalnum  => [ ['int'], 'int' => sub ( $inner, $char ) { $inner->( ord $char ) } ],
        SDL_isblank  => [ ['int'], 'int' => sub ( $inner, $char ) { $inner->( ord $char ) } ],
        SDL_iscntrl  => [ ['int'], 'int' => sub ( $inner, $char ) { $inner->( ord $char ) } ],
        SDL_isdigit  => [ ['int'], 'int' => sub ( $inner, $char ) { $inner->( ord $char ) } ],
        SDL_isxdigit => [ ['int'], 'int' => sub ( $inner, $char ) { $inner->( ord $char ) } ],
        SDL_ispunct  => [ ['int'], 'int' => sub ( $inner, $char ) { $inner->( ord $char ) } ],
        SDL_isspace  => [ ['int'], 'int' => sub ( $inner, $char ) { $inner->( ord $char ) } ],
        SDL_isupper  => [ ['int'], 'int' => sub ( $inner, $char ) { $inner->( ord $char ) } ],
        SDL_islower  => [ ['int'], 'int' => sub ( $inner, $char ) { $inner->( ord $char ) } ],
        SDL_isprint  => [ ['int'], 'int' => sub ( $inner, $char ) { $inner->( ord $char ) } ],
        SDL_isgraph  => [ ['int'], 'int' => sub ( $inner, $char ) { $inner->( ord $char ) } ],
        #
        SDL_toupper => [ ['int'], 'int' => sub ( $inner, $char ) { chr $inner->( ord $char ) } ],
        SDL_tolower => [ ['int'], 'int' => sub ( $inner, $char ) { chr $inner->( ord $char ) } ],
        #
        SDL_crc32 => [
            [ 'uint32', 'opaque', 'size_t' ],
            'uint32' => sub ( $inner, $crc, $str, $len = length( ref $str ? $$str : $str ) ) {
                $inner->( $crc, ref $str ? scalar_to_pointer($$str) : $str, $len );
            }
        ],
        #
        SDL_memset => [
            [ 'opaque', 'int', 'size_t' ],
            'opaque' => sub ( $inner, $dst, $c, $len ) {
                $inner->( ref $dst ? scalar_to_pointer($$dst) : $dst, ord($c), $len );
            }
        ],
        SDL_memcpy => [
            [ 'opaque', 'opaque', 'size_t' ],
            'opaque' => sub ( $inner, $dst, $src, $len ) {
                $inner->(
                    ref $dst ? scalar_to_pointer($$dst) : $dst,
                    ref $src ? scalar_to_pointer($$src) : $src, $len
                );
            }
        ],
        SDL_memmove => [
            [ 'opaque', 'opaque', 'size_t' ],
            'opaque' => sub ( $inner, $dst, $src, $count ) {
                $inner->(
                    ref $dst ? scalar_to_pointer($$dst) : $dst,
                    ref $src ? scalar_to_pointer($$src) : $src, $count
                );
            }
        ],
        SDL_memcmp => [
            [ 'opaque', 'opaque', 'size_t' ],
            'int' => sub ( $inner, $lhs, $rhs, $count ) {
                $inner->(
                    ref $lhs ? scalar_to_pointer($$lhs) : $lhs,
                    ref $rhs ? scalar_to_pointer($$rhs) : $rhs, $count
                );
            }
        ],
        SDL_wcslen      => [ ['wstring'],                        'size_t' ],
        SDL_wcslcpy     => [ [ 'wstring', 'wstring', 'size_t' ], 'size_t' ],
        SDL_wcslcat     => [ [ 'wstring', 'wstring', 'size_t' ], 'size_t' ],    # FIX
        SDL_wcsdup      => [ ['wstring'],                        'wstring' ],
        SDL_wcsstr      => [ [ 'wstring', 'wstring' ],           'wstring' ],
        SDL_wcscmp      => [ [ 'wstring', 'wstring' ],           'int' ],
        SDL_wcsncmp     => [ [ 'wstring', 'wstring', 'size_t' ], 'int' ],
        SDL_wcscasecmp  => [ [ 'wstring', 'wstring' ],           'int' ],
        SDL_wcsncasecmp => [ [ 'wstring', 'wstring', 'size_t' ], 'int' ],
        #
        SDL_strlen      => [ ['string'], 'size_t' ],
        SDL_strlcpy     => [ [ 'string', 'string', 'size_t' ], 'size_t' ],
        SDL_utf8strlcpy => [ [ 'string', 'string', 'size_t' ], 'size_t' ],
        SDL_strlcat     => [ [ 'string', 'string', 'size_t' ], 'size_t' ],
        #
        SDL_strdup => [ ['string'], 'string' ],
        SDL_strrev => [ ['string'], 'string' ],
        SDL_strupr => [ ['string'], 'string' ],
        SDL_strlwr => [ ['string'], 'string' ],
        SDL_strchr => [
            [ 'string', 'int' ],
            'string' => sub ( $inner, $str, $chr ) {
                $inner->( $str, ord $chr );
            }
        ],
        SDL_strrchr => [
            [ 'string', 'int' ],
            'string' => sub ( $inner, $str, $chr ) {
                $inner->( $str, ord $chr );
            }
        ],
        SDL_strstr      => [ [ 'string', 'string' ],           'string' ],
        SDL_strtokr     => [ [ 'string', 'string', 'string' ], 'string' ],    # FIX
        SDL_utf8strlen  => [ ['string'],                       'size_t' ],
        SDL_itoa        => [ [ 'int', 'string', 'int' ],       'string' ],
        SDL_uitoa       => [ [ 'uint', 'string', 'int' ],      'string' ],
        SDL_ltoa        => [ [ 'long', 'string', 'int' ],      'string' ],
        SDL_ultoa       => [ [ 'ulong', 'string', 'int' ],     'string' ],
        SDL_lltoa       => [ [ 'sint64', 'string', 'int' ],    'string' ],
        SDL_ulltoa      => [ [ 'uint64', 'string', 'int' ],    'string' ],
        SDL_atoi        => [ ['string'],                       'int' ],
        SDL_atof        => [ ['string'],                       'double' ],
        SDL_strtol      => [ [ 'string', 'string*', 'int' ],   'long' ],
        SDL_strtoul     => [ [ 'string', 'string*', 'int' ],   'long' ],
        SDL_strtoll     => [ [ 'string', 'string*', 'int' ],   'sint64' ],
        SDL_strtoull    => [ [ 'string', 'string*', 'int' ],   'uint64' ],
        SDL_strtod      => [ [ 'string', 'string*' ],          'double' ],
        SDL_strcmp      => [ [ 'string', 'string' ],           'int' ],
        SDL_strncmp     => [ [ 'string', 'string', 'size_t' ], 'int' ],
        SDL_strcasecmp  => [ [ 'string', 'string' ],           'int' ],
        SDL_strncasecmp => [ [ 'string', 'string', 'size_t' ], 'int' ],
        #
        SDL_acos      => [ ['double'],             'double' ],
        SDL_acosf     => [ ['float'],              'float' ],
        SDL_asin      => [ ['double'],             'double' ],
        SDL_asinf     => [ ['float'],              'float' ],
        SDL_atan      => [ ['double'],             'double' ],
        SDL_atan2     => [ [ 'double', 'double' ], 'double' ],
        SDL_atan2f    => [ [ 'float', 'float' ],   'float' ],
        SDL_atanf     => [ ['float'],              'float' ],
        SDL_ceil      => [ ['double'],             'double' ],
        SDL_ceilf     => [ ['float'],              'float' ],
        SDL_copysign  => [ [ 'double', 'double' ], 'double' ],
        SDL_copysignf => [ [ 'float', 'float' ],   'float' ],
        SDL_cos       => [ ['double'],             'double' ],
        SDL_cosf      => [ ['float'],              'float' ],
        SDL_exp       => [ ['double'],             'double' ],
        SDL_expf      => [ ['float'],              'float' ],
        SDL_fabs      => [ ['double'],             'double' ],
        SDL_fabsf     => [ ['float'],              'float' ],
        SDL_floor     => [ ['double'],             'double' ],
        SDL_floorf    => [ ['float'],              'float' ],
        SDL_trunc     => [ ['double'],             'double' ],
        SDL_truncf    => [ ['float'],              'float' ],
        SDL_fmod      => [ [ 'double', 'double' ], 'double' ],
        SDL_fmodf     => [ [ 'float', 'float' ],   'float' ],
        SDL_log       => [ ['double'],             'double' ],
        SDL_logf      => [ ['float'],              'float' ],
        SDL_log10     => [ ['double'],             'double' ],
        SDL_log10f    => [ ['float'],              'float' ],
        SDL_pow       => [ [ 'double', 'double' ], 'double' ],
        SDL_powf      => [ [ 'float', 'float' ],   'float' ],
        SDL_round     => [ ['double'],             'double' ],
        SDL_roundf    => [ ['float'],              'float' ],
        SDL_lround    => [ ['double'],             'long' ],
        SDL_lroundf   => [ ['float'],              'long' ],
        SDL_scalbn    => [ [ 'double', 'int' ],    'double' ],
        SDL_scalbnf   => [ [ 'float', 'int' ],     'float' ],
        SDL_sin       => [ ['double'],             'double' ],
        SDL_sinf      => [ ['float'],              'float' ],
        SDL_sqrt      => [ ['double'],             'double' ],
        SDL_sqrtf     => [ ['float'],              'float' ],
        SDL_tan       => [ ['double'],             'double' ],
        SDL_tanf      => [ ['float'],              'float' ],
        #
        SDL_iconv_open  => [ [ 'string', 'string' ], 'SDL_iconv_t' ],
        SDL_iconv_close => [ ['SDL_iconv_t'],        'int' ],
        SDL_iconv => [ [ 'SDL_iconv_t', 'string*', 'size_t*', 'string*', 'size_t*' ], 'size_t' ],
        SDL_iconv_string => [ [ 'string', 'string', 'string', 'size_t' ], 'string' ]
    };
    define stdinc => [
        [ SDL_zero => sub ($ptr) { SDL2::FFI::SDL_memset( $ptr, 0, length($ptr) ) } ],
        [   SDL_sscanf => sub ( $buffer, $format, @args ) {    # FIX: Breaks on string captures
                my @types = SDL2::Utils::_tokenize_in($format);
                my $retval
                    = ffi->function( SDL_sscanf => [ 'string', 'string' ] => [@types] => 'int' )
                    ->call( $buffer, $format, @args );
                for my $i ( 0 .. $#args ) {                    # clean up c->perl
                    $_[ $i + 2 ] = pack 'W*', unpack 'L*', $args[$i] if $types[$i] eq 'wide_string';
                    $_[ $i + 2 ] = unpack 'Z*', $args[$i] if $types[$i] eq 'string';
                }
                $retval;
            }
        ],
        [ SDL_vsscanf => sub ( $buffer, $format, @args ) { SDL2::FFI::SDL_sscanf(@_) } ],
        [   SDL_snprintf => sub ( $buffer, $maxlen, $format, @args ) {
                $buffer = "\0" x $maxlen;    # Just to be safe since we know $maxlen
                my @types = SDL2::Utils::_tokenize_out( $format, 0 );

                #use Data::Dump;ddx \@types;
                my $retval
                    = ffi->function(
                    SDL_snprintf => [ 'string', 'size_t', 'string' ] => [@types] => 'int' )
                    ->call( $buffer, $maxlen, $format, @args );
                $_[0] = unpack 'Z*', $buffer;
                $retval;
            }
        ],
        [   SDL_vsnprintf =>
                sub ( $buffer, $maxlen, $format, @args ) { SDL2::FFI::SDL_snprintf(@_) }
        ],

        # math for morons
        [ M_PI => '3.14159265358979323846264338327950288' ],

        # iconv
        [ SDL_ICONV_ERROR  => -1 ],
        [ SDL_ICONV_E2BIG  => -2 ],
        [ SDL_ICONV_EILSEQ => -3 ],
        [ SDL_ICONV_EINVAL => -4 ],
        #
        [   SDL_iconv_utf8_locale => sub ($s) {
                SDL2::FFI::SDL_iconv_string( "", "UTF-8", $s, SDL2::FFI::SDL_strlen($s) + 1 );
            }
        ],

#[SDL_iconv_utf8_ucs2   => sub ($s) { SDL2::FFI::SDL_iconv_string("UCS-2-INTERNAL", "UTF-8", $s, SDL2::FFI::SDL_strlen($s)+1 )}],
#[SDL_iconv_utf8_ucs4   => sub ($s) { SDL2::FFI::SDL_iconv_string("UCS-4-INTERNAL", "UTF-8", $s, SDL2::FFI::SDL_strlen($s)+1 )}]
    ];

=encoding utf-8

=head1 NAME

SDL2::stdinc - General C Language Support Functions

=head1 SYNOPSIS

    use SDL2 qw[:stdinc];

=head1 DESCRIPTION

This is a general package that includes C language support where platform
differences are abstracted away.

=head1 Functions

These functions likely will not be used in end-user code but may be imported
with the C<:stdinc> tag.

=head2 C<SDL_malloc( ... )>

Wraps the standard memory allocation functions for the specific platform.

Expected parameters include:

=over

=item C<size> - size of the allocated memory

=back

Returns a pointer to the memory.

=head2 C<SDL_calloc( ... )>

Allocates memory for an array of num objects of size and initializes all bytes
in the allocated storage to zero.

Expected parameters include:

=over

=item C<num> - number of objects

=item C<size> - size of each object

=back

Returns a pointer to the memory.

=head2 C<SDL_realloc( ... )>

Reallocates the given area of memory.

Expected parameters include:

=over

=item C<ptr> - pointer to the memory area to be reallocated

=item C<new_size> - new size of the array in bytes

=back

=head2 C<SDL_free( ... )>

Frees allocated memory.


Expected parameters include:

=over

=item C<ptr> - pointer to the memory area to be freed

=back

=head2 C<SDL_GetMemoryFunctions( ... )>

Get the current set of SDL memory functions.

	SDL_GetMemoryFunctions( \my $malloc, \my $calloc, \my $realloc, \my $free );
	my $mem = $malloc->(100);
	# Do odd, low level things with your memory
	$free->($mem);

Expected parameters include:

=over

=item C<malloc_func> - pointer which will be filled with a C<SDL_malloc_func>

=item C<calloc_func> - pointer which will be filled with a C<SDL_calloc_func>

=item C<realloc_func> - pointer which will be filled with a C<SDL_realloc_func>

=item C<free_func> - pointer which will be filled with a C<SDL_free_func>

=back

=head2 C<SDL_SetMemoryFunctions( ... )>

Replace SDL's memory allocation functions with a custom set.

	use Data::Dump;
	SDL_SetMemoryFunctions(   # poor example but I have no idea
		sub { ddx \@_; ... }, # why you're doing this anyway
		sub { ddx \@_; ... },
		sub { ddx \@_; ... },
		sub { ddx \@_; ... },
	);

Note: If you are replacing SDL's memory functions, you should call L<<
C<SDL_GetNumAllocations( )>|/C<SDL_GetNumAllocations( )> >> and be very careful
if it returns non-zero. That means that your free function will be called with
memory allocated by the previous memory allocation functions.

Expected parameters include:

=over

=item C<malloc_func> - a C<SDL_malloc_func> closure

=item C<calloc_func> - a C<SDL_calloc_func> closure

=item C<realloc_func> - a C<SDL_realloc_func> closure

=item C<free_func> - a C<SDL_free_func> closure

=back

If you pass a simple code reference to any of the parameters, they'll be
wrapped in a closure and made sticky

=head2 C<SDL_GetNumAllocations( )>

Get the number of outstanding (unfreed) allocations.

	my $leaks = SDL_GetNumAllocations( );

Returns an integer.

=head2 C<SDL_getenv( ... )>

Get environment variable's value.

	my $path = SDL_getenv( 'PATH' );

Expected parameters include:

=over

=item C<name> - the name of the environment variable to query

=back

Returns the value if defined.

=head2 C<SDL_setenv( ... )>

Set environment variable's value.

	SDL_setenv( 'Perl_SDL_pocket', 'store something here', 1 );

Expected parameters include:

=over

=item C<name> - the name of the environment variable to set

=item C<value> - the new value to set the given environment variable to

=item C<overwrite> - a boolean value; if true, the value is updated if already defined

=back

Returns C<1> if the environment variable has been changed; otherwise C<0>.

=head2 C<SDL_qsort( ... )>

A polymorphic sorting algorithm for arrays of arbitrary objects according to a
user-provided comparison function.

Expected parameters include:

=over

=item C<base> - pointer to the array to sort

=item C<count> - number of elements in the array

=item C<size> - size of each element in the array in bytes

=item C<comp> - comparison function which returns ​a negative integer value if the first argument is less than the second, a positive integer value if the first argument is greater than the second and zero if the arguments are equivalent.

The signature of the comparison function should be equivalent to the following:

	int cmp(const void *a, const void *b);
	# for FFI::Platypus->type: '(opaque,opaque)->int'

If the function is a code reference and not a closure, it will be wrapped
automatically and temporarily made sticky.

The function must not modify the objects passed to it and must return
consistent results when called for the same objects, regardless of their
positions in the array.

=back

See also: L<https://en.cppreference.com/w/c/algorithm/qsort>

=head2 C<SDL_abs( ... )>

Standard C<abs( ... )> function.

	my $zero = SDL_abs( -459 ); # Ha

Expected parameters include:

=over

=item C<x> - integer value

=back

Returns the absolute value of C<x>.

=head2 C<SDL_isalpha( ... )>

Checks if the given character is an alphabetic character, i.e. either an
uppercase letter (ABCDEFGHIJKLMNOPQRSTUVWXYZ), or a lowercase letter
(abcdefghijklmnopqrstuvwxyz).

Expected parameters include:

=over

=item C<ch> - character to classify

=back

Returns non-zero value if the character is an alphabetic character, zero
otherwise.

=head2 C<SDL_isalnum( ... )>

Checks if the given character is an alphanumeric character as classified by the
current C locale. In the default locale, the following characters are
alphanumeric:

=over

=item * digits (0123456789)

=item * uppercase letters (ABCDEFGHIJKLMNOPQRSTUVWXYZ)

=item * lowercase letters (abcdefghijklmnopqrstuvwxyz)

=back

Expected parameters include:

=over

=item C<ch> - character to classify

=back

Returns non-zero value if the character is an alphanumeric character, zero
otherwise.

=head2 C<SDL_isblank( ... )>

Checks if the given character is a blank character in the current C locale.

Expected parameters include:

=over

=item C<ch> - character to classify

=back

Returns non-zero value if the character is a blank character, zero otherwise.

=head2 C<SDL_iscntrl( ... )>

Checks if the given character is a control character, i.e. codes 0x00-0x1F and
0x7F.

Expected parameters include:

=over

=item C<ch> - character to classify

=back

Returns non-zero value if the character is a control character, zero otherwise.

=head2 C<SDL_isdigit( ... )>

Checks if the given character is a numeric character (0123456789).

Expected parameters include:

=over

=item C<ch> - character to classify

=back

Returns non-zero value if the character is a numeric character, zero otherwise.

=head2 C<SDL_isxdigit( ... )>

Checks if the given character is a hexadecimal numeric character
(0123456789abcdefABCDEF) or is classified as a hexadecimal character.

Expected parameters include:

=over

=item C<ch> - character to classify

=back

Returns non-zero value if the character is an hexadecimal numeric character,
zero otherwise.

=head2 C<SDL_ispunct( ... )>

Checks if the given character is a punctuation character in the current C
locale. The default C locale classifies the characters
!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~ as punctuation.

Expected parameters include:

=over

=item C<ch> - character to classify

=back

Returns non-zero value if the character is a punctuation character, zero
otherwise.

=head2 C<SDL_isspace( ... )>

Checks if the given character is a whitespace character, i.e. either space
(0x20), form feed (0x0c), line feed (0x0a), carriage return (0x0d), horizontal
tab (0x09) or vertical tab (0x0b).

Expected parameters include:

=over

=item C<ch> - character to classify

=back

Returns non-zero value if the character is a whitespace character, zero
otherwise.

=head2 C<SDL_isupper( ... )>

Checks if the given character is an uppercase character according to the
current C locale. In the default "C" locale, isupper returns true only for the
uppercase letters (ABCDEFGHIJKLMNOPQRSTUVWXYZ).

Expected parameters include:

=over

=item C<ch> - character to classify

=back

Returns non-zero value if the character is an uppercase letter, zero otherwise.

=head2 C<SDL_islower( ... )>

Checks if the given character is classified as a lowercase character according
to the current C locale. In the default "C" locale, islower returns true only
for the lowercase letters (abcdefghijklmnopqrstuvwxyz).

Expected parameters include:

=over

=item C<ch> - character to classify

=back

Returns non-zero value if the character is a lowercase letter, zero otherwise.

=head2 C<SDL_isprint( ... )>

Checks if the given character can be printed, i.e. it is either a number
(0123456789), an uppercase letter (ABCDEFGHIJKLMNOPQRSTUVWXYZ), a lowercase
letter (abcdefghijklmnopqrstuvwxyz), a punctuation
character(!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~), or space, or any character
classified as printable by the current C locale.

Expected parameters include:

=over

=item C<ch> - character to classify

=back

Returns non-zero value if the character can be printed, zero otherwise.

=head2 C<SDL_isgraph( ... )>

Checks if the given character has a graphical representation, i.e. it is either
a number (0123456789), an uppercase letter (ABCDEFGHIJKLMNOPQRSTUVWXYZ), a
lowercase letter (abcdefghijklmnopqrstuvwxyz), or a punctuation
character(!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~), or any graphical character
specific to the current C locale.

Expected parameters include:

=over

=item C<ch> - character to classify

=back

Returns non-zero value if the character has a graphical representation
character, zero otherwise.

=head2 C<SDL_toupper( ... )>

Converts the given character to uppercase according to the character conversion
rules defined by the currently installed C locale.

In the default "C" locale, the following lowercase letters
abcdefghijklmnopqrstuvwxyz are replaced with respective uppercase letters
ABCDEFGHIJKLMNOPQRSTUVWXYZ.

Expected parameters include:

=over

=item C<ch> - character to convert

=back

Returns uppercase version of C<ch> or unmodified C<ch> if no uppercase version
is defined by the current C locale.

=head2 C<SDL_tolower( ... )>

Converts the given character to lowercase according to the character conversion
rules defined by the currently installed C locale.

In the default "C" locale, the following uppercase letters
ABCDEFGHIJKLMNOPQRSTUVWXYZ are replaced with respective lowercase letters
abcdefghijklmnopqrstuvwxyz. Expected parameters include:

=over

=item C<ch> - character to convert

=back

Returns lowercase version of C<ch> or unmodified C<ch> if no lowercase version
is listed in the current C locale.

=head2 C<SDL_crc32( ... )>

This runs through a practical algorithm for the CRC-32 variant of CRC.

	warn SDL_crc32( 0, "123456789", 9);
	warn SDL_crc32( 0, "123456789");
	warn 0xCBF43926;

Expected parameters include:

=over

=item C<crc> - pointer to context variable

=item C<data> - input buffer to checksum

=item C<len> - length of C<data> (this is optional)

=back

The checksum is returned.

=head2 C<SDL_memset( ... )>

Fill a block of memory.

	my $str = 'almost every programmer should know memset!';
	SDL_memset($str, '-', 6);
	print $str; # '------ every programmer should know memset!'

Expected parameters include:

=over

=item C<ptr> - Pointer to the block of memory to fill.

=item C<value> - Value to set.

=item C<num> - Number of bytes to be set to C<value>

=back

The C<ptr> is returned.

=head2 C<SDL_zero)( ... )>

Fill a block of memory with zeros.

Expected parameters include:

=over

=item C<ptr> - Pointer to the block of memory to fill.

=back

The C<ptr> is returned.

=head2 C<SDL_memcpy( ... )>

Copies C<count> bytes from the object pointed to by C<src> to the object
pointed to by C<dest>. Both objects are reinterpreted as arrays of C<unsigned
char>.

	my $source = 'once upon a midnight dreary...';
	my $dest = 'xxxx';
	SDL_memcpy(\$dest, \$source, 4);

Expected parameters include:

=over

=item C<dest> - pointer to the memory location to copy to

=item C<src> - pointer to the memory location to copy from

=item C<count> - number of bytes to copy

=back

C<dest> is returned.

=begin internals

# Make this work without isCow flag

use Devel::Peek; my $source = 'once upon a midnight dreary...';

# my $dest = 'xxxx'; Devel::Peek::Dump( $dest ); SDL_memcpy($dest, $source, 4);
warn $dest;

# $dest = 'x' x 4; # Does not work Devel::Peek::Dump( $dest );
SDL_memcpy($dest, $source, 4); warn $dest;

=end internals

=head2 C<SDL_memmove( ... )>

Copies C<count> bytes from the object pointed to by C<src> to the object
pointed to by C<dest>. Both objects are reinterpreted as arrays of C<unsigned
char>.

	my $source = 'once upon a midnight dreary...';
	my $dest = 'xxxx';
	SDL_memmove(\$dest, \$source, 4);
	print $dest; # once

...or...

    use FFI::Platypus::Buffer qw[scalar_to_pointer];
    my $str = '1234567890';
    SDL_memmove( scalar_to_pointer($str) + 4, scalar_to_pointer($str) + 3, 3 )
        ;    # copies from [4, 5, 6] to [5, 6, 7]
    print $str;    # 1234456890

Expected parameters include:

=over

=item C<dest> - pointer to the memory location to copy to

=item C<src> - pointer to the memory location to copy from

=item C<count> - number of bytes to copy

=back

C<dest> is returned.

=head2 C<SDL_memcmp( ... )>

Reinterprets the objects pointed to by lhs and rhs as arrays of unsigned char
and compares the first count characters of these arrays. The comparison is done
lexicographically.

    sub demo ( $lhs, $rhs, $sz ) {
        print substr( $lhs, 0, $sz );
        my $rc = SDL_memcmp( \$lhs, \$rhs, $sz );
        print $rc == 0 ? ' compares equal to ' :
            $rc < 0    ? ' precedes ' :
            $rc > 0    ? ' follows ' :
            '';
        print substr( $rhs, 0, $sz ) . " in lexicographical order\n";
    }
    #
    my $a1 = 'abc';
    my $a2 = 'abd';
    demo( $a1, $a2, length $a1 ); # abc precedes abd in lexicographical order
    demo( $a2, $a1, length $a1 ); # abd follows abc in lexicographical order
    demo( $a1, $a1, length $a1 ); # abc compares equal to abc in lexicographical order

Expected parameters include:

=over

=item C<lhs> - pointer to memory to compare

=item C<rhs> - pointer to memory to compare

=item C<len> - number of bytes to examine

=back

Returns a negative value if the first differing byte (reinterpreted as unsigned
char) in lhs is less than the corresponding byte in C<rhs>.

​C<0​> if all count bytes of C<lhs> and C<rhs> are equal.

Positive value if the first differing byte in <lhs> is greater than the
corresponding byte in C<rhs>.

=head2 C<SDL_wcslen( ... )>

Returns the length of a wide string, that is the number of non-null wide
characters that precede the terminating null wide character.

    use utf8;
    my $str = "木之本 桜";
    binmode STDOUT, ":utf8";    # or `perl -CS file.pl` to avoid 'Wide character' noise
    print "The length of '$str' is " . SDL_wcslen($str) . "\n";
	# The length of '木之本 桜' is 5

Expected parameters include:

=over

=item C<str> - pointer to the wide string to be examined

=back

=head2 C<SDL_wcslcpy( ... )>

Copies at most C<count> characters of the wide string pointed to by C<src>
(including the terminating null wide character) to wide character array pointed
to by C<dest>.

Expected parameters include:

=over

=item C<dest> - pointer to the wide character array to copy to

=item C<src> - pointer to the wide string to copy from

=item C<count> - maximum number of wide characters to copy

=back

Returns C<dest>.

=head2 C<SDL_wcslcat( )>

Appends at most C<count> wide characters from the wide string pointed to by
C<src>, stopping if the null terminator is copied, to the end of the character
string pointed to by C<dest>. The wide character src[0] replaces the null
terminator at the end of dest. The null terminator is always appended in the
end (so the maximum number of wide characters the function may write is
C<count>+1).

Expected parameters include:

=over

=item C<dest> - pointer to the null-terminated wide string to append to

=item C<src> - pointer to the null-terminated wide string to copy from

=item C<count> - maximum number of wide characters to copy

=back

Returns zero on success, returns non-zero on error.

=head2 C<SDL_wcsdup( ... )>

Duplicate a wide character string.

Expected parameters include:

=over

=item C<wstr> - wide character string to duplicate

=back

Returns a newly allocated wide character string on success.

=head2 C<SDL_wcsstr( ... )>

Finds the first occurrence of the wide string C<src> in the wide string pointed
to by C<dest>. The terminating null characters are not compared.

    use utf8;
    binmode STDOUT, ":utf8";    # or `perl -CS file.pl` to avoid 'Wide character' noise
    my $origin = "アルファ, ベータ, ガンマ, アルファ, ベータ, ガンマ.";
    my $target = "ベータ";
    my $result = $origin;
    print "Substring to find: \"$target\"\nString to search: \"$origin\"\n\n";
    for ( ; ( $result = SDL_wcsstr( $result, $target ) ); $result = substr $result, 1 ) {
        print "Found: \"$result\"\n";
    }

Expected parameters include:

=over

=item C<dest> - pointer to the null-terminated wide string to examine

=item C<src> - pointer to the null-terminated wide string to search for

=back

Returns a pointer to the first character of the found substring in C<dest>, or
a null pointer if no such substring is found. If C<src> points to an empty
string, C<dest> is returned.

=head2 C<SDL_wcscmp( ... )>

Compares two null-terminated wide strings lexicographically.

	use utf8;
    binmode STDOUT, ":utf8";    # or `perl -CS file.pl` to avoid 'Wide character' noise
    my $string = "どうもありがとうございます";
    demo( $string,              "どうも" );
    demo( $string,              "助かった" );
    demo( substr( $string, 9 ), substr( "ありがとうございます", 6 ) );

    sub demo ( $lhs, $rhs ) {
        my $rc  = SDL_wcscmp( $lhs, $rhs );
        my $rel = $rc < 0 ? 'precedes' : $rc > 0 ? 'follows' : 'equals';
        printf( "[%ls] %s [%ls]\n", $lhs, $rel, $rhs );
    }

Expected parameters include:

=over

=item C<lhs> - pointer to a wide string

=item C<rhs> - pointer to a wide string

=back

Returns a negative value if C<lhs> appears before C<rhs> in lexicographical
order.

Returns zero if C<lhs> and C<rhs> compare equal.

Returns a positive value if C<lhs> appears after C<rhs> in lexicographical
order.

=head2 C<SDL_wcsncmp( ... )>

Compares at most C<count> wide characters of two null-terminated wide strings.
The comparison is done lexicographically.

    use utf8;
    binmode STDOUT, ":utf8";    # or `perl -CS file.pl` to avoid 'Wide character' noise
    my $str1 = "안녕하세요";
    my $str2 = "안녕히 가십시오";
    demo( $str1, $str2, 5 );
    demo( $str2, $str1, 8 );
    demo( $str1, $str2, 2 );

    sub demo ( $lhs, $rhs, $sz ) {
        my $rc  = SDL_wcsncmp( $lhs, $rhs, $sz );
        my $rel = $rc < 0 ? 'precede' : $rc > 0 ? 'follow' : 'equal';
        printf( "First %d characters of [%ls] %s [%ls]\n", $sz, $lhs, $rel, $rhs );
    }

Expected parameters include:

=over

=item C<lhs> - pointer to a wide string

=item C<rhs> - pointer to a wide string

=item C<count> - maximum number of characters to compare

=back

Returns a negative value if C<lhs> appears before C<rhs> in lexicographical
order.

Returns zero if C<lhs> and C<rhs> compare equal.

Returns a positive value if C<lhs> appears after C<rhs> in lexicographical
order.

=head2 C<SDL_wcscasecmp( ... )>

Compares at wide characters of two null-terminated wide strings.

    use utf8;
    binmode STDOUT, ":utf8";    # or `perl -CS file.pl` to avoid 'Wide character' noise
    my $str1 = "안녕하세요";
    my $str2 = "안녕히 가십시오";
    demo( $str1, $str2, 5 );
    demo( $str2, $str1, 8 );
    demo( $str1, $str2, 2 );

    sub demo ( $lhs, $rhs, $sz ) {
        my $rc  = SDL_wcscasecmp( $lhs, $rhs );
        my $rel = $rc < 0 ? 'precede' : $rc > 0 ? 'follow' : 'equal';
        printf( "First %d characters of [%ls] %s [%ls]\n", $sz, $lhs, $rel, $rhs );
    }

Expected parameters include:

=over

=item C<lhs> - pointer to a wide string

=item C<rhs> - pointer to a wide string

=back

Returns a negative value if C<lhs> appears before C<rhs> in lexicographical
order.

Returns zero if C<lhs> and C<rhs> compare equal.

Returns a positive value if C<lhs> appears after C<rhs> in lexicographical
order.


=head2 C<SDL_wcsncasecmp( ... )>

Compares at most C<count> wide characters of two null-terminated wide strings
while ignoring case.

    use utf8;
    binmode STDOUT, ":utf8";    # or `perl -CS file.pl` to avoid 'Wide character' noise
    my $str1 = "안녕하세요";
    my $str2 = "안녕히 가십시오";
    demo( $str1, $str2, 5 );
    demo( $str2, $str1, 8 );
    demo( $str1, $str2, 2 );

    sub demo ( $lhs, $rhs, $sz ) {
        my $rc  = SDL_wcsncasecmp( $lhs, $rhs, $sz );
        my $rel = $rc < 0 ? 'precede' : $rc > 0 ? 'follow' : 'equal';
        printf( "First %d characters of [%ls] %s [%ls]\n", $sz, $lhs, $rel, $rhs );
    }

Expected parameters include:

=over

=item C<lhs> - pointer to a wide string

=item C<rhs> - pointer to a wide string

=item C<count> - maximum number of characters to compare

=back

Returns a negative value if C<lhs> appears before C<rhs> in lexicographical
order.

Returns zero if C<lhs> and C<rhs> compare equal.

Returns a positive value if C<lhs> appears after C<rhs> in lexicographical
order.

=head2 C<SDL_strlen( ... )>

Returns the length of the given byte string, that is, the number of characters
in a character array whose first element is pointed to by C<str> up to and not
including the first null character. The behavior is undefined if there is no
null character in the character array pointed to by C<str>.

    my $str = "How many characters does this string contain?\0";
    printf "without null character: %d\nwith null character: %d", SDL_strlen($str), length $str;

Expected parameters include:

=over

=item <str> - string to be examined

=back

Returns the length of C<str>.

=head2 C<SDL_strlcpy( ... )>

Copies the character string pointed to by C<src>, including the null
terminator, to the character array whose first element is pointed to by
C<dest>.

Expected parameters include:

=over

=item C<dest> - destination string

=item C<src> - string to copy from

=item C<max> - maximum number of characters to copy

=back

Returns the new length of the entire string.

=head2 C<SDL_utf8strlcpy( ... )>

Copies the character string pointed to by C<src>, including the null
terminator, to the character array whose first element is pointed to by
C<dest>.

Expected parameters include:

=over

=item C<dest> - destination string

=item C<src> - string to copy from

=item C<max> - maximum number of bytes to copy

=back

Returns the new length of the entire string.


=head2 C<SDL_strlcat( ... )>

Copies the character string pointed to by C<src>, including the null
terminator, to the character array whose first element is pointed to by
C<dest>.

Expected parameters include:

=over

=item C<dest> - destination string

=item C<src> - string to copy from

=item C<max> - maximum number of bytes to copy

=back

Returns the new length of the entire string.

=head2 C<SDL_strdup( ... )>

Duplicate a string.

Expected parameters include:

=over

=item C<str> - string to duplicate

=back

Returns the new string.

=head2 C<SDL_strrev( ... )>

Reverses a string.

Expected parameters include:

=over

=item C<str> - string to reverse

=back

Returns the given string in reverse.

=head2 C<SDL_strupr( ... )>

Get a string in uppercase.

Expected parameters include:

=over

=item C<str> - string to make uppercase

=back

Returns the given string in uppercase.

=head2 C<SDL_strlwr( ... )>

Get a string in lowercase.

Expected parameters include:

=over

=item C<str> - string to make lowercase

=back

Returns the given string in lowercase.

=head2 C<SDL_strchr( ... )>

Finds the first occurrence of C<ch> (after conversion to C<char> as if by
C<(char)ch> in C) in the null-terminated byte string pointed to by C<str> (each
character interpreted as C<unsigned char>). The terminating null character is
considered to be a part of the string and can be found when searching for
'C<\0>'.

    my $str    = "Try not. Do, or do not. There is no try.";
    my $target = 'T';
    my $result = $str;
    while ( ( $result = SDL_strchr( $result, $target ) ) ) {
        printf "Found '%s' starting at '%s'\n", $target, $result;
        $result = substr $result,
            1;    # Increment result, otherwise we'll find target at the same location
    }

Expected parameters include:

=over

=item C<str> - byte string to be analyzed

=item C<ch> - character to search for

=back

Returns a pointer to the found character in C<str>, or null if no such
character is found.

=head2 C<SDL_strrchr( ... )>

    my $szSomeFileName = "foo/bar/foobar.txt";
    my $pLastSlash     = SDL_strrchr( $szSomeFileName, '/' );
    my $pszBaseName    = $pLastSlash ? substr $pLastSlash, 1 : $szSomeFileName;
    printf "Base Name: %s", $pszBaseName;

Finds the last occurrence of C<ch> (after conversion to C<char> as if by
C<(char)ch> in C) in the null-terminated byte string pointed to by C<str> (each
character interpreted as C<unsigned char>). The terminating null character is
considered to be a part of the string and can be found when searching for
'C<\0>'.

Expected parameters include:

=over

=item C<str> - string to be analyzed

=item C<ch> - character to search for

=back

Returns pointer to the found character in C<str>, or null if no such character
is found.

=head2 C<SDL_strstr( ... )>

Finds the first occurrence of the null-terminated byte string pointed to by
C<substr> in the null-terminated byte string pointed to by C<str>. The
terminating null characters are not compared.

    sub find_str ( $str, $substr ) {
        my $pos = SDL_strstr( $str, $substr );
        if ($pos) {
            printf "found the string '%s' in '%s' at position: %ld\n", $substr, $str,
                length($str) - length($pos);
        }
        else {
            printf( "the string '%s' was not found in '%s'\n", $substr, $str );
        }
    }
    my $str = "one two three";
    find_str( $str, "two" );
    find_str( $str, "" );
    find_str( $str, "nine" );
    find_str( $str, "n" );

Expected parameters include:

=over

=item C<str> - byte string to examine

=item C<substr> - byte string to search for

=back

Returns pointer to the first character of the found substring in C<str>, or a
null pointer if such substring is not found. If C<substr> points to an empty
string, C<str> is returned.

=head2 C<SDL_strtokr( ... )>

Finds the next token in a null-terminated byte string pointed to by C<str>. The
separator characters are identified by null-terminated byte string pointed to
by C<delim>.

This function is designed to be called multiple times to obtain successive
tokens from the same string.

Expected parameters include:

=over

=item C<str> - byte string to tokenize

=item C<delim> - string identifying delimiters

=item C<saveptr> - pointer to a string used internally to maintain context

=back

Returns a pointer to the beginning of then ext token or null if there are no
more tokens.

=head2 C<SDL_utf8strlen( ... )>

Find the length of a UTF-8 character string

Expected parameters include:

=over

=item C<str> - a UTF-8 string

=back

Returns the number of UTF-8 characters in C<str>.

=head2 C<SDL_itoa( ... )>

Converts an integer C<value> to a null-terminated string using the specified
C<base> and stores the result in the array given by C<str> parameter.

    my $i      = 1750;
    my $buffer = ' ';
    printf "decimal: %s\n",     SDL_itoa( $i, $buffer, 10 );
    printf "hexadecimal: %s\n", SDL_itoa( $i, $buffer, 16 );
    printf "binary: %s\n",      SDL_itoa( $i, $buffer, 2 );

Expected parameters include:

=over

=item C<value> - value to be converted to a string

=item C<str> - location to store result

=item C<base> - numerical base used to represent the value as a string, between 2 and 36, where 10 means decimal base, 16 hexadecimal, 8 octal, and 2 binary.

=back

Returns a pointer to the resulting string; same as C<str>.

=head2 C<SDL_uitoa( ... )>

Converts an unsigned integer C<value> to a null-terminated string using the
specified C<base> and stores the result in the array given by C<str> parameter.

    my $i      = 1750;
    my $buffer = ' ';
    printf "decimal: %s\n",     SDL_uitoa( $i, $buffer, 10 );
    printf "hexadecimal: %s\n", SDL_uitoa( $i, $buffer, 16 );
    printf "binary: %s\n",      SDL_uitoa( $i, $buffer, 2 );

Expected parameters include:

=over

=item C<value> - value to be converted to a string

=item C<str> - location to store result

=item C<base> - numerical base used to represent the value as a string, between 2 and 36, where 10 means decimal base, 16 hexadecimal, 8 octal, and 2 binary.

=back

Returns a pointer to the resulting string; same as C<str>.

=head2 C<SDL_ltoa( ... )>

Converts an long C<value> to a null-terminated string using the specified
C<base> and stores the result in the array given by C<str> parameter.

    my $i      = 1750;
    my $buffer = ' ';
    printf "decimal: %s\n",     SDL_ltoa( $i, $buffer, 10 );
    printf "hexadecimal: %s\n", SDL_ltoa( $i, $buffer, 16 );
    printf "binary: %s\n",      SDL_ltoa( $i, $buffer, 2 );

Expected parameters include:

=over

=item C<value> - value to be converted to a string

=item C<str> - location to store result

=item C<base> - numerical base used to represent the value as a string, between 2 and 36, where 10 means decimal base, 16 hexadecimal, 8 octal, and 2 binary.

=back

Returns a pointer to the resulting string; same as C<str>.

=head2 C<SDL_ultoa( ... )>

Converts an unsigned long C<value> to a null-terminated string using the
specified C<base> and stores the result in the array given by C<str> parameter.

    my $i      = 1750;
    my $buffer = ' ';
    printf "decimal: %s\n",     SDL_ultoa( $i, $buffer, 10 );
    printf "hexadecimal: %s\n", SDL_ultoa( $i, $buffer, 16 );
    printf "binary: %s\n",      SDL_ultoa( $i, $buffer, 2 );

Expected parameters include:

=over

=item C<value> - value to be converted to a string

=item C<str> - location to store result

=item C<base> - numerical base used to represent the value as a string, between 2 and 36, where 10 means decimal base, 16 hexadecimal, 8 octal, and 2 binary.

=back

Returns a pointer to the resulting string; same as C<str>.

=head2 C<SDL_lltoa( ... )>

Converts an 64-bit C<value> to a null-terminated string using the specified
C<base> and stores the result in the array given by C<str> parameter.

    my $i      = 1750;
    my $buffer = ' ';
    printf "decimal: %s\n",     SDL_lltoa( $i, $buffer, 10 );
    printf "hexadecimal: %s\n", SDL_lltoa( $i, $buffer, 16 );
    printf "binary: %s\n",      SDL_lltoa( $i, $buffer, 2 );

Expected parameters include:

=over

=item C<value> - value to be converted to a string

=item C<str> - location to store result

=item C<base> - numerical base used to represent the value as a string, between 2 and 36, where 10 means decimal base, 16 hexadecimal, 8 octal, and 2 binary.

=back

Returns a pointer to the resulting string; same as C<str>.

=head2 C<SDL_ulltoa( ... )>

Converts an unsigned 64-bit C<value> to a null-terminated string using the
specified C<base> and stores the result in the array given by C<str> parameter.

    my $i      = 1750;
    my $buffer = ' ';
    printf "decimal: %s\n",     SDL_ulltoa( $i, $buffer, 10 );
    printf "hexadecimal: %s\n", SDL_ulltoa( $i, $buffer, 16 );
    printf "binary: %s\n",      SDL_ulltoa( $i, $buffer, 2 );

Expected parameters include:

=over

=item C<value> - value to be converted to a string

=item C<str> - location to store result

=item C<base> - numerical base used to represent the value as a string, between 2 and 36, where 10 means decimal base, 16 hexadecimal, 8 octal, and 2 binary.

=back

Returns a pointer to the resulting string; same as C<str>.

=head2 C<SDL_atoi( ... )>

Interprets an integer value in a byte string pointed to by str.

    for my $str ( "42", "3.14159", "31337 with words", "words and 2" ) {
        printf "SDL_atoi('%s') is %s\n", $str, SDL_atoi($str);
    }

Discards any whitespace characters until the first non-whitespace character is
found, then takes as many characters as possible to form a valid integer number
representation and converts them to an integer value. The valid integer value
consists of the following parts:

=over

=item optional plus or minus sign

=item numeric digits

=back


Expected parameters include:

=over

=item C<str> - byte string to be interpreted

=back

Returns an integer value corresponding to the contents of C<str> on success. If
the converted value falls out of range of corresponding return type, the return
value is undefined. If no conversion can be performed, ​C<0​> is returned.

=head2 C<SDL_atof( ... )>

Interprets a floating point value in a byte string pointed to by C<str>.

    for my $str ( "0.0000000123", "0.012", "15e16", "-0x1afp-2", "inF", "Nan", "invalid" ) {
        printf "SDL_atof('%s') is %s\n", $str, SDL_atof($str);
    }

Function discards any whitespace characters until first non-whitespace
character is found. Then it takes as many characters as possible to form a
valid floating-point representation and converts them to a floating-point
value. The valid floating-point value can be one of the following:

=over

=item decimal floating-point expression. It consists of the following parts:

=over

=item (optional) plus or minus sign

=item nonempty sequence of decimal digits optionally containing decimal-point character (as determined by the current C locale) (defines significand)

=item (optional) C<e> or C<E> followed with optional minus or plus sign and nonempty sequence of decimal digits (defines exponent to base 10)

=back

=back

Expected parameters include:

=over

=item C<str> - byte string to be interpreted

=back

Returns a double value corresponding to the contents of C<str> on success. If
the converted value falls out of range of the return type, the return value is
undefined. If no conversion can be performed, C<0.0> is returned.


=head2 C<SDL_strtol( ... )>

Interprets an integer value in a byte string pointed to by C<str>.

    my $p = "10 200000000000000000000000000000 30 -40 junk";
    printf( "Parsing '%s':\n", $p );
    while (1) {
        my $i = SDL_strtol( $p, \my $end, 10 );
        last if $p eq $end;
        printf( "Extracted '%s', SDL_strtol returned %ld.", $p, $i );
        $p = $end;
        print "\n";
    }
    printf( "Unextracted leftover: '%s'\n\n", $p );

    # parsing without error handling
    printf( "\"1010\" in binary  --> %ld\n",            SDL_strtol( "1010", undef, 2 ) );
    printf( "\"12\"   in octal   --> %ld\n",            SDL_strtol( "12",   undef, 8 ) );
    printf( "\"A\"    in hex     --> %ld\n",            SDL_strtol( "A",    undef, 16 ) );
    printf( "\"junk\" in base-36 --> %ld\n",            SDL_strtol( "junk", undef, 36 ) );
    printf( "\"012\"  in auto-detected base --> %ld\n", SDL_strtol( "012",  undef, 0 ) );
    printf( "\"0xA\"  in auto-detected base --> %ld\n", SDL_strtol( "0xA",  undef, 0 ) );
    printf( "\"junk\" in auto-detected base --> %ld\n", SDL_strtol( "junk", undef, 0 ) );

Expected parameters include:

=over

=item C<str> - byte string to be interpreted

=item C<str_end> -  pointer to a pointer to character

=item C<base> - base of the interpreted integer value

=back

Returns an integer value corresponding to the contents of C<str> if successful.
Otherwise, C<0> is returned.

=head2 C<SDL_strtoul( ... )>

Interprets an unsigned integer value in a byte string pointed to by C<str>.

    my $p = "10 200000000000000000000000000000 30 -40";
    printf( "Parsing '%s':\n", $p );
    for ( my $i = SDL_strtoul( $p, \my $end, 10 ); $p ne $end; $i = SDL_strtoul( $p, \$end, 10 ) ) {
        printf( "'%s' -> ", $p );
        $p = $end;
        printf( "%lu\n", $i );
    }

Expected parameters include:

=over

=item C<str> - byte string to be interpreted

=item C<str_end> -  pointer to a pointer to character

=item C<base> - base of the interpreted integer value

=back

Returns an integer value corresponding to the contents of C<str> if successful.
Otherwise, C<0> is returned.

=head2 C<SDL_strtoll( ... )>

Interprets a 64-bit integer value in a byte string pointed to by C<str>.

Expected parameters include:

=over

=item C<str> - byte string to be interpreted

=item C<str_end> -  pointer to a pointer to character

=item C<base> - base of the interpreted integer value

=back

Returns an integer value corresponding to the contents of C<str> if successful.
Otherwise, C<0> is returned.

=head2 C<SDL_strtoull( ... )>

Interprets an unsigned 64-bit integer value in a byte string pointed to by
C<str>.

Expected parameters include:

=over

=item C<str> - byte string to be interpreted

=item C<str_end> -  pointer to a pointer to character

=item C<base> - base of the interpreted integer value

=back

Returns an integer value corresponding to the contents of C<str> if successful.
Otherwise, C<0> is returned.

=head2 C<SDL_strtod( ... )>

Interprets a floating-point value in a byte string pointed to by C<str>.



Expected parameters include:

=over

=item C<str> - byte string to be interpreted

=item C<str_end> -  pointer to a pointer to character

=back

Returns an floating point value corresponding to the contents of C<str> if
successful. Otherwise, C<0> is returned.

=head2 C<SDL_strcmp( ... )>

Compares two null-terminated byte strings lexicographically.

    sub demo ( $lhs, $rhs ) {
        my $rc  = SDL_strcmp( $lhs, $rhs );
        my $rel = $rc < 0 ? "precedes" : $rc > 0 ? "follows" : "equals";
        printf( "[%s] %s [%s]\n", $lhs, $rel, $rhs );
    }
    my $string = "Hello World!";
    demo( $string, "Hello!" );
    demo( $string, "Hello" );
    demo( $string, "Hello there" );
    demo( substr( "Hello, everybody!", 12 ), substr "Hello, somebody!", 11 );

Expected parameters include:

=over

=item C<lhs> - byte string to compare

=item C<rhs> - byte string to compare

=back

Returns a negative value if C<lhs> appears before C<rhs> in lexicographical
order.

Returns zero if C<lhs> and C<rhs> compare equal.

Returns a positive value if C<lhs> appears after C<rhs> in lexicographical
order.

=head2 C<SDL_strncmp( ... )>

Compares at most count characters of two possibly null-terminated arrays. The
comparison is done lexicographically. Characters following the null character
are not compared.

    sub demo ( $lhs, $rhs, $sz ) {
        my $rc  = SDL_strncmp( $lhs, $rhs, $sz );
        my $rel = $rc < 0 ? "precedes" : $rc > 0 ? "follows" : "equals";
        printf( "First %d chars of [%s] %s [%s]\n", $sz, $lhs, $rel, $rhs );
    }
    my $string = "Hello World!";
    demo( $string,                           "Hello!",                         5 );
    demo( $string,                           "Hello",                          10 );
    demo( $string,                           "Hello there",                    10 );
    demo( substr( "Hello, everybody!", 12 ), substr( "Hello, somebody!", 11 ), 5 );

Expected parameters include:

=over

=item C<lhs> - byte string to compare

=item C<rhs> - byte string to compare

=item C<count> - maximum number of characters to compare

=back

Returns a negative value if C<lhs> appears before C<rhs> in lexicographical
order.

Returns zero if C<lhs> and C<rhs> compare equal, or if C<count> is zero.

Returns a positive value if C<lhs> appears after C<rhs> in lexicographical
order.

=head2 C<SDL_strcasecmp( ... )>

Compares characters of two possibly strings. The comparison is done
lexicographically. Characters following the null character are not compared.

Expected parameters include:

=over

=item C<lhs> - byte string to compare

=item C<rhs> - byte string to compare

=back

Returns a negative value if C<lhs> appears before C<rhs> in lexicographical
order.

Returns zero if C<lhs> and C<rhs> compare equal, or if C<count> is zero.

Returns a positive value if C<lhs> appears after C<rhs> in lexicographical
order.

=head2 C<SDL_strncasecmp( ... )>

Compares up to C<count> characters of two possibly strings ignoring case. The
comparison is done lexicographically. Characters following the null character
are not compared.

Expected parameters include:

=over

=item C<lhs> - byte string to compare

=item C<rhs> - byte string to compare

=item C<count> - maximum number of characters to compare

=back

Returns a negative value if C<lhs> appears before C<rhs> in lexicographical
order.

Returns zero if C<lhs> and C<rhs> compare equal, or if C<count> is zero.

Returns a positive value if C<lhs> appears after C<rhs> in lexicographical
order.

=head2 C<SDL_sscanf( ... )>

Reads data from a variety of sources, interprets it according to C<format> and
stores the results into given locations.

    my ( $i, $j );                                        # int
    my ( $x, $y );                                        # float
    my $str1  = ' ' x 10;                                 # You *must* pre-define strings for length
    my $str2  = ' ' x 4;
    my $warr  = ' ' x 8;                                  # Don't forget wide chars
    my $input = '25 54.32E-1 Thompson 56789 0123 56ß水';

    # parses as follows:
    # %d: an integer
    # %f: a floating-point value
    # %9s: a string of at most 9 non-whitespace characters
    # %2d: two-digit integer (dig7its 5 and 6)
    # %f: a floating-point value (digits 7, 8, 9)
    # %*d an integer which isn't stored anywhere
    # ' ': all consecutive whitespace
    # %3[0-9]: a string of at most 3 digits (digits 5 and 6)
    # %2lc: two wide characters, using multibyte to wide conversion
    my $ret = SDL_sscanf( $input, "%d%f%9s%2d%f%*d %3[0-9]%2lc", \$i, \$x, $str1, \$j, \$y, $str2,
        $warr );
    printf << '', $ret, $i, $x, $str1, $j, $y, $str2, unpack 'WW', $warr;
    Converted %d fields:
      i = %d
      x = %f
      str1 = %s
      j = %s
      y = %f
      str2 = %s
      warr[0] = U+%x warr[1] = U+%x

Expected parameters include:

=over

=item C<buffer> - string to read from

=item C<format> - string similar to C<printf>

=item C<vars> - list of storage locations

=back

Returns the number of receiving arguments successfully assigned (which may be
zero in case a matching failure occurred before the first receiving argument
was assigned), or EOF if input failure occurs before the first receiving
argument was assigned.

=head2 C<SDL_vsscanf( ... )>

Reads data from a string, interprets it according to C<format> and stores the
results into locations defined by C<vlist>.

    my ( $n, $m );
    printf "Parsing '1 2'...%s\n",
        SDL_vsscanf( '1 2', '%d %d', \$n, \$m ) == 2 ? 'success' : 'failure';
    printf "Parsing '1 a'...%s\n",
        SDL_vsscanf( '1 a', '%d %s', \$n, \$m ) == 2 ? 'success' : 'failure';

Expected parameters include:

=over

=item C<buffer> - string to read from

=item C<format> - string specifying how to read the input

=item C<vlist> - variable argument list containing the receiving arguments

=back

Returns the number of arguments successfully read or C<EOF> if failure occurs.

=head2 C<SDL_snprintf( ... )>

Loads the data from the given locations, converts them to character string
equivalents and writes the results to a string buffer.

    print "Strings:\n";
    my $s = 'Hello';
    SDL_snprintf( my $output, 128, "\t[%10s]\n\t[%-10s]\n\t[%*s]\n\t[%-10.*s]\n\t[%-*.*s]\n",
        $s, $s, 10, $s, 4, $s, 10, 4, $s );
    print $output;
    SDL_snprintf( $output, 100, "Characters:\t%c %%\n", 65 );
    print $output;
    print "Integers\n";
    SDL_snprintf( $output, 100, "Decimal:\t%i %d %.6i %i %.0i %+i %i\n", 1, 2, 3, 0, 0, 4, -4 );
    print $output;
    SDL_snprintf( $output, 100, "Hexadecimal:\t%x %x %X %#x\n", 5, 10, 10, 6 );
    print $output;
    SDL_snprintf( $output, 100, "Octal:\t%o %#o %#o\n", 10, 10, 4 );
    print $output;
    print "Floating point\n";
    SDL_snprintf( $output, 100, "Rounding:\t%f %.0f %.32f\n", 1.5, 1.5, 1.3 );
    print $output;
    SDL_snprintf( $output, 100, "Padding:\t%05.2f %.2f %5.2f\n", 1.5, 1.5, 1.5 );
    print $output;
    SDL_snprintf( $output, 100, "Scientific:\t%E %e\n", 1.5, 1.5 );
    print $output;
    SDL_snprintf( $output, 100, "Hexadecimal:\t%a %A\n", 1.5, 1.5 );
    print $output;
    print "Variable width control:\n";
    SDL_snprintf( $output, 100, "right-justified variable width: '%*c'\n", 5, ord 'x' );
    print $output;
    my $r = SDL_snprintf( $output, 100, "left-justified variable width : '%*c'\n", -5, ord 'x' );
    print $output;
    SDL_snprintf( $output, 100, "(the last printf printed %d characters)\n", $r );
    print $output;

    # fixed-width types
    my $val = 2**32 - 1;
    SDL_snprintf( $output, 100, "Largest 32-bit value is %u or %#x\n", $val, $val );
    print $output;

Expected parameters include:

=over

=item C<buffer> - string to write to

=item C<buf_size> - maximum number of characters which may be written

=item C<format> - string specifying how to interpret the data

=item C<...> - arguments specifying data to print

=back

Returns the number of characters written on success.

=head2 C<SDL_vsnprintf( ... )>

Loads the data from the given locations, converts them to character string
equivalents and writes the results to a string buffer.

Expected parameters include:

=over

=item C<buffer> - string to write to

=item C<buf_size> - maximum number of characters which may be written

=item C<format> - string specifying how to interpret the data

=item C<...> - arguments specifying data to print

=back

Returns the number of characters written on success.

=head2 C<SDL_acos( ... )>

Computes the principal value of the arc cosine of C<arg>.

    printf
        "acos(-1) = %f\nacos(0.0) = %f 2*acos(0.0) = %f\nacos(0.5) = %f 3*acos(0.5) = %f\nacos(1) = %f\n",
        SDL_acos(-1), SDL_acos(0.0), 2 * SDL_acos(0), SDL_acos(0.5), 3 * SDL_acos(0.5),
        SDL_acos(1);

Expected parameters include:

=over

=item C<arg> - value of a floating point or integral type

=back

If no errors occur, the arc cosine of C<arg> in the range C<[0 , π]>, is
returned.

=head2 C<SDL_acosf( ... )>

Computes the principal value of the arc cosine of C<arg>.


Expected parameters include:

=over

=item C<arg> - value of a floating point or integral type

=back

If no errors occur, the arc cosine of C<arg> in the range C<[0 , π]>, is
returned.

=head2 C<SDL_asin( ... )>

Computes the principal values of the arc sine of C<arg>.

    printf "SDL_asin( 1.0) = %+f, 2*SDL_asin( 1.0)=%+f\n", SDL_asin(1),    2 * SDL_asin(1);
    printf "SDL_asin(-0.5) = %+f, 6*SDL_asin(-0.5)=%+f\n", SDL_asin(-0.5), 6 * SDL_asin(-0.5);

    # special values
    printf "SDL_asin(0.0) = %1f, SDL_asin(-0.0)=%f\n", SDL_asin(+0.0), SDL_asin(-0.0);
    printf "SDL_asin(1.1) = %f\n", SDL_asin(1.1);

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the arc sine of C<arg> in the range C<[-π/2,+π/2]>, is
returned.

=head2 C<SDL_asinf( ... )>

Computes the principal values of the arc sine of C<arg>.

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the arc sine of C<arg> in the range C<[-π/2,+π/2]>, is
returned.

=head2 C<SDL_atan( ... )>

Computes the principal value of the arc tangent of C<arg>.

    printf( "SDL_atan(1) = %f, 4*SDL_atan(1)=%f\n", SDL_atan(1), 4 * SDL_atan(1) );

    # special values
    use bigrat;    # inf
    printf( "SDL_atan(Inf) = %f, 2*SDL_atan(Inf) = %f\n",   SDL_atan(inf),  2 * SDL_atan(inf) );
    printf( "SDL_atan(-0.0) = %+f, SDL_atan(+0.0) = %+f\n", SDL_atan(-0.0), SDL_atan(0) );

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the arc tangent of C<arg> in the range C<[-π/2,+π/2]>
radians, is returned.

=head2 C<SDL_atanf( ... )>

Computes the principal value of the arc tangent of C<arg>.

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the arc tangent of C<arg> in the range C<[-π/2 ; +π/2]>
radians, is returned.

=head2 C<SDL_atan2( ... )>

Computes the arc tangent of C<y/x> using the signs of arguments to determine
the correct quadrant.

    use Math::AnyNum qw[hypot];

    # normal usage: the signs of the two arguments determine the quadrant
    # atan2(1,1) = +pi/4, Quad I
    printf( "(+1,+1) cartesian is (%f,%f) polar\n", hypot( 1, 1 ), SDL_atan2( 1, 1 ) );

    # atan2(1, -1) = +3pi/4, Quad II
    printf( "(+1,-1) cartesian is (%f,%f) polar\n", hypot( 1, -1 ), SDL_atan2( 1, -1 ) );

    # atan2(-1,-1) = -3pi/4, Quad III
    printf( "(-1,-1) cartesian is (%f,%f) polar\n", hypot( -1, -1 ), SDL_atan2( -1, -1 ) );

    # atan2(-1,-1) = -pi/4, Quad IV
    printf( "(-1,+1) cartesian is (%f,%f) polar\n", hypot( -1, 1 ), SDL_atan2( -1, 1 ) );

    # special values
    printf( "SDL_atan2(0, 0) = %f SDL_atan2(0, -0)=%f\n", SDL_atan2( 0, 0 ), SDL_atan2( 0, -0.0 ) );
    printf( "SDL_atan2(7, 0) = %f SDL_atan2(7, -0)=%f\n", SDL_atan2( 7, 0 ), SDL_atan2( 7, -0.0 ) );

Expected parameters include:

=over

=item C<x> - floating point value

=item C<y> - floating point value

=back

If no errors occur, the arc tangent of C<y/x> in the range C<[-π ; +π]>
radians, is returned.

=head2 C<SDL_atan2f( ... )>

Computes the arc tangent of C<y/x> using the signs of arguments to determine
the correct quadrant.

Expected parameters include:

=over

=item C<x> - floating point value

=item C<y> - floating point value

=back

If no errors occur, the arc tangent of C<y/x> in the range C<[-π ; +π]>
radians, is returned.

=head2 C<SDL_ceil( ... )>

Computes the smallest integer value not less than C<arg>.

    printf"SDL_ceil(+2.4) = %+.1f\n", SDL_ceil(2.4);
    printf"SDL_ceil(-2.4) = %+.1f\n", SDL_ceil(-2.4);
    printf"SDL_ceil(-0.0) = %+.1f\n", SDL_ceil(-0.0);
	use bigrat; # inf
    printf"SDL_ceil(-Inf) = %+f\n",   SDL_ceil(-inf);

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the smallest integer value not less than C<arg>, that is
C<⌈arg⌉>, is returned.

=head2 C<SDL_ceilf( ... )>

Computes the smallest integer value not less than C<arg>.

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the smallest integer value not less than C<arg>, that is
C<⌈arg⌉>, is returned.

=head2 C<SDL_copysign( ... )>

Composes a floating point value with the magnitude of C<mag> and the sign of
C<sgn>.

    printf "SDL_copysign(1.0,+2.0) = %+f\n", SDL_copysign( 1.0, +2.0 );
    printf "SDL_copysign(1.0,-2.0) = %+f\n", SDL_copysign( 1.0, -2.0 );
    use bigrat;
    printf "SDL_copysign(inf,-2.0) = %+f\n", SDL_copysign( inf, -2.0 );
    printf "SDL_copysign(NaN,-2.0) = %+f\n", SDL_copysign( NaN, -2.0 );

Expected parameters include:

=over

=item C<mag> - floating point value

=item C<sgn> - floating point value

=back

If no errors occur, the floating point value with the magnitude of C<mag> and
the sign of C<sgn> is returned.

If C<mag> is C<NaN>, then C<NaN> with the sign of C<sgn> is returned however
perl cannot properly express C<-NaN>.

If C<sgn> is C<-0>, the result is only negative if the implementation supports
the signed zero consistently in arithmetic operations.

=head2 C<SDL_copysignf( ... )>

Expected parameters include:

=over

=item C<mag> - floating point value

=item C<sgn> - floating point value

=back

If no errors occur, the floating point value with the magnitude of C<mag> and
the sign of C<sgn> is returned.

If C<mag> is C<NaN>, then C<NaN> with the sign of C<sgn> is returned however
perl cannot properly express C<-NaN>.

If C<sgn> is C<-0>, the result is only negative if the implementation supports
the signed zero consistently in arithmetic operations.


=head2 C<SDL_cos( ... )>

Computes the cosine of C<arg> (measured in radians).

    my $pi = M_PI;

    # typical usage
    printf "SDL_cos(pi/3) = %f\n",    SDL_cos( $pi / 3 );
    printf "SDL_cos(pi/2) = %f\n",    SDL_cos( $pi / 2 );
    printf "SDL_cos(-3*pi/4) = %f\n", SDL_cos( -3 * $pi / 4 );

    # special values
    printf "SDL_cos(+0) = %f\n", SDL_cos(0.0);
    printf "SDL_cos(-0) = %f\n", SDL_cos(-0.0);
    use bigrat;
    printf "SDL_cos(INFINITY) = %f\n", SDL_cos(inf);

Expected parameters include:

=over

=item C<arg> - floating point value representing angle in radians

=back

If no errors occur, the cosine of C<arg> in the range C<[-1 ; +1]>, is
returned.

=head2 C<SDL_cosf( ... )>

Computes the cosine of C<arg> (measured in radians).

Expected parameters include:

=over

=item C<arg> - floating point value representing angle in radians

=back

If no errors occur, the cosine of C<arg> in the range C<[-1 ; +1]>, is
returned.

=head2 C<SDL_exp( ... )>

Computes the C<e> (Euler's number, C<2.7182818>) raised to the given power
C<arg>.

    printf "SDL_exp(1) = %f\n", SDL_exp(1);
    printf "FV of \$100, continuously compounded at 3%% for 1 year = %f\n", 100 * SDL_exp(0.03);

    # special values
    printf "SDL_exp(-0) = %f\n",   SDL_exp(-0.0);
    printf "SDL_exp(-Inf) = %f\n", SDL_exp( -inf );

    # overflow
    printf "SDL_exp(710) = %f\n", SDL_exp(710);

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the base-e exponential of C<arg> is returned.

=head2 C<SDL_expf( ... )>

Computes the C<e> (Euler's number, C<2.7182818>) raised to the given power
C<arg>.

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the base-e exponential of C<arg> is returned.

=head2 C<SDL_fabs( ... )>

Computes the absolute value of a floating point value C<arg>.

	printf( "SDL_fabs(+3) = %f\n", SDL_fabs(+3.0) );
    printf( "SDL_fabs(-3) = %f\n", SDL_fabs(-3.0) );

    # special values
    printf( "SDL_fabs(-0) = %f\n",   SDL_fabs(-0.0) );
    printf( "SDL_fabs(-Inf) = %f\n", SDL_fabs( -inf ) );
    printf( "%f\n",                  num_int( 0.0, 2 * M_PI, 100000 ) );

    sub num_int ( $a, $b, $n ) {    # assumes all area is positive
        return 0.0 if $a == $b;
        $n ||= 1;                   # avoid division by zero
        my $h   = ( $b - $a ) / $n;
        my $sum = 0.0;
        for ( my $k = 0; $k < $n; ++$k ) {
            $sum += $h * SDL_fabs( sin( $a + $k * $h ) );
        }
        return $sum;
    }

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If successful, returns the absolute value of C<arg> (C<|arg|>). The value
returned is exact and does not depend on any rounding modes.

=head2 C<SDL_fabsf( ... )>

Computes the absolute value of a floating point value C<arg>.

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If successful, returns the absolute value of C<arg> (C<|arg|>). The value
returned is exact and does not depend on any rounding modes.

=head2 C<SDL_floor( ... )>

Computes the largest integer value not greater than C<arg>.

    printf "SDL_floor(+2.7) = %+.1f\n", SDL_floor(2.7);
    printf "SDL_floor(-2.7) = %+.1f\n", SDL_floor(-2.7);
    printf "SDL_floor(-0.0) = %+.1f\n", SDL_floor(-0.0);
    printf "SDL_floor(-Inf) = %+f\n",   SDL_floor( -INFINITY );

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the largest integer value not greater than C<arg>, that is
C<⌊arg⌋>, is returned.

=head2 C<SDL_floorf( ... )>

Computes the largest integer value not greater than C<arg>.

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the largest integer value not greater than C<arg>, that is
C<⌊arg⌋>, is returned.

=head2 C<SDL_trunc( ... )>

Computes the nearest integer not greater in magnitude than C<arg>.

    printf "SDL_trunc(+2.7) = %+.1f\n", SDL_trunc(2.7);
    printf "SDL_trunc(-2.7) = %+.1f\n", SDL_trunc(-2.7);
    printf "SDL_trunc(-0.0) = %+.1f\n", SDL_trunc(-0.0);
    printf "SDL_trunc(-Inf) = %+f\n",   SDL_trunc( -INFINITY );

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the nearest integer value not greater in magnitude than
C<arg> (in other words, C<arg> rounded towards zero), is returned.

=head2 C<SDL_truncf( ... )>

Computes the nearest integer not greater in magnitude than C<arg>.

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the nearest integer value not greater in magnitude than
C<arg> (in other words, C<arg> rounded towards zero), is returned.

=head2 C<SDL_fmod( ... )>

Computes the floating-point remainder of the division operation C<x/y>.

    printf "SDL_fmod(+5.1, +3.0) = %.1f\n", SDL_fmod( 5.1,  3 );
    printf "SDL_fmod(-5.1, +3.0) = %.1f\n", SDL_fmod( -5.1, 3 );
    printf "SDL_fmod(+5.1, -3.0) = %.1f\n", SDL_fmod( 5.1,  -3 );
    printf "SDL_fmod(-5.1, -3.0) = %.1f\n", SDL_fmod( -5.1, -3 );

    # special values
    printf "SDL_fmod(+0.0, 1.0) = %.1f\n", SDL_fmod( 0,    1 );
    printf "SDL_fmod(-0.0, 1.0) = %.1f\n", SDL_fmod( -0.0, 1 );
    printf "SDL_fmod(+5.1, Inf) = %.1f\n", SDL_fmod( 5.1,  'INFINITY' );

    # error handling
    printf "SDL_fmod(+5.1, 0) = %.1f\n", SDL_fmod( 5.1, 0 );

Expected parameters include:

=over

=item C<x> - floating point value

=item C<y> - floating point value

=back

If successful, returns the floating-point remainder of the division C<x/y> as
defined above.

=head2 C<SDL_fmodf( ... )>

Computes the floating-point remainder of the division operation C<x/y>.

Expected parameters include:

=over

=item C<x> - floating point value

=item C<y> - floating point value

=back

If successful, returns the floating-point remainder of the division C<x/y> as
defined above.

=head2 C<SDL_log( ... )>

Computes the natural (base e) logarithm of C<arg>.

    printf "SDL_log(1) = %f\n",              SDL_log(1);
    printf "base-5 logarithm of 125 = %f\n", SDL_log(125) / SDL_log(5);

    # special values
    printf "SDL_log(1) = %f\n",    SDL_log(1);
    printf "SDL_log(+Inf) = %f\n", SDL_log('INFINITY');

    #error handling
    printf "SDL_log(0) = %f\n", SDL_log(0);

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the natural (base-e) logarithm of C<arg> is returned.

=head2 C<SDL_logf( ... )>

Computes the natural (base e) logarithm of C<arg>.

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the natural (base-e) logarithm of C<arg> is returned.

=head2 C<SDL_log10( ... )>

Computes the common (base-10) logarithm of C<arg>.

    printf "SDL_log10(1000) = %f\n",         SDL_log10(1000);
    printf "log10(0.001) = %f\n",            SDL_log10(0.001);
    printf "base-5 logarithm of 125 = %f\n", SDL_log10(125) / SDL_log10(5);

    # special values
    printf "SDL_log10(1) = %f\n",    SDL_log10(1);
    printf "SDL_log10(+Inf) = %f\n", SDL_log10('INFINITY');

    # error handling
    printf "SDL_log10(0) = %f\n", SDL_log10(0);

Expected parameters include:

=over

=item C<arg> - value of floating point or integral type

=back

If no errors occur, the common (base-10) logarithm of C<arg> is returned.

=head2 C<SDL_log10f( ... )>

Computes the common (base-10) logarithm of C<arg>.

Expected parameters include:

=over

=item C<arg> - value of floating point or integral type

=back

If no errors occur, the common (base-10) logarithm of C<arg> is returned.

=head2 C<SDL_pow( ... )>

Computes the value of C<base> raised to the power C<exponent>.

    # typical usage
    printf "SDL_pow(2, 10) = %f\n",  SDL_pow( 2,  10 );
    printf "SDL_pow(2, 0.5) = %f\n", SDL_pow( 2,  0.5 );
    printf "SDL_pow(-2, -3) = %f\n", SDL_pow( -2, -3 );

    # special values
    printf "SDL_pow(-1, NAN) = %f\n",      SDL_pow( -1,         'NaN' );
    printf "SDL_pow(+1, NAN) = %f\n",      SDL_pow( +1,         'NaN' );
    printf "SDL_pow(INFINITY, 2) = %f\n",  SDL_pow( 'INFINITY', 2 );
    printf "SDL_pow(INFINITY, -1) = %f\n", SDL_pow( 'INFINITY', -1 );

    # error handling
    printf "SDL_pow(-1, 1/3) = %f\n", SDL_pow( -1,   1.0 / 3 );
    printf "SDL_pow(-0, -3) = %f\n",  SDL_pow( -0.0, -3 );

Expected parameters include:

=over

=item C<base> - floating point value

=item C<exponent> - floating point value

=back

If no errors occur, C<base> raised to the power of C<exponent> is returned.

=head2 C<SDL_powf( ... )>

Computes the value of C<base> raised to the power C<exponent>.

Expected parameters include:

=over

=item C<base> - floating point value

=item C<exponent> - floating point value

=back

If no errors occur, C<base> raised to the power of C<exponent> is returned.

=head2 C<SDL_round( ... )>

Computes the nearest integer value to C<arg> (in floating-point format),
rounding halfway cases away from zero, regardless of the current rounding mode.

    printf 'SDL_round(+2.3) = %+.1f  ', SDL_round(2.3);
    printf 'SDL_round(+2.5) = %+.1f  ', SDL_round(2.5);
    printf "SDL_round(+2.7) = %+.1f\n", SDL_round(2.7);
    printf 'SDL_round(-2.3) = %+.1f  ', SDL_round(-2.3);
    printf 'SDL_round(-2.5) = %+.1f  ', SDL_round(-2.5);
    printf "SDL_round(-2.7) = %+.1f\n", SDL_round(-2.7);
    printf "SDL_round(-0.0) = %+.1f\n", SDL_round(-.0);
    printf "SDL_round(-Inf) = %+f\n",   SDL_round('-INFINITY');

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the nearest integer value to C<arg>, rounding halfway cases
away from zero, is returned.

=head2 C<SDL_roundf( ... )>

Computes the nearest integer value to C<arg> (in floating-point format),
rounding halfway cases away from zero, regardless of the current rounding mode.

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the nearest integer value to C<arg>, rounding halfway cases
away from zero, is returned.

=head2 C<SDL_lround( ... )>

Computes the nearest integer value to C<arg> (in integer format), rounding
halfway cases away from zero, regardless of the current rounding mode.

    printf 'SDL_lround(+2.3) = %ld   ', SDL_lround(2.3);
    printf 'SDL_lround(+2.5) = %ld   ', SDL_lround(2.5);
    printf "SDL_lround(+2.7) = %ld\n",  SDL_lround(2.7);
    printf 'SDL_lround(-2.3) = %ld  ',  SDL_lround(-2.3);
    printf 'SDL_lround(-2.5) = %ld  ',  SDL_lround(-2.5);
    printf "SDL_lround(-2.7) = %ld\n",  SDL_lround(-2.7);
    printf "SDL_lround(-0.0) = %ld\n",  SDL_lround(-.0);
    printf "SDL_lround(-Inf) = %ld\n",  SDL_lround('-INFINITY');    # FE_INVALID raised

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the nearest integer value to C<arg>, rounding halfway cases
away from zero, is returned.


=head2 C<SDL_lroundf( ... )>

Computes the nearest integer value to C<arg> (in integer format), rounding
halfway cases away from zero, regardless of the current rounding mode.

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, the nearest integer value to C<arg>, rounding halfway cases
away from zero, is returned.

=head2 C<SDL_scalbn( ... )>

Multiplies a floating point value C<arg> by C<FLT_RADIX> (the radix (integer
base) used by the representation of all three floating-point types) raised to
power C<exp>.

    printf "SDL_scalbn(7, -4) = %f\n", SDL_scalbn( 7, -4 );
    printf "SDL_scalbn(1, -1074) = %g (minimum positive subnormal double)\n",
        SDL_scalbn( 1, -1074 );
    printf "SDL_scalbn(.9999999999999999, 1024) = %g (largest finite double)\n",
        SDL_scalbn( 0.99999999999999989, 1024 );

    # special values
    printf "SDL_scalbn(-0, 10) = %f\n",   SDL_scalbn( -.0,         10 );
    printf "SDL_scalbn(-Inf, -1) = %f\n", SDL_scalbn( '-INFINITY', -1 );

    # error handling
    printf "SDL_scalbn(1, 1024) = %f\n", SDL_scalbn( 1, 1024 );

Expected parameters include:

=over

=item C<arg> - floating point value

=item C<exp> - integer value

=back

If no errors occur, C<arg> multiplied by C<FLT_RADIX> to the power of C<exp> is
returned.

=head2 C<SDL_scalbnf( ... )>

Multiplies a floating point value C<arg> by C<FLT_RADIX> (the radix (integer
base) used by the representation of all three floating-point types) raised to
power C<exp>.

Expected parameters include:

=over

=item C<arg> - floating point value

=item C<exp> - integer value

=back

If no errors occur, C<arg> multiplied by C<FLT_RADIX> to the power of C<exp> is
returned.

=head2 C<SDL_sin( ... )>

Computes the sine of C<arg> (measured in radians).

    my $pi = SDL_acos(-1);

    # typical usage
    printf "SDL_sin(pi/6) = %f\n",    SDL_sin( $pi / 6 );
    printf "SDL_sin(pi/2) = %f\n",    SDL_sin( $pi / 2 );
    printf "SDL_sin(-3*pi/4) = %f\n", SDL_sin( -3 * $pi / 4 );

    # special values
    printf "SDL_sin(+0) = %f\n",       SDL_sin(0);
    printf "SDL_sin(-0) = %f\n",       SDL_sin(-.0);
    printf "SDL_sin(INFINITY) = %f\n", SDL_sin('INFINITY');

Expected parameters include:

=over

=item C<arg> - floating point value representing an angle in radians

=back

If no errors occur, the sine of C<arg> in the range [-1 ; +1], is returned.

=head2 C<SDL_sinf( ... )>

Computes the sine of C<arg> (measured in radians).

Expected parameters include:

=over

=item C<arg> - floating point value representing an angle in radians

=back

If no errors occur, the sine of C<arg> in the range [-1 ; +1], is returned.

=head2 C<SDL_sqrt( ... )>

Computes square root of C<arg>.

    # normal use
    printf "SDL_sqrt(100) = %f\n", SDL_sqrt(100);
    printf "SDL_sqrt(2) = %f\n",   SDL_sqrt(2);
    printf "golden ratio = %f\n", ( 1 + SDL_sqrt(5) ) / 2;

    # special values
    printf "SDL_sqrt(-0) = %f\n", SDL_sqrt(-0.0);

    # error handling
    printf "SDL_sqrt(-1.0) = %f\n", SDL_sqrt(-1);

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, square root of Carg> (C<√arg>), is returned.

=head2 C<SDL_sqrtf( ... )>

Computes square root of C<arg>.

Expected parameters include:

=over

=item C<arg> - floating point value

=back

If no errors occur, square root of Carg> (C<√arg>), is returned.

=head2 C<SDL_tan( ... )>

Computes the tangent of C<arg> (measured in radians).

    my $pi = SDL_acos(-1);

    # typical usage
    printf "SDL_tan  (pi/4) = %+f\n", SDL_tan( $pi / 4 );        #   45 deg
    printf "SDL_tan(3*pi/4) = %+f\n", SDL_tan( 3 * $pi / 4 );    #  135 deg
    printf "SDL_tan(5*pi/4) = %+f\n", SDL_tan( 5 * $pi / 4 );    # -135 deg
    printf "SDL_tan(7*pi/4) = %+f\n", SDL_tan( 7 * $pi / 4 );    #  -45 deg

    # special values
    printf "SDL_tan(+0) = %+f\n", SDL_tan(0.0);
    printf "SDL_tan(-0) = %+f\n", SDL_tan(-0.0);

    # error handling
    printf "SDL_tan(INFINITY) = %f\n", SDL_tan('INFINITY');

Expected parameters include:

=over

=item C<arg> - floating point value representing angle in radians

=back

If no errors occur, the tangent of C<arg> is returned.

=head2 C<SDL_tanf( ... )>

Computes the tangent of C<arg> (measured in radians).

Expected parameters include:

=over

=item C<arg> - floating point value representing angle in radians

=back

If no errors occur, the tangent of C<arg> is returned.

=head2 C<SDL_iconv_open( ... )>

Allocate descriptor for character set conversion.

Expected parameters include:

=over

=item C<tocode> - name of the destination encoding

=item C<fromcode> - name of the source encoding

=back

The values permitted for fromcode and tocode and the supported combinations are
system-dependent. For the GNU C library, the permitted values are listed by the
C<`iconv --list`> command, and all combinations of the listed values are
supported.

Returns a new L<SDL2::iconv_t> object.

=head2 C<SDL_iconv_close( ... )>

Deallocate descriptor for character set conversion.

Expected parameters include:

=over

=item C<cd> - L<SDL2::iconv_t> object

=back

Returns C<0> on success; otherwise returns C<-1>.

=head2 C<SDL_iconv( ... )>

Converts a stream of data between encodings.

Expected parameters include:

=over

=item C<cd> - L<SDL2::iconv_t> object

=item C<inbuf> - pointer to a buffer

=item C<inbytesleft> - pointer to an integer

=item C<outbuf> - pointer to a buffer

=item C<outbytesleft> - pointer to an integer

=back

Returns an L<< C<iconv( )> error code|/C<iconv( )> error codes >>.

=head2 C<SDL_iconv_string( ... )>

Converts a string between encodings in one pass.

Expected parameters include:

=over

=item C<tocode> - encoding of the outcome of this conversion

=item C<fromcode> - encoding of the encoding text

=item C<inbuf> - input buffer

=item C<inbytesleft> - number of characters left to encode

=back


Returns a string that must be freed with C<SDL_free( ... )> on success; undef
on error.

=head2 C<SDL_iconv_utf8_locale( ... )>

Converts string from UTF-8 to the local encoding.

Expected parameters include:

=over

=item C<string> - UTF-8 encoded string

=back

Returns the re-encoded string.

=head1 Defined values and Enumerations

These might actually be useful and may be imported with the listed tags.

=head2 C<SDL_bool>

Basic boolean values for added sugar. Imported with the C<:bool> tag.

=over

=item C<SDL_TRUE> - not false

=item C<SDL_FALSE> - not true

=back

=head2 C<M_PI>

Pi in a pinch.

=head2 Memory allocation callbacks

Not sure why you'd ever want to do this, but you may override SDL's internal
memory handling with these closure types.

=head3 C<SDL_malloc_func>

Parameters to expect:

=over

=item C<size> - C<size_t> type

=back

You must return a pointer to allocated memory.

=head3 C<SDL_calloc_func>

Parameters to expect:

=over

=item C<nmemb> - number of members in the array

=item C<size> - C<size_t> type indicating the size of the members

=back

You must return a pointer to allocated memory.

=head3 C<SDL_realloc_func>

Parameters to expect:

=over

=item C<mem> - an opaque pointer to allocated memory

=item C<size> - C<size_t> type indicating how much memory to allocate

=back

You must return a pointer to allocated memory.

=head3 C<SDL_free_func>

Parameters to expect:

=over

=item C<mem> - opaque pointer to allocated memory which will be freed

=back

=head2 C<iconv( )> error codes

The SDL implementation of C<iconv( )> returns these error codes:

=over

=item C<SDL_ICONV_ERROR>

=item C<SDL_ICONV_E2BIG>

=item C<SDL_ICONV_EILSEQ>

=item C<SDL_ICONV_EINVAL>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

whitespace abcdefghijklmnopqrstuvwxyz (0123456789abcdefABCDEF) checksum isupper
significand islower lhs rhs dest tokenize ext fromcode tocode src

=end stopwords

=cut

};
1;
