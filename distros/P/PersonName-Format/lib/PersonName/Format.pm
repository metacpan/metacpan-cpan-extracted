##----------------------------------------------------------------------------
## Person Name Format - ~/lib/PersonName/Format.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/07/16
## Modified 2026/07/17
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package PersonName::Format;
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( PersonName::Format::Generic );
    use vars qw( $VERSION );
    use Locale::Unicode;
    use PersonName::Format::Compiled;
    use PersonName::Format::FieldModifier;
    use PersonName::Format::Name;
    use PersonName::Format::Pattern;
    use PersonName::Format::PP ();
    use PersonName::Format::SimpleName;
    use Scalar::Util ();
    our( $VERSION ) = 'v0.1.0';
    our( $IsPurePerl );

    unless( defined( $IsPurePerl ) )
    {
        if( $ENV{PERSONNAME_FORMAT_PUREPERL} )
        {
            $IsPurePerl = 1;
        }
        else
        {
            $IsPurePerl = eval
            {
                require XSLoader;
                XSLoader::load( __PACKAGE__, $VERSION );
                0;
            };
            $IsPurePerl = 1 if( $@ );
        }
    }

    if( $IsPurePerl )
    {
        no warnings 'redefine';
        *_first_grapheme = \&PersonName::Format::PP::_first_grapheme;
        *_get_name_script = \&PersonName::Format::PP::_get_name_script;
    }
};

use strict;
use warnings;

my $OPTION_ALIASES =
{
    length           => 'length',
    usage            => 'usage',
    formality        => 'formality',
    display_order    => 'display_order',
    displayOrder     => 'display_order',
    surname_all_caps => 'surname_all_caps',
    surnameAllCaps   => 'surname_all_caps',
    data             => 'data',
    debug            => 'debug',
    fatal            => 'fatal',
};

my $SCRIPT_SETS =
{
    Hanb => { Hani => 1, Bopo => 1 },
    Hans => { Hani => 1 },
    Hant => { Hani => 1 },
    Hrkt => { Hira => 1, Kana => 1 },
    Jpan => { Hani => 1, Hira => 1, Kana => 1 },
    Kore => { Hang => 1, Hani => 1 },
};

sub init
{
    my $self   = shift( @_ );
    my $locale = shift( @_ );
    if( !defined( $locale ) ||
        !CORE::length( "$locale" ) )
    {
        return( $self->error( "No formatting locale was provided." ) );
    }
    my $args = $self->_get_args_as_hash( @_ );
    $args = {%$args};
    my $opts = {};

    foreach my $key ( keys( %$args ) )
    {
        unless( exists( $OPTION_ALIASES->{ $key } ) )
        {
            return( $self->error( "Unknown PersonName::Format option '${key}'." ) );
        }
        my $normalised = $OPTION_ALIASES->{ $key };
        if( exists( $opts->{ $normalised } ) )
        {
            return( $self->error( "Option '${normalised}' was provided more than once using aliases." ) );
        }
        $opts->{ $normalised } = $args->{ $key };
    }

    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init(
        debug => delete( $opts->{debug} ),
        fatal => delete( $opts->{fatal} )
    ) || return( $self->pass_error );

    my $formatting_locale = Locale::Unicode->new( $locale ) ||
        return( $self->pass_error( Locale::Unicode->error ) );
    $self->{locale} = $formatting_locale;

    my $data = delete( $opts->{data} );
    if( defined( $data ) )
    {
        unless( Scalar::Util::blessed( $data ) )
        {
            return( $self->error( "The data option must be an object." ) );
        }
    }
    else
    {
        local $@;
        eval{ require Locale::Unicode::Data; };
        return( $self->error( "Unable to load Locale::Unicode::Data: ", ( $@ || 'unknown error' ) ) ) if( $@ );
        $data = Locale::Unicode::Data->new ||
            return( $self->pass_error( Locale::Unicode::Data->error ) );
    }
    $self->{data} = $data;

    my $length = delete( $opts->{length} );
    if( defined( $length ) )
    {
        unless( $length eq 'long' ||
                $length eq 'medium' ||
                $length eq 'short' )
        {
            return( $self->error( "Invalid length '${length}'. Expected 'long', 'medium', or 'short'." ) );
        }
    }
    else
    {
        $length = $self->_locale_info_value(
            $self->{locale},
            'person_name_default_length'
        );
        if( !defined( $length ) && $self->error )
        {
            return( $self->pass_error );
        }
        elsif( !defined( $length ) )
        {
            $length = 'medium';
        }
    }

    my $formality = delete( $opts->{formality} );
    if( defined( $formality ) )
    {
        unless( $formality eq 'formal' ||
                $formality eq 'informal' )
        {
            return( $self->error( "Invalid formality '${formality}'. Expected 'formal' or 'informal'." ) );
        }
    }
    else
    {
        $formality = $self->_locale_info_value(
            $self->{locale},
            'person_name_default_formality'
        );
        if( !defined( $formality ) && $self->error )
        {
            return( $self->pass_error );
        }
        elsif( !defined( $formality ) )
        {
            $formality = 'formal';
        }
    }

    my $usage = delete( $opts->{usage} );
    if( !defined( $usage ) )
    {
        $usage = 'referring';
    }
    unless( $usage eq 'referring' ||
            $usage eq 'addressing' ||
            $usage eq 'monogram' )
    {
        return( $self->error( "Invalid usage '${usage}'. Expected 'referring', 'addressing', or 'monogram'." ) );
    }

    my $display_order = delete( $opts->{display_order} );
    if( !defined( $display_order ) )
    {
        $display_order = 'default';
    }
    unless( $display_order eq 'default' ||
            $display_order eq 'givenFirst' ||
            $display_order eq 'surnameFirst' ||
            $display_order eq 'sorting' )
    {
        return( $self->error( "Invalid display order '${display_order}'. Expected 'default', 'givenFirst', 'surnameFirst', or 'sorting'." ) );
    }

    my $surname_all_caps = delete( $opts->{surname_all_caps} );
    if( !defined( $surname_all_caps ) )
    {
        $surname_all_caps = 0;
    }
    if( ref( $surname_all_caps ) ||
        "$surname_all_caps" !~ /^(?:0|1)$/ )
    {
        return( $self->error( "surname_all_caps must be either 0 or 1." ) );
    }

    $self->{length}           = $length;
    $self->{usage}            = $usage;
    $self->{formality}        = $formality;
    $self->{display_order}    = $display_order;
    $self->{surname_all_caps} = $surname_all_caps ? 1 : 0;
    return( $self );
}

sub compile
{
    my $self = shift( @_ );
    my $args = $self->_get_args_as_hash( @_ );
    $args    = {%$args};
    my $name_locale = delete( $args->{name_locale} );
    if( !defined( $name_locale ) &&
        exists( $args->{nameLocale} ) )
    {
        $name_locale = delete( $args->{nameLocale} );
    }
    my $name_script = delete( $args->{name_script} );
    if( !defined( $name_script ) &&
        exists( $args->{nameScript} ) )
    {
        $name_script = delete( $args->{nameScript} );
    }
    my $preferred_order = delete( $args->{preferred_order} );
    if( !defined( $preferred_order ) &&
        exists( $args->{preferredOrder} ) )
    {
        $preferred_order = delete( $args->{preferredOrder} );
    }

    # Validate nameScript first: it is the single required argument.
    if( !defined( $name_script ) || $name_script !~ /^[A-Z][a-z]{3}$/ )
    {
        return( $self->error( "compile() requires a valid nameScript (four-letter ISO 15924 code such as 'Latn')." ) );
    }
    if( defined( $preferred_order ) &&
        $preferred_order ne 'givenFirst' &&
        $preferred_order ne 'surnameFirst' )
    {
        return( $self->error( "Invalid preferredOrder '$preferred_order'. Expected 'givenFirst' or 'surnameFirst'." ) );
    }
    if( scalar( keys( %$args ) ) )
    {
        return( $self->error( "Unknown compile option '", ( keys( %$args ) )[0], "'." ) );
    }

    my $identity = PersonName::Format::Compiled::IdentityName->new(
        name_locale     => $name_locale,
        preferred_order => $preferred_order
    ) || return( $self->pass_error( PersonName::Format::Compiled::IdentityName->error ) );
    my $context = $self->_name_context(
        $identity,
        {
            name_script             => $name_script,
            name_locale             => $name_locale,
            defer_pattern_selection => 1,
        },
    ) || return( $self->pass_error );

    return( PersonName::Format::Compiled->new(
        formatter       => $self,
        context         => $context,
        name_script     => $name_script,
        name_locale     => $name_locale,
        preferred_order => $preferred_order
    ) || $self->pass_error( PersonName::Format::Compiled->error ) );
}

sub data { return( shift->{data} ); }

sub display_order { return( shift->{display_order} ); }

sub displayOrder { return( shift->display_order( @_ ) ); }

sub formality { return( shift->{formality} ); }

sub format
{
    my $self    = shift( @_ );
    my $name    = $self->_coerce_name( @_ ) || return( $self->pass_error );
    my $context = $self->_name_context( $name ) || return( $self->pass_error );
    return( $self->_render_context( $context, $name, 0 ) );
}

sub format_to_parts
{
    my $self    = shift( @_ );
    my $name    = $self->_coerce_name( @_ ) || return( $self->pass_error );
    my $context = $self->_name_context( $name ) || return( $self->pass_error );
    return( $self->_render_context( $context, $name, 1 ) );
}

sub formatToParts { return( shift->format_to_parts( @_ ) ); }

sub length { return( shift->{length} ); }

sub locale { return( shift->{locale} ); }

sub resolved_options
{
    my $self = shift( @_ );
    return({
        locale         => "$self->{locale}",
        length         => $self->{length},
        usage          => $self->{usage},
        formality      => $self->{formality},
        displayOrder   => $self->{display_order},
        surnameAllCaps => $self->{surname_all_caps},
    });
}

sub resolvedOptions { return( shift->resolved_options( @_ ) ); }

sub surname_all_caps { return( shift->{surname_all_caps} ); }

sub surnameAllCaps { return( shift->surname_all_caps( @_ ) ); }

sub usage { return( shift->{usage} ); }

sub _coerce_name
{
    my $self = shift( @_ );

    if( @_ == 1 )
    {
        my $value = $_[0];
        if( Scalar::Util::blessed( $value ) )
        {
            if( PersonName::Format::Name->implements_name_contract( $value ) )
            {
                return( $value );
            }
            return( $self->error( "Object of class '", ref( $value ), "' does not implement the person-name contract." ) );
        }
        elsif( ref( $value ) eq 'HASH' )
        {
            return( PersonName::Format::SimpleName->new( $value ) ||
                $self->pass_error( PersonName::Format::SimpleName->error ) );
        }
    }

    my $args = $self->_get_args_as_hash( @_ );
    return( PersonName::Format::SimpleName->new( $args ) ||
        $self->pass_error( PersonName::Format::SimpleName->error ) );
}

sub _derive_name_order
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    my $name_ordering_locale = shift( @_ );
    my $formatting_locale = shift( @_ );

    if( $self->{display_order} eq 'sorting' )
    {
        return( 'sorting' );
    }
    elsif( $self->{display_order} eq 'givenFirst' ||
           $self->{display_order} eq 'surnameFirst' )
    {
        return( $self->{display_order} );
    }

    my $preferred = $name->preferred_order;
    if( defined( $preferred ) &&
        ( $preferred eq 'givenFirst' ||
          $preferred eq 'surnameFirst' ) )
    {
        return( $preferred );
    }

    my $order = $self->{data}->person_name_derive_order(
        formatting_locale => $formatting_locale,
        name_locale       => $name_ordering_locale,
    );
    if( !defined( $order ) )
    {
        return( $self->pass_error( $self->{data}->error ) );
    }
    return( $order );
}

sub _detected_script
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    my $surname = $name->get_field_value( 'surname', {} );
    my $given = $name->get_field_value( 'given', {} );
    return( _get_name_script( $surname, $given ) );
}

sub _field_modifier
{
    my $self = shift( @_ );
    my $locale = shift( @_ );
    my $key = lc( "$locale" );
    $self->{field_modifiers} ||= {};
    if( exists( $self->{field_modifiers}->{ $key } ) )
    {
        return( $self->{field_modifiers}->{ $key } );
    }

    my $modifier = PersonName::Format::FieldModifier->new( $locale,
        data => $self->{data},
    ) || return( $self->pass_error( PersonName::Format::FieldModifier->error ) );
    $self->{field_modifiers}->{ $key } = $modifier;
    return( $modifier );
}

sub _find_pattern_group
{
    my $self = shift( @_ );
    my $order = shift( @_ );
    my $formatting_locale = shift( @_ );
    my $tree = $self->{data}->make_inheritance_tree( $formatting_locale ) ||
        return( $self->pass_error( $self->{data}->error ) );

    foreach my $locale ( @$tree )
    {
        my $rows = $self->{data}->person_name_formats(
            locale => $locale,
        );
        if( !defined( $rows ) )
        {
            if( $self->{data}->error )
            {
                return( $self->pass_error( $self->{data}->error ) );
            }
            next;
        }
        unless( ref( $rows ) eq 'ARRAY' && @$rows )
        {
            next;
        }

        my $groups  = {};
        my $indexes = [];
        foreach my $row ( @$rows )
        {
            my $index = $row->{name_index};
            if( !exists( $groups->{ $index } ) )
            {
                $groups->{ $index } = [];
                push( @$indexes, $index );
            }
            push( @{$groups->{ $index }}, $row );
        }

        foreach my $index ( @$indexes )
        {
            my $group = $groups->{ $index };
            my $rule  = $group->[0];
            if( ( defined( $rule->{name_order} ) && $rule->{name_order} ne $order ) ||
                ( defined( $rule->{name_length} ) && $rule->{name_length} ne $self->{length} ) ||
                ( defined( $rule->{name_usage} ) && $rule->{name_usage} ne $self->{usage} ) ||
                ( defined( $rule->{name_formality} ) && $rule->{name_formality} ne $self->{formality} ) )
            {
                next;
            }
            return({
                locale   => $locale,
                index    => $index,
                patterns => [map{ $_->{name_pattern} } @$group],
                rows     => $group,
            });
        }
    }

    return( $self->error( "Unable to find a person-name pattern for locale '", $formatting_locale, "' with order '${order}', length '$self->{length}', usage '$self->{usage}', and formality '$self->{formality}'." ) );
}

sub _formatting_locale_has_name_data
{
    my $self   = shift( @_ );
    my $locale = shift( @_ );
    my $tree = $self->{data}->make_inheritance_tree( $locale ) ||
        return( $self->pass_error( $self->{data}->error ) );

    foreach my $candidate ( @$tree )
    {
        last if( lc( $candidate ) eq 'und' );
        my $rows = $self->{data}->person_name_order_locales(
            locale => $candidate,
        );
        if( !defined( $rows ) )
        {
            if( $self->{data}->error )
            {
                return( $self->pass_error( $self->{data}->error ) );
            }
            next;
        }
        if( ref( $rows ) eq 'ARRAY' && @$rows )
        {
            return(1);
        }
    }

    return(0);
}

sub _locale_info_value
{
    my $self     = shift( @_ );
    my $locale   = shift( @_ );
    my $property = shift( @_ );
    my $tree     = $self->{data}->make_inheritance_tree( $locale ) ||
        return( $self->pass_error( $self->{data}->error ) );

    foreach my $candidate ( @$tree )
    {
        my $ref = $self->{data}->locales_info(
            locale   => $candidate,
            property => $property,
        );
        if( !defined( $ref ) )
        {
            if( $self->{data}->error )
            {
                return( $self->pass_error( $self->{data}->error ) );
            }
            next;
        }
        if( exists( $ref->{value} ) &&
            defined( $ref->{value} ) )
        {
            return( $ref->{value} );
        }
    }
    return;
}

sub _locale_with_script
{
    my $self = shift( @_ );
    my $locale = shift( @_ );
    my $script = shift( @_ );
    return( $locale->clone ) if( $script eq 'Zzzz' );

    my $clone = $locale->clone;
    my $full = $self->_maximal_likely_locale( $clone ) ||
        return( $self->pass_error );
    my $default_script = $full->script;

    if( defined( $default_script ) &&
        $self->_scripts_match( $script, $default_script ) )
    {
        $script = $default_script;
    }
    $clone->script( $script );
    return( $clone );
}

sub _maximal_likely_locale
{
    my $self   = shift( @_ );
    my $value  = shift( @_ );
    my $locale = Locale::Unicode->new( $value ) ||
        return( $self->pass_error( Locale::Unicode->error ) );
    my $language  = $locale->language_id;
    my $script    = $locale->script;
    my $territory = $locale->territory;
    my @candidates;

    push( @candidates, "$locale" );
    if( defined( $language ) && defined( $script ) )
    {
        push( @candidates, join( '-', grep{ defined( $_ ) && CORE::length( $_ ) } ( $language, $script ) ) );
    }
    if( defined( $language ) && defined( $territory ) )
    {
        push( @candidates, join( '-', grep{ defined( $_ ) && CORE::length( $_ ) } ( $language, $territory ) ) );
    }
    if( defined( $language ) )
    {
        push( @candidates, $language );
    }
    if( defined( $script ) )
    {
        push( @candidates, "und-${script}" );
    }
    if( defined( $territory ) )
    {
        push( @candidates, "und-${territory}" );
    }
    push( @candidates, 'und' );

    my $seen = {};
    foreach my $candidate ( @candidates )
    {
        if( !defined( $candidate ) ||
            !CORE::length( $candidate ) ||
            $seen->{ lc( $candidate ) }++ )
        {
            next;
        }
        my $ref = $self->{data}->likely_subtag(
            locale => $candidate,
        );
        if( !defined( $ref ) )
        {
            if( $self->{data}->error )
            {
                return( $self->pass_error( $self->{data}->error ) );
            }
            next;
        }
        unless( defined( $ref->{target} ) &&
                CORE::length( $ref->{target} ) )
        {
            next;
        }

        my $target = Locale::Unicode->new( $ref->{target} ) ||
            return( $self->pass_error( Locale::Unicode->error ) );
        if( defined( $language ) && lc( $language ) ne 'und' )
        {
            $target->language_id( $language );
        }
        if( defined( $script ) )
        {
            $target->script( $script );
        }
        if( defined( $territory ) )
        {
            $target->territory( $territory );
        }
        return( $target );
    }

    return( $self->error( "Unable to derive a maximal likely locale for '${locale}'." ) );
}

sub _name_context
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    my $opts = @_ && ref( $_[0] ) eq 'HASH' ? shift( @_ ) : {};
    my $name_script = defined( $opts->{name_script} )
        ? $opts->{name_script}
        : $self->_detected_script( $name );
    my $provided_name_locale = exists( $opts->{name_locale} )
        ? $opts->{name_locale}
        : $name->name_locale;
    my $provided_locale;

    if( defined( $provided_name_locale ) &&
        CORE::length( "$provided_name_locale" ) )
    {
        $provided_locale = Locale::Unicode->new( $provided_name_locale ) ||
            return( $self->pass_error( Locale::Unicode->error ) );
    }

    my $name_base_language;
    my $name_locale;
    my $name_ordering_locale;

    if( defined( $provided_locale ) )
    {
        $name_base_language = $provided_locale->language_id;
        $name_locale = $self->_locale_with_script(
            $provided_locale,
            $name_script,
        ) || return( $self->pass_error );
        $name_ordering_locale = $provided_locale->clone;
    }
    else
    {
        my $maximal_name_script = $self->_maximal_likely_locale( "und-${name_script}" );
        if( !defined( $maximal_name_script ) && $name_script eq 'Zzzz' )
        {
            $maximal_name_script = $self->_maximal_likely_locale( 'und' );
        }
        return( $self->pass_error ) if( !defined( $maximal_name_script ) );
        $name_base_language = $maximal_name_script->language_id;
        $name_locale = Locale::Unicode->new(
            join( '-', grep{ defined( $_ ) && CORE::length( $_ ) }
                ( $name_base_language, $name_script ) )
        ) || return( $self->pass_error( Locale::Unicode->error ) );
        $name_ordering_locale = $maximal_name_script;
    }

    my $full_formatting_locale = $self->_maximal_likely_locale( $self->{locale} ) ||
        return( $self->pass_error );
    my $effective_formatting_locale = $self->{locale}->clone;
    my $formatting_script = $full_formatting_locale->script;

    if( !$self->_scripts_match( $name_script, $formatting_script ) )
    {
        my $has_name_data = $self->_formatting_locale_has_name_data( $name_locale );
        return( $self->pass_error ) if( !defined( $has_name_data ) );

        if( $has_name_data )
        {
            $effective_formatting_locale = $name_locale->clone;
        }
        else
        {
            my $region = $name_locale->territory;
            my $fallback = join(
                '-',
                grep{ defined( $_ ) && CORE::length( $_ ) }
                    ( 'und', $name_script, $region )
            );
            $effective_formatting_locale = $self->_maximal_likely_locale( $fallback ) ||
                return( $self->pass_error );
        }
    }

    my $order = $self->_derive_name_order(
        $name,
        $name_ordering_locale,
        $effective_formatting_locale,
    );
    return( $self->pass_error ) if( !defined( $order ) );

    my $group = $self->_find_pattern_group(
        $order,
        $effective_formatting_locale
    ) || return( $self->pass_error );
    my $modifier = $self->_field_modifier( $effective_formatting_locale ) || return( $self->pass_error );
    my $patterns = [];

    foreach my $source ( @{$group->{patterns}} )
    {
        my $pattern = $self->_pattern( $source ) ||
            return( $self->pass_error );
        push( @$patterns, $pattern );
    }

    my $best;
    unless( $opts->{defer_pattern_selection} )
    {
        $best = $patterns->[0]->select_best(
            $patterns,
            $name,
            modifier_resolver => $modifier,
        ) || return( $self->pass_error( $patterns->[0]->error ) );
    }

    return({
        name_script                 => $name_script,
        name_base_language          => $name_base_language,
        name_locale                 => $name_locale,
        name_ordering_locale        => $name_ordering_locale,
        full_formatting_locale      => $full_formatting_locale,
        effective_formatting_locale => $effective_formatting_locale,
        order                       => $order,
        group                       => $group,
        modifier                    => $modifier,
        patterns                    => $patterns,
        pattern                     => $best,
    });
}

sub _pattern
{
    my $self   = shift( @_ );
    my $source = shift( @_ );
    if( !defined( $source ) )
    {
        return( $self->error( "No person-name pattern source was provided." ) );
    }
    $self->{pattern_cache} ||= {};
    if( exists( $self->{pattern_cache}->{ $source } ) )
    {
        return( $self->{pattern_cache}->{ $source } );
    }
    my $pattern = PersonName::Format::Pattern->new( $source ) ||
        return( $self->pass_error( PersonName::Format::Pattern->error ) );
    $self->{pattern_cache}->{ $source } = $pattern;
    return( $pattern );
}

sub _pattern_cache_size
{
    my $self = shift( @_ );
    return(0) unless( ref( $self->{pattern_cache} ) eq 'HASH' );
    return( scalar( keys( %{$self->{pattern_cache}} ) ) );
}

sub _render_context
{
    my $self        = shift( @_ );
    my $context     = shift( @_ );
    my $name        = shift( @_ );
    my $as_parts    = shift( @_ ) ? 1 : 0;
    my $render_name = $name;

    if( $self->{surname_all_caps} )
    {
        $render_name = PersonName::Format::SurnameAllCapsName->new( $name ) ||
            return( $self->pass_error( PersonName::Format::SurnameAllCapsName->error ) );
    }

    my $pattern = $self->_select_pattern( $context, $render_name ) ||
        return( $self->pass_error );
    my $replacement = exists( $context->{space_replacement} )
        ? $context->{space_replacement}
        : $self->_space_replacement(
            $context->{effective_formatting_locale},
            $context->{name_locale},
        );
    if( !defined( $replacement ) )
    {
        return( $self->pass_error );
    }
    $context->{space_replacement} = $replacement;

    if( $as_parts )
    {
        my $parts = $pattern->format_to_parts(
            $render_name,
            modifier_resolver => $context->{modifier}
        );
        if( !defined( $parts ) )
        {
            return( $self->pass_error( $pattern->error ) );
        }
        foreach my $part ( @$parts )
        {
            unless( $part->{type} eq 'literal' )
            {
                next;
            }
            $part->{value} =~ s/ +/$replacement/gs;
        }
        return( [grep{ CORE::length( $_->{value} ) } @$parts] );
    }

    my $result = $pattern->format(
        $render_name,
        modifier_resolver => $context->{modifier}
    );
    if( !defined( $result ) )
    {
        return( $self->pass_error( $pattern->error ) );
    }
    $result =~ s/ +/$replacement/gs;
    return( $result );
}

sub _scripts_match
{
    my $self  = shift( @_ );
    my $left  = shift( @_ );
    my $right = shift( @_ );
    if( !defined( $left ) ||
        !defined( $right ) ||
        $left eq 'Zzzz' ||
        $right eq 'Zzzz' ||
        $left eq $right )
    {
        return(1);
    }

    my $left_set  = $SCRIPT_SETS->{ $left } || { $left => 1 };
    my $right_set = $SCRIPT_SETS->{ $right } || { $right => 1 };

    foreach my $script ( keys( %$left_set ) )
    {
        return(1) if( exists( $right_set->{ $script } ) );
    }
    return(0);
}

sub _select_pattern
{
    my $self    = shift( @_ );
    my $context = shift( @_ );
    my $name    = shift( @_ );
    if( defined( $context->{pattern} ) )
    {
        return( $context->{pattern} );
    }
    my $patterns = $context->{patterns};
    unless( ref( $patterns ) eq 'ARRAY' && @$patterns )
    {
        return( $self->error( "The formatting context contains no patterns." ) );
    }
    return( $patterns->[0]->select_best(
        $patterns,
        $name,
        modifier_resolver => $context->{modifier}
    ) || $self->pass_error( $patterns->[0]->error ) );
}

sub _space_replacement
{
    my $self = shift( @_ );
    my $formatting_locale = shift( @_ );
    my $name_locale = shift( @_ );
    my $replacement = $self->{data}->person_name_space_replacement(
        formatting_locale => $formatting_locale,
        name_locale       => $name_locale,
    );
    if( !defined( $replacement ) )
    {
        return( $self->pass_error( $self->{data}->error ) );
    }
    return( $replacement );
}

# NOTE: PersonName::Format::SurnameAllCapsName class
package PersonName::Format::SurnameAllCapsName;
BEGIN
{
    use v5.10.1;
    use strict;
    use warnings;
    use parent qw( PersonName::Format::Name );
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    unless( Scalar::Util::blessed( $name ) )
    {
        return( $self->error( "No underlying name object was provided." ) );
    }
    $self->{name} = $name;
    return( $self );
}

sub get_field_value
{
    my $self = shift( @_ );
    my $field = shift( @_ );
    my $modifiers = shift( @_ );
    my $value = $self->{name}->get_field_value( $field, $modifiers );
    return if( !defined( $value ) );
    if( $field eq 'surname' ||
        $field eq 'surname2' )
    {
        return( uc( $value ) );
    }
    return( $value );
}

sub name_locale { return( shift->{name}->name_locale( @_ ) ); }

sub preferred_order { return( shift->{name}->preferred_order( @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

PersonName::Format - CLDR person-name formatter for Perl

=head1 SYNOPSIS

    my $formatter = PersonName::Format->new(
        'ja-JP',
        length         => 'long',
        usage          => 'referring',
        formality      => 'formal',
        displayOrder   => 'default',
        surnameAllCaps => 0,
    );

    # Native Japanese order: 宮崎駿
    my $native = $formatter->format(
        given      => '駿',
        surname    => '宮崎',
        nameLocale => 'ja-JP',
    );

    # Japanese formatter switching to Latin conventions for a foreign name
    my $foreign = $formatter->format(
        given      => 'Albert',
        surname    => 'Einstein',
        nameLocale => 'de-CH',
    );

    # Pass a hash reference instead of a flat list
    my $by_ref = $formatter->format({
        given      => 'Albert',
        surname    => 'Einstein',
        nameLocale => 'de-CH',
    });

    # Or pass any object that satisfies the name contract
    my $by_obj = $formatter->format( $my_name_object );

=head1 DESCRIPTION

C<PersonName::Format> formats structured personal names using CLDR person-name patterns provided by L<Locale::Unicode::Data>.

The formatter derives the name script by inspecting the surname and then the given name, derives or adjusts the name locale using likely-subtag data, compares the name and formatting scripts, and switches to an effective formatting locale when required by UTS #35 Part 8.

The implementation is pure Perl. Script detection is intentionally isolated so it can later be replaced by an optional XS backend without changing the public API.

=head1 CONSTRUCTOR

=head2 new

    my $formatter = PersonName::Format->new( $locale, %options );

Creates a new formatter. The first positional argument is the BCP 47 formatting locale tag (required). All remaining arguments are named options documented under L</CONSTRUCTOR OPTIONS>.

=head1 CONSTRUCTOR OPTIONS

=head2 display_order

=head2 displayOrder

C<default>, C<givenFirst>, C<surnameFirst>, or C<sorting>.

=head2 formality

C<formal> or C<informal>. When omitted, the CLDR default inherited by the formatter locale is used.

=head2 length

C<long>, C<medium>, or C<short>. When omitted, the CLDR default inherited by the formatter locale is used.

=head2 surname_all_caps

=head2 surnameAllCaps

Boolean option causing surname fields to be rendered in uppercase.

=head2 usage

C<referring>, C<addressing>, or C<monogram>. Defaults to C<referring>.

=head1 METHODS

=head2 compile

    my $compiled = $formatter->compile(
        nameLocale => 'fr-FR',
        nameScript => 'Latn',
    );

Returns a L<PersonName::Format::Compiled> object with the name identity and resolved CLDR context frozen. C<nameScript> is required. C<nameLocale> and C<preferredOrder> are optional but, when supplied, are enforced for every name formatted by the compiled object.

=head2 format

    my $string = $formatter->format( $name_object );
    my $string = $formatter->format( \%fields );
    my $string = $formatter->format( given => 'John', surname => 'Doe' );

Formats a name and returns the resulting string. The argument may be:

=over 4

=item * any object satisfying the name contract (see L<PersonName::Format::Name/implements_name_contract>)

=item * a hash reference of name fields

=item * a flat key/value list of name fields

=back

The name locale may be omitted. When present, its language and region are retained and its script is replaced by the script detected in the name data.

=head2 format_to_parts

    my $parts = $formatter->format_to_parts( \%fields );

Returns an array reference of hash references describing the generated parts.
Literal spacing replacement is applied only to literal parts.
Each hash has the following keys:

=over 4

=item C<type>

For field parts, the CLDR pattern field expression such as C<given> or C<given-initial>. For spacing between fields, the value is C<literal>.

=item C<value>

The rendered text for this part.

=item C<field>

Present on non-literal parts. The base CLDR field name such as C<given> or C<surname>.

=item C<modifiers>

Present on non-literal parts when modifiers were resolved. An array reference of modifier names.

=back

=head2 resolved_options

Returns the resolved constructor options. Per-name derived locales are not constructor options and are therefore not included.

=head2 resolvedOptions

Alias for C<resolved_options()>.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
