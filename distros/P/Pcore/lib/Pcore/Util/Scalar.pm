package Pcore::Util::Scalar;

use Pcore -export;
use Scalar::Util qw[blessed dualvar isdual readonly refaddr reftype tainted weaken isweak isvstring looks_like_number set_prototype];    ## no critic qw[Modules::ProhibitEvilModules]
use Devel::Refcount qw[refcount];
use Ref::Util qw[:all];

our $EXPORT = {
    ALL    => [qw[looks_like_uuid]],
    SCALAR => [qw[blessed refaddr reftype weaken isweak looks_like_number tainted refcount is_glob]],
    REF    => [qw[is_ref is_scalarref is_arrayref is_hashref is_coderef is_regexpref is_globref is_formatref is_ioref is_refref is_plain_ref is_plain_scalarref is_plain_arrayref is_plain_hashref is_plain_coderef is_plain_globref is_plain_formatref is_plain_refref is_blessed_ref is_blessed_scalarref is_blessed_arrayref is_blessed_hashref is_blessed_coderef is_blessed_globref is_blessed_formatref is_blessed_refref ]],
    TYPE   => [qw[is_bool is_path is_uri is_res]],
};

sub looks_like_uuid : prototype($) ($str) {
    return $str =~ /\A[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}\z/sm;
}

sub is_glob : prototype($) {

    # return is_blessed_ref $_[0] && ( $_[0]->isa('GLOB') || $_[0]->isa('IO') );

    if ( !is_ref $_[0] ) {
        return is_globref \$_[0];
    }
    else {
        return is_blessed_globref $_[0] || is_globref $_[0] || is_ioref $_[0];
    }
}

sub on_destroy ( $scalar, $cb ) {
    require Variable::Magic;

    Variable::Magic::cast( $_[0], Variable::Magic::wizard( free => $cb ) );

    return;
}

sub is_bool : prototype($) {
    return ( is_ref $_[0] && UNIVERSAL::isa( $_[0], JSON::PP::Boolean:: ) ) || ( exists $INC{'Types/Serialiser.pm'} && Types::Serialiser::is_bool( $_[0] ) );
}

sub is_path : prototype($) { return is_blessed_hashref $_[0] && $_[0]->isa('Pcore::Util::Path') }

sub is_uri : prototype($) { return is_blessed_hashref $_[0] && $_[0]->can('IS_PCORE_URI') }

sub is_res : prototype($) { return is_blessed_hashref $_[0] && $_[0]->can('IS_PCORE_RESULT') }

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 16                   | RegularExpressions::ProhibitComplexRegexes - Split long regexps into smaller qr// chunks                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 40                   | BuiltinFunctions::ProhibitUniversalIsa - UNIVERSAL::isa should not be used as a function                       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Scalar

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
