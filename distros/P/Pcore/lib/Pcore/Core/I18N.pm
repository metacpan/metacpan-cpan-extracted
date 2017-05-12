package Pcore::Core::I18N;

use Pcore -export => {
    CORE    => [qw[i18n_locale]],
    DEFAULT => [qw[i18n]],
};
use Pcore::Util::Text qw[decode_utf8];

our $LOCALE    = 'en_US';
our $LOCATIONS = [];
our $CACHE     = {};

if ( my $i18n_res = $ENV->share->get_storage('i18n') ) {
    for my $path ( $i18n_res->@* ) {
        _add_location($path);
    }
}

sub i18n {
    my $source;
    if ( ref $_[0] eq 'ARRAY' ) {
        @{$source} = @{ $_[0] };
        if ( defined $_[1] && scalar @{$source} == 2 ) {
            $source->[2] = $_[1];
        }
    }
    else {
        $source = \@_;
    }

    if ( scalar @{$source} == 3 ) {
        return sprintf _t( $source->[0], $source->[1], $source->[2] ), $source->[2];
    }
    else {
        return _t( $source->[0] );
    }
}

sub i18n_locale {
    my $self = shift;
    my $locale = shift || undef;

    $LOCALE = $locale if $locale;
    return $LOCALE;
}

sub _add_location {
    my $location = shift;

    if ( $location && -d $location ) {
        $location = P->path( $location, is_dir => 1 )->realpath;

        unless ( $location ~~ $LOCATIONS->@* ) {
            unshift $LOCATIONS->@*, $location;

            $CACHE = {};
        }
    }

    return;
}

sub _load_domains {
    if ( exists $CACHE->{$LOCALE} ) {
        return $CACHE->{$LOCALE};
    }
    else {
        $CACHE->{$LOCALE} = [];
        for my $location ( @{$LOCATIONS} ) {
            if ( -e $location . q[/] . $LOCALE . '.mo' ) {    ## no critic (ValuesAndExpressions::ProhibitMismatchedOperators)
                my $catalog = _load_catalog($location);
                push @{ $CACHE->{$LOCALE} }, $catalog;
            }
        }
    }
    return $CACHE->{$LOCALE};
}

# TODO
# need optimization
# old source - http://cpansearch.perl.org/src/JV/EekBoek-2.02.02/lib/EB/CPAN/Locale/gettext_pp.pm
# possible new sources:
# https://metacpan.org/module/File::Gettext
sub _load_catalog {
    my $location = shift;

    my $filename = "$location/$LOCALE.mo";
    return unless -f $filename && -r $filename;

    my $raw = P->file->read_bin($filename)->$*;

    # Corrupted?
    return if !defined $raw || length $raw < 28;

    my $filesize = length $raw;

    # Read the magic number in order to determine the byte order.
    my $domain = {};
    my $unpack = 'N';
    $domain->{potter} = unpack $unpack, substr $raw, 0, 4;

    if ( $domain->{potter} == 0xde120495 ) {
        $unpack = 'V';
    }
    elsif ( $domain->{potter} != 0x950412de ) {
        return;
    }
    my $domain_unpack = $unpack x 6;

    my ( $revision, $num_strings, $msgids_off, $msgstrs_off, $hash_size, $hash_off ) = unpack $unpack x 6, substr( $raw, 4, 24 );

    return unless $revision == 0;    # Invalid revision number.

    $domain->{revision}    = $revision;
    $domain->{num_strings} = $num_strings;
    $domain->{msgids_off}  = $msgids_off;
    $domain->{msgstrs_off} = $msgstrs_off;
    $domain->{hash_size}   = $hash_size;
    $domain->{hash_off}    = $hash_off;

    return if $msgids_off + 4 * $num_strings > $filesize;
    return if $msgstrs_off + 4 * $num_strings > $filesize;

    my @orig_tab  = unpack( ( $unpack x ( 2 * $num_strings ) ), substr $raw, $msgids_off,  8 * $num_strings );
    my @trans_tab = unpack( ( $unpack x ( 2 * $num_strings ) ), substr $raw, $msgstrs_off, 8 * $num_strings );

    my $messages = {};

    for ( my $count = 0; $count < 2 * $num_strings; $count += 2 ) {
        my $orig_length  = $orig_tab[$count];
        my $orig_offset  = $orig_tab[ $count + 1 ];
        my $trans_length = $trans_tab[$count];
        my $trans_offset = $trans_tab[ $count + 1 ];

        return if $orig_offset + $orig_length > $filesize;
        return if $trans_offset + $trans_length > $filesize;

        my @origs = split /\000/sm, substr $raw, $orig_offset,  $orig_length;
        my @trans = split /\000/sm, substr $raw, $trans_offset, $trans_length;

        # The singular is the key, the plural plus all translations is the value.
        my $msgid = $origs[0];
        $msgid = q[] unless defined $msgid && length $msgid;
        my $msgstr = [ $origs[1], @trans ];
        $messages->{$msgid} = $msgstr;
    }

    $domain->{messages} = $messages;

    # Try to find po header information.
    my $po_header  = {};
    my $null_entry = $messages->{q[]}->[1];
    if ($null_entry) {
        my @lines = split /\n/sm, $null_entry;
        foreach my $line (@lines) {
            my ( $key, $value ) = split /:/sm, $line, 2;
            $key =~ s/-/_/smg;
            $po_header->{ lc $key } = $value;
        }
    }
    $domain->{po_header} = $po_header;

    if ( exists $domain->{po_header}->{content_type} ) {
        my $content_type = $domain->{po_header}->{content_type};
        if ( $content_type =~ s/.*=//sm ) {
            $domain->{po_header}->{charset} = $content_type;
        }
    }

    my $code = $domain->{po_header}->{plural_forms} || q[];

    # Whitespace, locale-independent.
    my $s = '[ \t\r\n\013\014]';

    # Untaint the plural header.
    # Keep line breaks as is (Perl 5_005 compatibility).
    if ( $code =~ m[^($s*nplurals$s*=$s*[\d]+$s*;$s*plural$s*=$s*(?:$s|[-\?\|\&=!<>+*/\%:;[:alpha:]\d_\(\)])+)]smx ) {    ## no critic qw[RegularExpressions::ProhibitEscapedMetacharacters]
        $domain->{po_header}->{plural_forms} = $1;
    }
    else {
        $domain->{po_header}->{plural_forms} = q[];
    }

    # Determine plural rules.
    # The leading and trailing space is necessary to be able to match
    # against word boundaries.
    my $plural_func;

    if ( $domain->{po_header}->{plural_forms} ) {
        my $plural_code = q[ ] . $domain->{po_header}->{plural_forms} . q[ ];
        $plural_code =~ s/([^_[:alpha:]\d]|\A)([_[:lower:]][_[:alpha:]\d]*)([^_[:alpha:]\d])/$1\$$2$3/g;    ## no critic qw[RegularExpressions::RequireDotMatchAnything RegularExpressions::RequireLineBoundaryMatching]

        $plural_code = "sub { my \$n = shift; my (\$plural, \$nplurals); $plural_code; return (\$nplurals, \$plural ? \$plural : 0); }";

        # Now try to evaluate the code.     There is no need to run the code in
        # a Safe compartment.  The above substitutions should have destroyed
        # all evil code.  Corrections are welcome!
        $plural_func = eval $plural_code;    ## no critic (BuiltinFunctions::ProhibitStringyEval)
        undef $plural_func if $@;
    }

    # Default is English
    unless ($plural_func) {
        $plural_func = sub { ( 2, 1 != shift || 0 ) };
    }

    $domain->{plural_func} = $plural_func;

    return $domain;
}

sub _t {
    my ( $msgid, $plural, $n ) = @_;

    return unless defined $msgid;

    my $domains = _load_domains;

    my @trans = ();
    my $domain;
    my $found;
    foreach my $this_domain ( @{$domains} ) {
        if ( $this_domain && defined $this_domain->{messages}->{$msgid} ) {
            @trans = @{ $this_domain->{messages}->{$msgid} };
            shift @trans;
            $domain = $this_domain;
            $found  = 1;
            last;
        }
    }
    @trans = ( $msgid, $plural ) unless @trans;

    my $trans = $trans[0];
    if ($plural) {
        if ($domain) {
            my $nplurals = 0;
            ( $nplurals, $plural ) = $domain->{plural_func}->($n);
            $plural   = 0 unless defined $plural;
            $nplurals = 0 unless defined $nplurals;
            $plural = 0 if $nplurals <= $plural;
        }
        else {
            $plural = $n != 1 || 0;
        }

        $trans = $trans[$plural] if defined $trans[$plural];
    }

    decode_utf8 $trans;

    return $trans;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 84                   | Subroutines::ProhibitExcessComplexity - Subroutine "_load_catalog" with high complexity score (26)             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 177, 191             | RegularExpressions::ProhibitComplexRegexes - Split long regexps into smaller qr// chunks                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 102, 105             | ValuesAndExpressions::RequireNumberSeparators - Long number not separated with underscores                     |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 129                  | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 110, 124, 125        | CodeLayout::ProhibitParensWithBuiltins - Builtin function called with parentheses                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 173                  | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::I18N - P internationalization subsystem.

=head1 SYNOPSIS

    GO->I18N->add_location($ENV->{I18N_DIR});
    GO->I18N->locale('ru_RU');

=head1 Config strings internationalization

Интернационализация в inline конфиге (конфиге в блоке BEGIN скрипта) не поддерживается.

Для интернационализации строк в остальных конфигах использовать вызов i18n с одним или двумя параметрами:

    {
        string        => i18n('text'),
        plural_string => i18n('text', 'plural form')
    }

Для ресолвинга интернациональных строк в конфиге использовать вызов:

    i18n($ENV->{string});
    i18n($ENV->{plural_string}, $plural_value); $plural_value - числовое значение множественной формы


=head1 Template toolkit templates internationalization

Поддерживаемые форматы нитернационализации для использования в шаблонах:

    [% i18n('text') %]
    [% i18n('text', 'plural form', $plural_value) %]

=head1 Performance

Locale::gettext_xs:      timethis 1000000: 10 wallclock secs ( 9,68 usr +  0,03 sys =  9,71 CPU) @ 102986,61/s (n=1000000)

Pcore::Core::GO::I18N: timethis 1000000: 10 wallclock secs ( 9,40 usr +  0,01 sys =  9,41 CPU) @ 106269,93/s (n=1000000)

По результатам тестов видно, что производительность сохраняется на уровне XS кода.

=cut
