package Pcore::Util::Src::Filter;

use Pcore -role, -res, -const;
use Pcore::Util::Src qw[:FILTER_STATUS];
use Pcore::Util::Sys::Proc qw[:PROC_REDIRECT];

has data      => ( required => 1 );
has path      => ( required => 1 );
has has_kolon => ( is       => 'lazy', init_arg => undef );

around decompress => sub ( $orig, $self, $data, $path = undef, %args ) {
    $self = $self->new( %args, data => $data->$*, path => $path );

    my $res = $self->$orig;

    $data->$* = $self->{data} if $res < $SRC_FATAL;

    return $res;
};

around compress => sub ( $orig, $self, $data, $path = undef, %args ) {
    $self = $self->new( %args, data => $data->$*, path => $path );

    my $res = $self->$orig;

    $data->$* = $self->{data} if $res < $SRC_FATAL;

    return $res;
};

around obfuscate => sub ( $orig, $self, $data, $path = undef, %args ) {
    $self = $self->new( %args, data => $data->$*, path => $path );

    my $res = $self->$orig;

    $data->$* = $self->{data} if $res < $SRC_FATAL;

    return $res;
};

sub _build_has_kolon ($self) {
    return 1 if $self->{data} =~ /<: /sm;

    return 1 if $self->{data} =~ /^: /sm;

    return 0;
}

sub src_cfg ($self) { return Pcore::Util::Src::cfg() }

sub dist_cfg ($self) { return {} }

sub decompress ($self) { return $SRC_OK }

sub compress ($self) { return $SRC_OK }

sub obfuscate ($self) { return $SRC_OK }

sub update_log ( $self, $log = undef ) {return}

sub filter_prettier ( $self, @options ) {
    my $dist_options = $self->dist_cfg->{prettier} || $self->src_cfg->{prettier};

    my $temp = P->file1->tempfile;
    P->file->write_bin( $temp, $self->{data} );

    my $proc = P->sys->run_proc(
        [ 'prettier', $temp, $dist_options->@*, @options, '--no-color', '--no-config', '--loglevel=error' ],
        stdout => $PROC_REDIRECT_FH,
        stderr => $PROC_REDIRECT_FH,
    )->capture;

    # ran without errors
    if ($proc) {
        $self->{data} = $proc->{stdout}->$*;

        $self->update_log;

        return $SRC_OK;
    }

    # run with errors
    else {

        my ( @log, $has_errors, $has_warnings );

        my $temp_filename = $temp->{filename};

        # parse stderr
        if ( $proc->{stderr}->$* ) {
            for my $line ( split /\n/sm, $proc->{stderr}->$* ) {
                if ( $line =~ s/\A\[(.+?)\]\s//sm ) {
                    if    ( $1 eq 'error' ) { $has_errors++ }
                    elsif ( $1 eq 'warn' )  { $has_warnings++ }
                }

                # remove temp filename from log
                $line =~ s[\A.+$temp_filename:\s][]sm;

                push @log, $line;
            }

        }

        # unable to run prettier
        return res [ $SRC_FATAL, $log[0] || $proc->{reason} ] if $proc->{exit_code} == 1;

        # prettier found errors in content
        $self->update_log( join "\n", @log );

        return $has_errors ? $SRC_ERROR : $SRC_WARN;
    }
}

sub filter_eslint ( $self, @options ) {
    my $root;

    if ( $self->{path} ) {
        my $path = P->path( $self->{path} );

        while ( $path = $path->parent ) {
            if ( -f "$path/package.json" ) {
                $root = $path;

                last;
            }
        }
    }

    my $proc;

    # node project was found
    if ($root) {
        $proc = P->sys->run_proc(
            [ 'npx', 'eslint', '--fix-dry-run', @options, '--format=json', '--report-unused-disable-directives', '--stdin', "--stdin-filename=$self->{path}", '--fix-dry-run' ],
            stdin  => \$self->{data},
            stdout => $PROC_REDIRECT_FH,
            stderr => $PROC_REDIRECT_FH,
        )->capture;
    }

    # node project was not found, use default settings
    else {
        state $config = $ENV->{share}->get('/Pcore/data/.eslintrc.yaml');

        $proc = P->sys->run_proc(
            [ 'eslint', '--fix-dry-run', @options, '--format=json', '--report-unused-disable-directives', '--stdin', "--stdin-filename=$self->{path}", "--config=$config", '--no-eslintrc' ],
            stdin  => \$self->{data},
            stdout => $PROC_REDIRECT_FH,
            stderr => $PROC_REDIRECT_FH,
        )->capture;
    }

    # unable to run elsint
    if ( !$proc && !$proc->{stdout}->$* ) {
        my $reason;

        if ( $proc->{stderr}->$* ) {
            my @log = split /\n/sm, $proc->{stderr}->$*;

            $reason = $log[0];
        }

        return res [ $SRC_FATAL, $reason || $proc->{reason} ];
    }

    my $eslint_log = P->data->from_json( $proc->{stdout} );

    $self->{data} = $eslint_log->[0]->{output} if $eslint_log->[0]->{output};

    # eslint reported no violations
    if ( !$eslint_log->[0]->{messages}->@* ) {
        $self->update_log;

        return $SRC_OK;
    }

    my ( $log, $has_warnings, $has_errors );

    # create table
    my $tbl = P->text->table(
        style => 'compact',
        color => 0,
        cols  => [
            severity => {
                title  => 'Sev.',
                width  => 7,
                align  => 1,
                valign => -1,
            },
            pos => {
                title       => 'Line:Col',
                width       => 15,
                title_align => -1,
                align       => -1,
                valign      => -1,
            },
            rule => {
                title       => 'Rule',
                width       => 30,
                title_align => -1,
                align       => -1,
                valign      => -1,
            },
            desc => {
                title       => 'Description',
                width       => 80,
                title_align => -1,
                align       => -1,
                valign      => -1,
            },
        ],
    );

    $log .= $tbl->render_header;

    my @items;

    for my $msg ( sort { $a->{severity} <=> $b->{severity} || $a->{line} <=> $b->{line} || $a->{column} <=> $b->{column} } $eslint_log->[0]->{messages}->@* ) {
        my $severity_text;

        if ( $msg->{severity} == 1 ) {
            $has_warnings++;

            $severity_text = 'WARN';
        }
        else {
            $has_errors++;

            $severity_text = 'ERROR';
        }

        push @items, [ $severity_text, "$msg->{line}:$msg->{column}", $msg->{ruleId}, $msg->{message} ];
    }

    my $row_line = $tbl->render_row_line;

    $log .= join $row_line, map { $tbl->render_row($_) } @items;

    $log .= $tbl->finish;

    $self->update_log($log);

    if    ($has_errors)   { return $SRC_ERROR }
    elsif ($has_warnings) { return $SRC_WARN }
    else                  { return $SRC_OK }
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Src::Filter

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
