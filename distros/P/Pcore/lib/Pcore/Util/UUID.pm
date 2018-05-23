package Pcore::Util::UUID;

use Pcore -export;
use Pcore::Util::UUID::Obj;
use Data::UUID qw[];        ## no critic qw[Modules::ProhibitEvilModules]
use Data::UUID::MT qw[];    ## no critic qw[Modules::ProhibitEvilModules]

our $EXPORT = {
    ALL    => [qw[looks_like_uuid]],
    CREATE => [qw[uuid_v1mc uuid_v4 uuid_from_bin uuid_from_str uuid_from_hex]],
    V1MC   => [qw[uuid_v1mc uuid_v1mc_bin uuid_v1mc_str uuid_v1mc_hex]],
    V4     => [qw[uuid_v4 uuid_v4_bin uuid_v4_str uuid_v4_hex]],
};

sub looks_like_uuid ($str) : prototype($) {
    return $str =~ /\A[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}\z/sm;
}

# UUID v1mc
my $UUID_V1 = Data::UUID->new;

*uuid_v1mc     = \&v1mc;
*uuid_v1mc_bin = \&v1mc_bin;
*uuid_v1mc_str = \&v1mc_str;
*uuid_v1mc_hex = \&v1mc_hex;

sub v1mc : prototype() {
    return bless { bin => v1mc_bin() }, 'Pcore::Util::UUID::Obj';
}

sub v1mc_bin : prototype() {
    return $UUID_V1->create_bin;
}

sub v1mc_str : prototype() {
    return lc $UUID_V1->create_str;
}

sub v1mc_hex : prototype() {
    return lc $UUID_V1->create_hex;
}

# UUID v4
my $UUID_V4 = Data::UUID::MT->new( version => 4 )->iterator;

*uuid_v4     = \&v4;
*uuid_v4_bin = \&v4_bin;
*uuid_v4_str = \&v4_str;
*uuid_v4_hex = \&v4_hex;

sub v4 : prototype() {
    return bless { bin => $UUID_V4->() }, 'Pcore::Util::UUID::Obj';
}

sub v4_bin {
    return $UUID_V4->();
}

sub v4_str {
    return join '-', unpack 'H8H4H4H4H12', $UUID_V4->();
}

sub v4_hex : prototype() {
    return unpack 'h*', $UUID_V4->();
}

# OBJECT
*uuid_from_bin = \&from_bin;
*uuid_from_str = \&from_str;
*uuid_from_hex = \&from_hex;

sub from_bin ($bin) : prototype($) {
    return bless { bin => $bin }, 'Pcore::Util::UUID::Obj';
}

sub from_str ($str) : prototype($) {
    return bless { str => $str }, 'Pcore::Util::UUID::Obj';
}

sub from_hex ($hex) : prototype($) {
    return bless { hex => $hex }, 'Pcore::Util::UUID::Obj';
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 16                   | RegularExpressions::ProhibitComplexRegexes - Split long regexps into smaller qr// chunks                       |
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
