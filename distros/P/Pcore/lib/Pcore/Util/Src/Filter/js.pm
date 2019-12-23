package Pcore::Util::Src::Filter::js;

use Pcore -class, -res;
use Pcore::Util::Src qw[:FILTER_STATUS];
use Pcore::Util::Text qw[rcut_all encode_utf8];
use Pcore::Util::Sys::Proc qw[:PROC_REDIRECT];

with qw[Pcore::Util::Src::Filter];

sub decompress ( $self ) {
    my $res = $self->filter_prettier( parser => 'babel' );

    return $res if !$res;

    return $self->filter_eslint;
}

sub compress ($self) {
    return $self->filter_terser( compress => \1, mangle => \0 );
}

sub obfuscate ($self) {
    return $self->filter_terser( compress => \1, mangle => \1 );
}

sub update_log ( $self, $log = undef ) {

    # clear log
    $self->{data} =~ s[// -----SOURCE FILTER LOG BEGIN-----.*-----SOURCE FILTER LOG END-----][]sm;

    rcut_all $self->{data};

    # insert log
    if ($log) {
        encode_utf8 $log;

        $self->{data} .= qq[\n// -----SOURCE FILTER LOG BEGIN-----\n//\n];

        $self->{data} .= $log =~ s[^][// ]smgr;

        $self->{data} .= qq[//\n// -----SOURCE FILTER LOG END-----];
    }

    return;
}

sub filer_js_packer ( $self, $obfuscate = undef ) {
    state $packer = do {
        require JavaScript::Packer;

        JavaScript::Packer->init;
    };

    $packer->minify( \$self->{data}, { compress => $obfuscate ? 'obfuscate' : 'clean' } );

    return $SRC_OK;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 29                   | RegularExpressions::ProhibitComplexRegexes - Split long regexps into smaller qr// chunks                       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Src::Filter::js

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
