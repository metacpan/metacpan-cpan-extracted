package Perl::Critic::Policy::PreferredModules;

use strict;
use warnings;

use parent 'Perl::Critic::Policy';

use Perl::Critic::Utils qw{ :severities :classification :ppi $SEVERITY_MEDIUM $TRUE $FALSE };

use Perl::Critic::Exception::AggregateConfiguration ();
use Perl::Critic::Exception::Configuration::Generic ();

use Config::INI::Reader ();
use PPI::Document       ();
use File::Spec          ();

sub supported_parameters {
    return (
        {
            name        => 'config',
            description => 'Config::INI file listing recommendations.',
            behavior    => 'string',
        },
    );
}

use constant default_severity => $SEVERITY_MEDIUM;
use constant applies_to       => qw{ PPI::Statement::Include PPI::Token::Word };

use constant optional_config_attributes => qw{ prefer reason severity message for };

use constant builtin_config_attributes => qw{ prefer reason severity };

# `[perl/rand]` prefers a module over the builtin function `rand`
use constant BUILTIN_SECTION => qr{\A perl \s* / \s* (\S+) \z}x;

our $VERSION = '0.005'; # VERSION
# ABSTRACT: Provide custom package recommendations

sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    $self->{_is_enabled} = !! $self->_parse_config( $self->_config_file($config) );

    return $TRUE;
}

sub _config_file {
    my ( $self, $config ) = @_;

    $config //= $self->__get_config;

    my $cfg_file = $config->get('config') // '';
    $cfg_file =~ s{^~}{$ENV{HOME}};

    return $cfg_file;
}

# Resolving a `prefer` module for a builtin means loading it, so such a
# configuration is only honoured when unsafe policies are allowed.
sub is_safe {
    my ($self) = @_;

    return $self->_loads_modules ? $FALSE : $TRUE;
}

sub _loads_modules {
    my ($self) = @_;

    # Perl::Critic asks before initialize_if_enabled has parsed anything, so
    # take a look at the configuration ourselves. Errors are left for
    # _parse_config to report at the usual point.
    my $builtins = $self->{_cfg_preferred_builtins} // $self->_scan_builtin_sections;

    return ( grep { defined $_->{prefer} } values %$builtins ) ? $TRUE : $FALSE;
}

sub _scan_builtin_sections {
    my ($self) = @_;

    my $raw = eval { $self->_read_config } or return {};
    my $cfg = $raw->{config}               or return {};

    my %builtins;
    foreach my $pkg ( keys %$cfg ) {
        next unless my ($function) = $pkg =~ BUILTIN_SECTION;
        $builtins{$function} = $cfg->{$pkg};
    }

    return \%builtins;
}

# Read and parse the INI file, once. is_safe() needs it before
# initialize_if_enabled does, and both are given the same answer. Problems are
# recorded rather than thrown, so the caller decides when to complain.
sub _read_config {
    my ( $self, $cfg_file ) = @_;

    $cfg_file //= $self->_config_file;

    my $cached = $self->{_raw_config};
    return $cached if $cached && $cached->{file} eq $cfg_file;

    my $raw = $self->{_raw_config} = { file => $cfg_file };

    return $raw if !length $cfg_file;

    if ( !-e $cfg_file ) {
        $raw->{error} = qq[config file '$cfg_file' does not exist.];
        return $raw;
    }

    # slurp the file rather than using `read_file` for compat with Test::MockFile
    my $content;
    {
        local $/;
        open my $fh, '<', $cfg_file or do {
            $raw->{error} = qq[Cannot open config file '$cfg_file': $!];
            return $raw;
        };
        $content = <$fh>;
    }

    my $parsed;
    if ( eval { $parsed = Config::INI::Reader->read_string($content); 1 } ) {
        $raw->{config} = $parsed;
        return $raw;
    }
    $raw->{error} = qq[Invalid configuration file $cfg_file];

    return $raw;
}

sub _throw {
    my ( $self, $msg ) = @_;

    Perl::Critic::Exception::Configuration::Generic->throw(
        message => __PACKAGE__ . ' ' . ( $msg // 'Unknown Error' ),
    );
}

# Collect a configuration error rather than dying on the spot, so a single run
# can report every problem in the file at once.
sub _add_exception {
    my ( $self, $msg ) = @_;

    $self->{_config_errors} //= Perl::Critic::Exception::AggregateConfiguration->new();

    $self->{_config_errors}->add_exception(
        Perl::Critic::Exception::Configuration::Generic->new(
            message => __PACKAGE__ . ' ' . ( $msg // 'Unknown Error' ),
        )
    );

    return;
}

sub _throw_collected_exceptions {
    my ($self) = @_;

    my $errors = delete $self->{_config_errors} or return;

    die $errors if $errors->has_exceptions();

    return;
}

sub _parse_config {
    my ( $self, $cfg_file ) = @_;

    my $raw = $self->_read_config($cfg_file);

    # A file we cannot read or parse at all is fatal on the spot; only the
    # per-package settings below are collected and reported together.
    $self->_throw( $raw->{error} ) if $raw->{error};

    my $preferred_cfg = $raw->{config} or return;

    my ( %modules, %builtins );

    # Config::INI uses '_' for the root/default section — skip it
    delete $preferred_cfg->{'_'};

    foreach my $pkg ( sort keys %$preferred_cfg ) {
        my $setup = $preferred_cfg->{$pkg};

        if ( $pkg eq 'perl' ) {
            $self->_add_exception(
                "Invalid configuration - use a '[perl/<function>]' section to prefer a module over a builtin function");
            next;
        }

        if ( my ($function) = $pkg =~ BUILTIN_SECTION ) {
            $self->_validate_settings( $pkg, $setup, builtin_config_attributes() );
            $builtins{$function} = $setup;
            next;
        }

        $self->_validate_settings( $pkg, $setup, optional_config_attributes() );

        if ( defined $setup->{for} ) {
            my @functions = grep { length } split m{[\s,]+}, $setup->{for};
            if ( !@functions ) {
                $self->_add_exception("Invalid configuration - Package '$pkg' has an empty 'for' list");
            }
            $setup->{_for_functions} = \@functions;
        }

        $modules{$pkg} = $setup;
    }

    $self->_throw_collected_exceptions();

    $self->{_cfg_preferred_modules}  = \%modules;
    $self->{_cfg_preferred_builtins} = \%builtins;

    return 1;
}

sub _validate_settings {
    my ( $self, $pkg, $setup, @valid_opts ) = @_;

    my %is_valid = map { $_ => 1 } @valid_opts;

    foreach my $opt ( keys %$setup ) {
        next if $is_valid{$opt};
        $self->_add_exception("Invalid configuration - Package '$pkg' is using an unknown setting '$opt'");
    }

    if ( defined $setup->{severity} ) {
        my $sev = $setup->{severity};
        if ( $sev !~ /\A[1-5]\z/ ) {
            $self->_add_exception("Invalid configuration - Package '$pkg' has invalid severity '$sev' (must be 1-5)");
        }
    }

    return;
}

sub _is_string_token {
    my ($token) = @_;

    return $token->isa('PPI::Token::QuoteLike::Words') || $token->isa('PPI::Token::Quote');
}

# Extract the real module from a `use if CONDITION, 'Module::Name', IMPORT_LIST`
# statement: after the first comma, the next token is the module name.
sub _extract_use_if_module {
    my ( $self, $elem ) = @_;

    my $found_comma;
    for my $child ( $elem->children ) {
        if ( $child->isa('PPI::Token::Operator') && $child->content eq ',' ) {
            $found_comma = 1;
            next;
        }
        next unless $found_comma;
        next if $child->isa('PPI::Token::Whitespace');

        if ( $child->isa('PPI::Token::Quote') ) {
            return $child->string;
        }
        if ( $child->isa('PPI::Token::Word') ) {
            return $child->content;
        }

        return;
    }

    return;
}

# Return the list of names explicitly imported by an include statement,
# e.g. `use Foo qw{ bar baz }` or `use Foo 'bar', 'baz'`.
sub _imported_names {
    my ( $self, $elem ) = @_;

    my @names;

    foreach my $arg ( $elem->arguments ) {
        my @tokens =
          $arg->isa('PPI::Node')
          ? @{ $arg->find( sub { _is_string_token( $_[1] ) } ) || [] }
          : ($arg);

        foreach my $token (@tokens) {
            next unless _is_string_token($token);
            push @names, $token->isa('PPI::Token::QuoteLike::Words') ? $token->literal : $token->string;
        }
    }

    return @names;
}

# True for `use Foo ()`, which imports nothing, but not for a bare `use Foo`,
# which pulls in whatever the module exports by default.
sub _has_empty_import_list {
    my ( $self, $elem ) = @_;

    my @args = $elem->arguments;

    return $FALSE unless @args == 1;
    return $FALSE unless $args[0]->isa('PPI::Structure::List');

    return $args[0]->schildren ? $FALSE : $TRUE;
}

# Look for calls to any of @functions anywhere in the document, either as a
# plain function call or fully qualified as $module::function.
sub _document_calls_any {
    my ( $self, $elem, $module, @functions ) = @_;

    my $doc = $elem->top or return $FALSE;
    return $FALSE unless $doc->isa('PPI::Document');

    my %wanted = map { ( $_ => 1, "${module}::$_" => 1 ) } @functions;

    my $words = $doc->find( sub { $_[1]->isa('PPI::Token::Word') && $wanted{ $_[1]->content } } ) or return $FALSE;

    foreach my $word (@$words) {
        return $TRUE if is_function_call($word);
    }

    return $FALSE;
}

# A `for` entry restricts the preference to the listed functions: the module is
# only reported when one of them is actually pulled in or called.
sub _matches_for {
    my ( $self, $elem, $module, $setup ) = @_;

    my $functions = $setup->{_for_functions};
    return $TRUE unless $functions && @$functions;

    my %wanted = map { $_ => 1 } @$functions;

    foreach my $name ( $self->_imported_names($elem) ) {
        return $TRUE if $wanted{$name};
    }

    return $self->_document_calls_any( $elem, $module, @$functions );
}

sub _normalize_export_name {
    my ($name) = @_;

    $name =~ s{\A&}{};

    return $name;
}

# What $module exports, as { default => {}, optional => {}, tags => {} }, or
# undef when we cannot tell. Answers are cached: resolving means loading or
# parsing the module.
sub _module_exports {
    my ( $self, $module ) = @_;

    my $cache = $self->{_module_exports} //= {};
    return $cache->{$module} if exists $cache->{$module};

    $cache->{$module} = undef;    # guards against a module resolving to itself

    return undef unless $module =~ m{\A [A-Za-z_]\w* (?: :: \w+ )* \z}x;

    return $cache->{$module} = $self->_load_module_exports($module) // $self->_parse_module_exports($module);
}

# Preferred source: once the module is loaded its symbol table is what Exporter
# itself consults, including anything built at load time or inherited.
sub _load_module_exports {
    my ( $self, $module ) = @_;

    my $path = _module_path($module);

    if ( !$INC{$path} ) {
        local $SIG{__WARN__} = sub { };
        eval { require $path; 1 } or return undef;
    }

    my %tags;
    my %declared_tags = _package_hash( $module, 'EXPORT_TAGS' );
    foreach my $tag ( keys %declared_tags ) {
        my $names = $declared_tags{$tag};
        next unless ref $names eq 'ARRAY';
        $tags{$tag} = { map { _normalize_export_name($_) => 1 } @$names };
    }

    return {
        default  => { map { _normalize_export_name($_) => 1 } _package_array( $module, 'EXPORT' ) },
        optional => { map { _normalize_export_name($_) => 1 } _package_array( $module, 'EXPORT_OK' ) },
        tags     => \%tags,
    };
}

sub _package_array {
    my ( $module, $name ) = @_;

    no strict 'refs';    ## no critic (ProhibitNoStrict)
    return @{"${module}::${name}"};
}

sub _package_hash {
    my ( $module, $name ) = @_;

    no strict 'refs';    ## no critic (ProhibitNoStrict)
    return %{"${module}::${name}"};
}

# Fallback for a module that will not load in this process: read the export
# lists straight out of its source. Only literal declarations are understood.
sub _parse_module_exports {
    my ( $self, $module ) = @_;

    my $file = _find_module_file($module) or return undef;

    my $doc = eval { PPI::Document->new($file) } or return undef;

    my %exports = ( default => {}, optional => {}, tags => {} );

    my $symbols = $doc->find( sub { $_[1]->isa('PPI::Token::Symbol') } ) || [];

    foreach my $symbol (@$symbols) {
        my $statement = $symbol->statement or next;

        my $kind = { '@EXPORT' => 'default', '@EXPORT_OK' => 'optional' }->{ $symbol->symbol };

        if ($kind) {
            $exports{$kind}{$_} = 1 for _exported_names_in($statement);
        }
        elsif ( $symbol->symbol eq '%EXPORT_TAGS' ) {
            _parse_export_tags( $statement, $exports{tags} );
        }
    }

    return \%exports;
}

sub _module_path {
    my ($module) = @_;

    ( my $path = "$module.pm" ) =~ s{::}{/}g;

    return $path;
}

sub _find_module_file {
    my ($module) = @_;

    my @parts = split m{::}, "$module.pm";

    foreach my $dir (@INC) {
        next if ref $dir;
        my $candidate = File::Spec->catfile( $dir, @parts );
        return $candidate if -f $candidate;
    }

    return undef;
}

sub _within_subscript {
    my ($token) = @_;

    my $parent = $token->parent;
    while ($parent) {
        return $TRUE if $parent->isa('PPI::Structure::Subscript');
        $parent = $parent->parent;
    }

    return $FALSE;
}

# Literal names in an export declaration. Anything under a subscript is skipped,
# so `@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } )` does not yield 'all'.
sub _exported_names_in {
    my ($element) = @_;

    my $tokens = $element->find( sub { _is_string_token( $_[1] ) } ) || [];

    my @names;
    foreach my $token (@$tokens) {
        next if _within_subscript($token);
        push @names, $token->isa('PPI::Token::QuoteLike::Words') ? $token->literal : $token->string;
    }

    return map { _normalize_export_name($_) } @names;
}

# Pick up `tag => [ ... ]` pairs from a %EXPORT_TAGS declaration.
sub _parse_export_tags {
    my ( $statement, $tags ) = @_;

    my $constructors = $statement->find( sub { $_[1]->isa('PPI::Structure::Constructor') } ) || [];

    foreach my $constructor (@$constructors) {
        my $tag = _tag_name_before($constructor) or next;

        my %names = map { $_ => 1 } _exported_names_in($constructor);
        $tags->{$tag} = \%names if %names;
    }

    return;
}

sub _tag_name_before {
    my ($constructor) = @_;

    my $fat_comma = $constructor->sprevious_sibling or return undef;
    return undef unless $fat_comma->isa('PPI::Token::Operator') && $fat_comma->content eq '=>';

    my $key = $fat_comma->sprevious_sibling or return undef;

    return $key->content if $key->isa('PPI::Token::Word');
    return $key->string  if $key->isa('PPI::Token::Quote');

    return undef;
}

# True when this include provides $function: either it is named in the import
# list, or it comes in through a tag or the module's default exports. When the
# exports cannot be resolved we assume it is provided, so an unknown module
# never turns into a false positive.
sub _include_provides {
    my ( $self, $include, $module, $function ) = @_;

    my $exports = $self->_module_exports($module);

    my @args = $include->arguments;

    if ( !@args ) {    # a bare `use Module` imports whatever it exports by default
        return $TRUE unless $exports;
        return $exports->{default}{$function} ? $TRUE : $FALSE;
    }

    return $FALSE if $self->_has_empty_import_list($include);

    foreach my $imported ( $self->_imported_names($include) ) {
        $imported = _normalize_export_name($imported);

        return $TRUE if $imported eq $function;

        next unless my ($tag) = $imported =~ m{\A:(.+)\z};
        return $TRUE unless $exports;

        my $names = $exports->{tags}{$tag};
        return $TRUE unless $names;    # an unknown tag might well cover it
        return $TRUE if $names->{$function};
    }

    return $FALSE;
}

# True when $module is used in a way that provides $function to the current
# document, so a call to $function is already the preferred implementation.
sub _provides_function {
    my ( $self, $elem, $module, $function ) = @_;

    my $doc = $elem->top or return $FALSE;
    return $FALSE unless $doc->isa('PPI::Document');

    my $includes = $doc->find( sub { $_[1]->isa('PPI::Statement::Include') } ) or return $FALSE;

    foreach my $include (@$includes) {
        next unless ( $include->module // '' ) eq $module;
        next if ( $include->type // '' ) eq 'require';

        return $TRUE if $self->_include_provides( $include, $module, $function );
    }

    return $FALSE;
}

# True when the module has the function but does not hand it over by default,
# which is the case worth explaining: the config looks satisfied while the
# builtin is still what runs.
sub _exports_on_request {
    my ( $self, $module, $function ) = @_;

    my $exports = $self->_module_exports($module) or return $FALSE;

    return $FALSE if $exports->{default}{$function};

    return $exports->{optional}{$function} ? $TRUE : $FALSE;
}

sub _violates_include {
    my ( $self, $elem ) = @_;

    # 'no Module' unloads/disables — not a use violation
    my $type = $elem->type;
    return () if defined $type && $type eq 'no';

    my $module = $elem->module;

    return () unless defined $module;

    # Handle 'use if CONDITION, Module' by extracting the real module
    if ( $module eq 'if' && ( $elem->type // '' ) eq 'use' ) {
        $module = $self->_extract_use_if_module($elem);
        return () unless defined $module;
    }

    my @violations;

    if ( my $setup = $self->{_cfg_preferred_modules}->{$module} ) {
        push @violations, $self->_build_violation( $module, $setup, $elem );
    }

    # Also check modules passed as arguments to 'use parent' / 'use base'
    if ( $module eq 'parent' || $module eq 'base' ) {
        for my $parent_mod ( $self->_extract_parent_modules($elem) ) {
            next unless my $setup = $self->{_cfg_preferred_modules}->{$parent_mod};
            push @violations, $self->_build_violation( $parent_mod, $setup, $elem );
        }
    }

    return @violations;
}

sub _build_violation {
    my ( $self, $module, $setup, $elem ) = @_;

    return () unless $self->_matches_for( $elem, $module, $setup );

    my $desc = qq[Using module $module is not recommended];
    my $expl = $setup->{reason} // $desc;

    if ( defined $setup->{message} ) {
        $desc = $setup->{message};
    }
    elsif ( my $prefer = $setup->{prefer} ) {
        $desc = "Prefer using module $prefer over $module";
    }

    if ( my $functions = $setup->{_for_functions} ) {
        $desc .= ' for ' . join( ', ', @$functions );
    }

    return $self->_violation_for( $setup, $desc, $expl, $elem );
}

sub _violates_builtin {
    my ( $self, $elem ) = @_;

    my $function = $elem->content;

    return () unless my $setup = $self->{_cfg_preferred_builtins}->{$function};
    return () unless is_function_call($elem);

    my $desc = qq[Using the builtin $function is not recommended];
    my $expl = $setup->{reason} // $desc;

    if ( my $prefer = $setup->{prefer} ) {

        # already calling the preferred implementation
        return () if $self->_provides_function( $elem, $prefer, $function );

        $desc = "Prefer using ${prefer}::${function} over the builtin $function";

        if ( !defined $setup->{reason} && $self->_exports_on_request( $prefer, $function ) ) {
            $expl =
                "$prefer exports $function on request only, so this call is still the builtin"
              . " - import it explicitly with `use $prefer qw{ $function }`";
        }
    }

    return $self->_violation_for( $setup, $desc, $expl, $elem );
}

sub _violation_for {
    my ( $self, $setup, $desc, $expl, $elem ) = @_;

    if ( my $sev = $setup->{severity} ) {
        local $self->{_severity} = $sev;
        return $self->violation( $desc, $expl, $elem );
    }

    return $self->violation( $desc, $expl, $elem );
}

sub _extract_parent_modules {
    my ( $self, $elem ) = @_;

    my @modules;
    for my $child ( $elem->schildren ) {
        if ( $child->isa('PPI::Token::Quote') ) {
            my $val = $child->string;
            push @modules, $val if $val =~ /\A[A-Za-z_]\w*(?:::\w+)*\z/;
        }
        elsif ( $child->isa('PPI::Token::QuoteLike::Words') ) {
            push @modules, grep { /\A[A-Za-z_]\w*(?:::\w+)*\z/ } $child->literal;
        }
    }
    return @modules;
}

sub violates {
    my ( $self, $elem ) = @_;

    return () unless $self->{_is_enabled};
    return () unless $elem;

    return $self->_violates_include($elem) if $elem->isa('PPI::Statement::Include');
    return $self->_violates_builtin($elem) if $elem->isa('PPI::Token::Word');

    return ();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::PreferredModules - Provide custom package recommendations

=head1 VERSION

version 0.005

=head1 DESCRIPTION

Every project has its own rules for preferring specific packages over others.

This Policy tries to be `un-opinionated` and let the user provide a module
preferences with an explanation and/or suggested alternative.

=head1 MODULES

=head1 CONFIGURATION

To use L<Perl::Critic::Policy::PreferredModules> you have first to enable it in your
 F<.perlcriticrc> file by providing a F<preferred_modules.ini> configuration file:

    [PreferredModules]
    config = /path/to/preferred_modules.ini
    # you can also use '~' in the path for $HOME
    #config = ~/.preferred_modules

The  F<preferred_modules.ini> file is using the L<Config::INI> format and can looks like this

    [Do::Not::Use]
    prefer = Another::Package
    reason = "Please use Another::Package rather than Do::Not::Use"

    [Avoid::Using::This]
    [And::Also::That]

    [No:Reason]
    prefer=A::Better:Module
    
    [Only::Reason]
    reason="If you use this module, a puppy might die."

    [Hard::Ban]
    severity=5
    reason="This module has known security vulnerabilities"

    [Custom::Message]
    message="Do not use Custom::Message - see internal wiki for details"

    [File::Slurper]
    prefer = File::Slurper::Temp
    for = write_binary write_text

    [perl/rand]
    prefer = Crypt::PRNG

Each module entry supports the following optional keys:

=over 4

=item C<prefer> - Suggested replacement module

=item C<reason> - Explanation shown in the violation message

=item C<severity> - Override the policy's default severity for this module (1-5, where 5 is most severe)

=item C<message> - Free-form description that fully replaces the auto-generated violation text

=item C<for> - Restrict the preference to a list of functions (whitespace and/or comma separated)

=back

=head2 Partial preferences

Sometimes the preferred module only implements a part of the API it replaces.
For example L<File::Slurper::Temp> is a rename-in-place writer: it provides the
C<write_> functions of L<File::Slurper> but none of its readers. Recommending it
unconditionally would be incorrect.

The C<for> key limits the recommendation to the listed functions:

    [File::Slurper]
    prefer = File::Slurper::Temp
    for = write_binary write_text

With that configuration:

    use File::Slurper qw{ write_text };            # violation
    use File::Slurper qw{ read_text };             # no violation
    use File::Slurper qw{ read_text write_text };  # violation

When the import list does not name any of them - because there is no import
list, or because it only uses export tags - the rest of the document is
inspected instead, and the violation is only reported if one of the listed
functions is actually called, either directly or fully qualified:

    use File::Slurper;
    write_text( $file, $content );                 # violation

    require File::Slurper;
    File::Slurper::read_text($file);               # no violation

=head2 Preferring a module's implementation of a builtin function

A section named C<[perl/E<lt>functionE<gt>]> applies to calls to the builtin
function rather than to a module import. Use one section per function:

    [perl/rand]
    prefer = Crypt::PRNG
    reason = the builtin rand is not cryptographically secure

These sections accept the same C<prefer>, C<reason> and C<severity> keys as a
module entry. C<for> is not accepted: the function is already named by the
section itself.

A bare C<[perl]> section is rejected, since duplicate INI
section names silently collapse into one.

The call has to be a real function call, so method calls, hash keys and
subroutine declarations of the same name are left alone:

    my $x = rand();                # violation
    my $x = rand;                  # violation
    my $x = $prng->rand;           # no violation
    my %h = ( rand => 1 );         # no violation

=head3 Calls to the preferred implementation are not reported

When the preferred module is imported in a way that provides the function, a
call to that name I<is> the preferred implementation, so nothing is reported.

    use Crypt::PRNG qw{ rand };
    my $x = rand();                # no violation, this is Crypt::PRNG::rand

    use Crypt::PRNG ();            # imports nothing
    my $x = rand();                # violation, this is the builtin

The whole document is considered, not just the enclosing scope.
Use an empty import list, e.g. C<use Crypt::PRNG ()> if you want to be fully
sure you never call the builtin.
Fully qualified calls such as C<Crypt::PRNG::rand()> never
match a C<[perl/rand]> section to begin with, since the section only applies to
unqualified calls.

=head3 A bare C<use> is checked against the module's exports

An import list that names the function can be read straight off the source, but
a bare C<use Crypt::PRNG> only helps if the module hands the function over by
default. Taking that on trust would hide the very mistake this is meant to
catch, because C<Crypt::PRNG> declares C<@EXPORT = qw()>:

    use Crypt::PRNG;
    my $x = rand();                # violation, this is still the builtin

That reads as though the configuration is being honoured while every call goes
to the builtin. The explanation says what happened and how to fix it:

    Crypt::PRNG exports rand on request only, so this call is still the
    builtin - import it explicitly with `use Crypt::PRNG qw{ rand }`

To answer that question the module named by C<prefer> is loaded, unless it is
already in C<%INC>, and its C<@EXPORT>, C<@EXPORT_OK> and C<%EXPORT_TAGS> are
read from the symbol table - the same lists L<Exporter> itself consults, so
exports built at load time or inherited from a parent are accounted for. Only
modules you name in your own configuration are ever loaded, and each is resolved
at most once per run.

=head3 This requires C<-allow-unsafe>

Loading a module runs its code: C<BEGIN> blocks, top level statements, whatever
the author put there. That is more than static analysis is normally allowed to
do, so a configuration that needs it is treated as unsafe and L<Perl::Critic>
will not load this policy without C<-allow-unsafe>:

    perlcritic --allow-unsafe ...

or, in your F<.perlcriticrc>:

    allow_unsafe = 1

Only a C<[perl/E<lt>functionE<gt>]> section that names a C<prefer> module makes
the policy unsafe, because nothing else here loads anything. Module preferences,
C<for> lists, and builtin sections without a C<prefer> all stay safe and need no
flag.

Note that the policy is silently left out when the flag is missing, which is how
L<Perl::Critic> handles every unsafe policy. If your C<[perl/...]> sections seem
to do nothing, that is the first thing to check. C<--single-policy> bypasses the
safety check altogether, so it will run these sections without the flag.

If a module will not load in the process running the policy, its source is
located in C<@INC> and parsed instead. That fallback only understands literal
declarations, so a list built at runtime is invisible to it.

Export tags are resolved from the same lists:

    use Crypt::PRNG qw{ :all };
    my $x = rand();                # no violation, :all covers rand

When the exports cannot be resolved at all - the module is not installed, or its
lists are built in a way the fallback cannot read - the function is assumed to
be provided and nothing is reported, so an unresolvable module never turns into
a false positive.

Leaving C<prefer> out discourages the builtin outright:

    [perl/each]
    reason = iterating with each() is error prone
    severity = 4

=head1 PARENT AND BASE CLASS CHECKING

When the policy encounters C<use parent> or C<use base> statements, it also
checks the modules passed as arguments. For example, if C<Banned::Module> is
in your configuration file, all of these will trigger a violation:

    use Banned::Module;
    use parent 'Banned::Module';
    use base qw(Banned::Module);
    use parent -norequire, 'Banned::Module';

=head1 CONDITIONAL LOADING

The policy detects modules loaded via C<use if>:

    use if $] >= 5.010, 'Some::Module';

If C<Some::Module> is listed in the configuration file, a violation will be
reported. This ensures that conditional imports are not silently overlooked.

=head1 SEE ALSO

L<Perl::Critic>

=head1 AUTHOR

Nicolas R <nicolas@atoomic.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by WebPros International, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
