#line 1
package Package::DeprecationManager;
BEGIN {
  $Package::DeprecationManager::VERSION = '0.11';
}

use strict;
use warnings;

use Carp qw( croak );
use List::MoreUtils qw( any );
use Params::Util qw( _HASH0 );
use Sub::Install;

sub import {
    shift;
    my %args = @_;

    croak
        'You must provide a hash reference -deprecations parameter when importing Package::DeprecationManager'
        unless $args{-deprecations} && _HASH0( $args{-deprecations} );

    my %registry;

    my $import = _build_import( \%registry );
    my $warn = _build_warn( \%registry, $args{-deprecations}, $args{-ignore} );

    my $caller = caller();

    Sub::Install::install_sub(
        {
            code => $import,
            into => $caller,
            as   => 'import',
        }
    );

    Sub::Install::install_sub(
        {
            code => $warn,
            into => $caller,
            as   => 'deprecated',
        }
    );

    return;
}

sub _build_import {
    my $registry = shift;

    return sub {
        my $class = shift;
        my %args  = @_;

        $args{-api_version} ||= delete $args{-compatible};

        $registry->{ caller() } = $args{-api_version}
            if $args{-api_version};

        return;
    };
}

sub _build_warn {
    my $registry      = shift;
    my $deprecated_at = shift;
    my $ignore        = shift;

    my %ignore = map { $_ => 1 } grep { !ref } @{ $ignore || [] };
    my @ignore_res = grep {ref} @{ $ignore || [] };

    my %warned;

    return sub {
        my %args = @_ < 2 ? ( message => shift ) : @_;

        my ( $package, undef, undef, $sub ) = caller(1);

        my $skipped = 1;

        if ( @ignore_res || keys %ignore ) {
            while ( defined $package
                && ( $ignore{$package} || any { $package =~ $_ } @ignore_res )
                ) {
                $package = caller( $skipped++ );
            }
        }

        $package = 'unknown package' unless defined $package;

        unless ( defined $args{feature} ) {
            $args{feature} = $sub;
        }

        my $compat_version = $registry->{$package};

        my $deprecated_at = $deprecated_at->{ $args{feature} };

        return
            if defined $compat_version
                && defined $deprecated_at
                && $compat_version lt $deprecated_at;

        my $msg;
        if ( defined $args{message} ) {
            $msg = $args{message};
        }
        else {
            $msg = "$args{feature} has been deprecated";
            $msg .= " since version $deprecated_at"
                if defined $deprecated_at;
        }

        return if $warned{$package}{ $args{feature} }{$msg};

        $warned{$package}{ $args{feature} }{$msg} = 1;

        # We skip at least two levels. One for this anon sub, and one for the
        # sub calling it.
        local $Carp::CarpLevel = $Carp::CarpLevel + $skipped;

        Carp::cluck($msg);
    };
}

1;

# ABSTRACT: Manage deprecation warnings for your distribution



#line 272


__END__

