package OpenTelemetry::Instrumentation::namespace;
# ABSTRACT: OpenTelemetry instrumentation for a namespace

our $VERSION = '0.033';

use v5.38;
use experimental 'try';

use Class::Method::Modifiers 'install_modifier';
use Devel::Peek;
use List::Util 'pairs';
use Module::Runtime ();
use OpenTelemetry::Common;
use OpenTelemetry;
use Ref::Util qw( is_regexpref is_coderef is_hashref );
use YAML::PP;

use namespace::clean ();

use parent 'OpenTelemetry::Instrumentation';

my $LOGGER = OpenTelemetry::Common::internal_logger;
my %CACHE;

sub install {
    my $class = shift;
    my ( $rules, $options ) = $class->parse_options(@_);

    return !!1 unless @$rules;

    # Loop over loaded modules
    for my $module ( keys %INC ) {
        if ( lc $module eq $module ) {
            # $LOGGER->trace("Not auto-instrumenting $module because it is a pragma");
            next;
        }

        if ( $module =~ /^[0-9]/ ) {
            # $LOGGER->trace("Not auto-instrumenting $module because it is a version");
            next;
        }

        $class->wrap_module( $module, $rules, $options )
    }

    $class->wrap_require( $rules, $options );

    return !!1;
}

sub wrap_require ($class, $rules, $options ) {
    my $old_hook = ${^HOOK}{require__before};
    ${^HOOK}{require__before} = sub {
        my ($name) = @_;

        my $return;
        $return = $old_hook->($name) if $old_hook;

        return sub {
            $return->() if ref $return && is_coderef $return;
            return unless $INC{$name};
            $class->wrap_module($name, $rules, $options);
        };
    };
}

sub parse_options ( $class, @config ) {
    my %options = (
        -ignore_constants        => 1,
        -ignore_private          => 1,
        -ignore_import           => 1,
        -prefer_instrumentations => 1,
    );

    my @rules;
    for ( pairs @config ) {
        unless ( $_->[0] =~ /^-/ ) {
            push @rules, @$_;
            next;
        }

        $options{ $_->[0] } = $_->[1];
    }

    if ( my $path = delete $options{-from_file} ) {
        try {
            $LOGGER->trace("Loading OpenTelemetry namespace configuration from $path");
            my $loaded = YAML::PP::LoadFile($path);
            @rules = ( is_hashref($loaded) ? %$loaded : @$loaded, @rules );
        }
        catch ($e) {
            $LOGGER->warn(
                "Could not load configuration for OpenTelemetry namespace instrumentation: $e"
            );
        }
    }

    return ( \@rules, \%options );
}

sub wrap_module ( $class, $module, $rules, $options ) {
    my $package = $module =~ s/\//::/gr;
    $package =~ s/\.p[ml]$//;

    if ( $package =~ /^::/ ) {
        # $LOGGER->trace("Not auto-instrumenting $package because it is not a package");
        return;
    }

    if ( $package =~ /^OpenTelemetry/ ) {
        # $LOGGER->trace("Not auto-instrumenting $package because it is itself an OpenTelemetry class");
        return;
    }

    # TODO
    if ( $package =~ /^(?:B|Exporter|Test2|Plack|XSLoader)(?:::|$)/ ) {
        # $LOGGER->trace("Not auto-instrumenting $package because it is not currently supported");
        return;
    }

    if ( my $instrumentation = $class->for_package($package) ) {
        if ( $options->{-prefer_instrumentations} ) {
            # $LOGGER->trace(
            #     "Not auto-instrumenting $package because $instrumentation is installed in this system. You can ignore this by disabling -prefer_instrumentations"
            # );

            return;
        }

        my $notional = Module::Runtime::module_notional_filename($instrumentation);
        if ( $INC{$notional} ) {
            # $LOGGER->trace(
            #     "Not auto-instrumenting $package because $instrumentation has already been loaded"
            # );
            return;
        }
    }

    $class->wrap_package( $package, $rules, $options );
}

sub wrap_package ( $class, $package, $rules, $options ) {
    # Check the assumed package of the module against each package rule
    for my $pair ( pairs @$rules ) {
        my ( $matcher, $rules ) = @$pair;

        # If this rule does not apply to this package
        # move to the next rule
        next if is_regexpref($matcher)
            ? $package !~ $matcher
            : $package ne $matcher;

        # Since this rule applies to this package,
        # we abort if this rule is 'ignore'
        return unless $rules;

        $class->wrap_subroutines( $package, $rules, $options )
    }
}

sub wrap_subroutines ( $class, $package, $rules, $options ) {
    my $default_rules = [ qr/.*/ => 1 ];

    # Normalise rules
    $rules = $default_rules unless ref $rules;
    $rules = [ %$rules ] if is_hashref $rules;

    my $subs = namespace::clean->get_functions($package);

    # The package rule has matched
    # Loop over the subroutines in the package
    SUB: while ( my ( $subname, $coderef ) = each %$subs ) {
        my $fullname = "${package}::${subname}";

        if ( $subname =~ /^(?:un)?import$/ && $options->{-ignore_import} ) {
            # $LOGGER->trace(
            #     "Not auto-instrumenting $fullname because -ignore_import was set",
            # );
            next;
        }

        if ( uc($subname) eq $subname && $options->{-ignore_constants} ) {
            # $LOGGER->trace(
            #     "Not auto-instrumenting $fullname because -ignore_constants was set",
            # );
            next;
        }

        if ( $subname =~ /^_/ && $options->{-ignore_private} ) {
            # $LOGGER->trace(
            #     "Not auto-instrumenting $fullname because -ignore_private was set",
            # );
            next;
        }

        # Skip imported functions.
        # See https://stackoverflow.com/a/3685262/807650
        if ( my $gv = Devel::Peek::CvGV($coderef) ) {
            if ( *$gv{PACKAGE} ne $package ) {
                # $LOGGER->trace(
                #     "Not auto-instrumenting $fullname because it is imported from a different package"
                # );
                next;
            }
        }

        if ( defined prototype $coderef ) {
            # $LOGGER->trace(
            #     "Not auto-instrumenting $fullname because it has a prototype"
            # );
            next;
        }

        for ( pairs @$rules ) {
            my ( $matcher, $spanner ) = @$_;

            next unless $subname =~ $matcher;
            next SUB unless $spanner;

            # Avoid double-wrapping subs
            if ( $CACHE{$package}{$subname}++ ) {
                # $LOGGER->trace(
                #     "Not auto-instrumenting $fullname because we have already done so"
                # );
                next;
            }

            $LOGGER->info(
                "Adding OpenTelemetry auto-instrumentation for $fullname"
            );

            $spanner = sub {
                my ( $package, $subname, $orig, @args ) = @_;
                OpenTelemetry
                    ->tracer_provider
                    ->tracer( name => $package, version => $package->VERSION )
                    ->in_span(
                        "${package}::${subname}" => sub { $orig->(@args) },
                    );
            } unless is_coderef $spanner;

            install_modifier $package => around => $subname => sub {
                local @_ = ( $package, $subname, @_ );
                goto $spanner;
            };
        }
    }
}

1;
