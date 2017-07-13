package Pcore::Util::UUID;

use Pcore -export => { ALL => [qw[looks_like_uuid uuid_bin uuid_str uuid_hex create_uuid create_uuid_from_bin create_uuid_from_str create_uuid_from_hex]] };
use Pcore::Util::UUID::Obj;
use Data::UUID qw[];    ## no critic qw[Modules::ProhibitEvilModules]

our $UUID = Data::UUID->new;

*create_uuid          = \&create;
*create_uuid_from_bin = \&create_from_bin;
*create_uuid_from_str = \&create_from_str;
*create_uuid_from_hex = \&create_from_hex;

*uuid_bin = \&bin;
*uuid_str = \&str;
*uuid_hex = \&hex;

sub looks_like_uuid ($str) : prototype($) {
    return $str =~ /\A[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}\z/sm;
}

sub create {
    return bless { bin => $UUID->create_bin }, 'Pcore::Util::UUID::Obj';
}

sub create_from_bin ($bin) : prototype($) {
    return bless { bin => $bin }, 'Pcore::Util::UUID::Obj';
}

sub create_from_str ($str) : prototype($) {
    return bless { str => $str }, 'Pcore::Util::UUID::Obj';
}

sub create_from_hex ($hex) : prototype($) {
    return bless { hex => $hex }, 'Pcore::Util::UUID::Obj';
}

sub bin {
    return $UUID->create_bin;
}

sub str {
    return lc $UUID->create_str;
}

sub hex {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    return lc $UUID->create_hex;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 19                   | RegularExpressions::ProhibitComplexRegexes - Split long regexps into smaller qr// chunks                       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::UUID - Data::UUID wrapper

=head1 SYNOPSIS

    P->uuid->str;
    P->uuid->bin;
    P->uuid->hex;

=head1 DESCRIPTION

This is Data::UUID wrapper to use with Pcore::Util interafce.

=head1 SEE ALSO

L<Data::UUID|https://metacpan.org/pod/Data::UUID>

=cut
