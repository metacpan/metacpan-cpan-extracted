package Pcore::Util::Src::Filter::vue;

use Pcore -class, -res;
use Pcore::Util::Src qw[:FILTER_STATUS];
use Pcore::Util::Text qw[rcut_all encode_utf8];

with qw[Pcore::Util::Src::Filter];

sub decompress ($self) {
    my $res = $self->filter_prettier( parser => 'vue' );

    return $res if !$res;

    return $self->filter_eslint;
}

sub update_log ( $self, $log = undef ) {

    # clear log
    $self->{data} =~ s[<!-- -----SOURCE FILTER LOG BEGIN-----.*-----SOURCE FILTER LOG END----- -->][]sm;

    rcut_all $self->{data};

    # insert log
    if ($log) {
        encode_utf8 $log;

        $log =~ s[-->][---]smg;
        $log =~ s[^][<!-- ]smg;
        $log =~ s[\n][ -->\n]smg;

        $self->{data} .= "\n<!-- -----SOURCE FILTER LOG BEGIN----- -->";
        $self->{data} .= "\n<!-- -->\n";
        $self->{data} .= $log;
        $self->{data} .= "<!-- -->";
        $self->{data} .= "\n<!-- -----SOURCE FILTER LOG END----- -->";
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 20                   | RegularExpressions::ProhibitComplexRegexes - Split long regexps into smaller qr// chunks                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 35                   | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Src::Filter::vue

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
