package Pcore::Lib::Src::Filter::js;

use Pcore -class, -res;
use Pcore::Lib::Text qw[rcut_all encode_utf8];

with qw[Pcore::Lib::Src::Filter];

has jshint => 1;    # use jshint on decompress

my $JS_PACKER;

sub decompress ($self) {
    require JavaScript::Beautifier;

    $self->{data}->$* = JavaScript::Beautifier::js_beautify(
        $self->{data}->$*,
        {   indent_size               => 4,
            indent_character          => $SPACE,
            preserve_newlines         => 1,
            space_after_anon_function => 1,
        }
    );

    my $log;

    my $jshint_output;

    if ( $self->{jshint} && length $self->{data}->$* ) {

        $jshint_output = $self->_run_jshint;

        # $jshint_output = $self->_run_eslint;

        if ( $jshint_output->{data}->@* ) {
            for my $rec ( $jshint_output->{data}->@* ) {
                $log .= qq[ * $rec->{code}, line: $rec->{line}, col: $rec->{col}, $rec->{msg}\n];
            }
        }
    }

    $self->_append_log($log);

    if ( $self->{jshint} ) {
        if ( $jshint_output->{has_errors} ) {
            return res [ 500, 'Error, jshint' ];
        }
        elsif ( $jshint_output->{has_warns} ) {
            return res [ 201, 'Warning, jshint' ];
        }
    }

    return res 200;
}

sub compress ($self) {
    require JavaScript::Packer;

    $JS_PACKER //= JavaScript::Packer->init;

    $JS_PACKER->minify( $self->{data}, { compress => 'clean' } );

    return res 200;
}

sub obfuscate ($self) {
    require JavaScript::Packer;

    $JS_PACKER //= JavaScript::Packer->init;

    $JS_PACKER->minify( $self->{data}, { compress => 'obfuscate' } );

    return res 200;
}

sub _append_log ( $self, $log ) {
    $self->_cut_log;

    if ($log) {
        encode_utf8 $log;

        $self->{data}->$* .= qq[\n/* -----SOURCE FILTER LOG BEGIN-----\n *\n];

        $self->{data}->$* .= $log;

        $self->{data}->$* .= qq[ *\n * -----SOURCE FILTER LOG END----- */];
    }

    return;
}

sub _cut_log ($self) {
    $self->{data}->$* =~ s[/[*] -----SOURCE FILTER LOG BEGIN-----.*-----SOURCE FILTER LOG END----- [*]/\n*][]sm;

    rcut_all $self->{data}->$*;

    return;
}

sub _run_jshint ($self) {
    my $jshint_output = [];

    my $jshint_args = $self->dist_cfg->{jshint} || $self->src_cfg->{jshint};

    my $in_temp = P->file1->tempfile;

    P->file->write_bin( $in_temp, $self->{data} );

    my $out_temp = "$ENV->{TEMP_DIR}/tmp-jshint-" . int rand 99_999;

    my $proc = P->sys->run_proc( qq[jshint $jshint_args "$in_temp" > "$out_temp"], win32_create_no_window => 1 )->wait;

    $jshint_output = P->file->read_lines($out_temp);

    unlink $out_temp;    ## no critic qw[InputOutput::RequireCheckedSyscalls]

    my $res = {
        has_errors => 0,
        has_warns  => 0,
        data       => [],
    };

    for my $line ( $jshint_output->@* ) {
        next unless $line =~ s/^.+?: line/line/smg;

        my $descriptor = { raw => $line };

        ( $descriptor->{line}, $descriptor->{col}, $descriptor->{msg}, $descriptor->{code} ) = $line =~ /line (\d+), col (\d+|undefined), (.+)? [(]([WE]\d+)[)]/sm;

        if ( index( $descriptor->{code}, 'E', 0 ) == 0 ) {
            $descriptor->{is_error} = 1;

            $res->{has_errors}++;
        }
        else {
            $descriptor->{is_warn} = 1;

            $res->{has_warns}++;
        }

        push $res->{data}->@*, $descriptor;
    }

    return $res;
}

sub _run_eslint ($self) {

    # my $jshint_args = $self->dist_cfg->{jshint} || $self->src_cfg->{jshint};

    my $in_temp = P->file1->tempfile;

    P->file->write_bin( $in_temp, $self->{data} );

    my $out_temp = "$ENV->{TEMP_DIR}/tmp-jshint-@{[ int rand 99_999 ]}.json";

    my $config = '/var/local/pcore-lib/arbitrator/data/cdn/app/09bc0f7872d3f6ddeae90acd113c0cab/.eslintrc.yaml';

    my $proc = P->sys->run_proc( qq[eslint --format json --config "$config" -o "$out_temp" "$in_temp"], win32_create_no_window => 1 )->wait;

    my $jshint_output = P->cfg->read($out_temp);

    say dump $jshint_output;

    unlink $out_temp;    ## no critic qw[InputOutput::RequireCheckedSyscalls]

    my $res = {
        has_errors => 0,
        has_warns  => 0,
        data       => [],
    };

    return $res;

    # for my $line ( $jshint_output->@* ) {
    #     next unless $line =~ s/^.+?: line/line/smg;

    #     my $descriptor = { raw => $line };

    #     ( $descriptor->{line}, $descriptor->{col}, $descriptor->{msg}, $descriptor->{code} ) = $line =~ /line (\d+), col (\d+|undefined), (.+)? [(]([WE]\d+)[)]/sm;

    #     if ( index( $descriptor->{code}, 'E', 0 ) == 0 ) {
    #         $descriptor->{is_error} = 1;

    #         $res->{has_errors}++;
    #     }
    #     else {
    #         $descriptor->{is_warn} = 1;

    #         $res->{has_warns}++;
    #     }

    #     push $res->{data}->@*, $descriptor;
    # }

    # return $res;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 92                   | RegularExpressions::ProhibitComplexRegexes - Split long regexps into smaller qr// chunks                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 146                  | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_run_eslint' declared but not used  |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::Src::Filter::js

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
