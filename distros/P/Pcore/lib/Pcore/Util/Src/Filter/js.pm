package Pcore::Util::Src::Filter::js;

use Pcore -class, -res;
use Pcore::Util::Src qw[:FILTER_STATUS];
use Pcore::Util::Text qw[rcut_all encode_utf8];
use Pcore::Util::Sys::Proc qw[:PROC_REDIRECT];

with qw[Pcore::Util::Src::Filter];

sub decompress ( $self ) {
    return $self->filter_eslint;
}

sub compress ($self) {
    my $options = $self->dist_cfg->{terser_compress} || $self->src_cfg->{terser_compress};

    return $self->filter_terser( $options->@* );
}

sub obfuscate ($self) {
    my $options = $self->dist_cfg->{terser_obfuscate} || $self->src_cfg->{terser_obfuscate};

    return $self->filter_terser( $options->@* );
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

sub filter_terser ( $self, @options ) {
    my $temp = P->file1->tempfile( suffix1 => 'js' );

    P->file->write_bin( $temp, $self->{data} );

    my $proc = P->sys->run_proc(
        [ 'terser', $temp, @options ],
        stdout => $PROC_REDIRECT_FH,
        stderr => $PROC_REDIRECT_FH,
    )->capture;

    if ( !$proc ) {
        my $reason;

        if ( $proc->{stderr} ) {
            my @log = split /\n/sm, $proc->{stderr}->$*;

            $reason = $log[0];
        }

        return res [ $SRC_FATAL, $reason || $proc->{reason} ];
    }

    $self->{data} = $proc->{stdout}->$*;

    return $SRC_OK;
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
