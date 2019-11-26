package Pcore::Util::Src;

use Pcore -const, -res, -ansi;
use Pcore::Util::Scalar qw[is_path is_plain_arrayref is_plain_hashref];
use Pcore::Util::Text qw[encode_utf8 decode_eol lcut_all rcut_all rtrim_multi remove_bom];
use Pcore::Util::Digest qw[md5_hex];

const our $STATUS_REASON => {
    200 => 'OK',
    201 => 'Warning',
    202 => 'File skipped',
    404 => 'File not found',
    500 => 'Error',
    510 => 'Params error',
};

const our $STATUS_COLOR => {
    200 => $BOLD . $GREEN,
    201 => $YELLOW,
    404 => $BOLD . $RED,
    500 => $BOLD . $RED,
};

# CLI
sub CLI ($self) {
    return {
        opt => {
            action => {
                desc => <<'TXT',
action to perform:
    decompress   unpack sources, DEFAULT;
    compress     pack sources, comments will be deleted;
    obfuscate    applied only for javascript and embedded javascripts, comments will be deleted;
    commit       SCM commit hook
TXT
                isa     => [ 'decompress', 'compress', 'obfuscate', 'commit' ],
                default => 'decompress',
            },
            type => {
                desc => 'define source files to process. Mandatory, if <source> is a directory. Recognized types: perl, html, css, js, json',
                isa  => [qw[perl html css js json]],
                max  => 0,
            },
            report => {
                short   => undef,
                desc    => 'print report',
                default => 1,
            },
            dry_run => {
                short   => undef,
                desc    => q[don't save changes],
                default => 0,
            },
            prefix => {
                short => undef,
                isa   => 'Str',
                desc  => q[for internal use with commit hook],
                max   => 1,
            },
        },
        arg => [
            path => {
                type => 'Path',
                desc => 'path for processing, special value "-" for read paths from stdin',
                min  => 1,
                max  => 0,
            }
        ],
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    if ( $arg->{path}->[0] eq '-' ) {
        $arg->{path} = P->file->read_lines(*STDIN);

        for ( $arg->{path}->@* ) { $_ = P->path( $_, from_mswin => 1 )->to_abs }
    }

    if ( $opt->{action} eq 'commit' ) {
        $opt->{action} = 'decompress';
        $opt->{type}   = 'perl';
        $opt->{prefix} = P->path( $opt->{prefix}, from_mswin => 1 )->to_abs;
    }
    else {
        undef $opt->{prefix};
    }

    my $res = P->src->run(
        $opt->{action},
        {   path    => $arg->{path},
            type    => $opt->{type},
            report  => $opt->{report},
            dry_run => $opt->{dry_run},
            prefix  => $opt->{prefix},
        }
    );

    exit( $res ? 0 : 3 );
}

sub cfg {
    state $cfg = $ENV->{share}->read_cfg('/Pcore/data/src.yaml');

    return $cfg;
}

sub decompress ( %args ) { return run( 'decompress', \%args ) }

sub compress ( %args ) { return run( 'compress', \%args ) }

sub obfuscate ( %args ) { return run( 'obfuscate', \%args ) }

# path, Scalar, ArrayRef
# data, Str
# type, ArrayRef[ Enum ['css', 'html', 'js', 'json', 'perl']], list of types to process, used if path is directory
# ignore, Bool, ignore unsupported file types
# filter, HashRef, additional filter arguments
# dry_run, Bool, if true - do not write results to the source path
# report, print report
# prefix, common paths prefix
sub run ( $action, $args ) {
    $args->{ignore} //= 1;

    # convert type to HashRef
    if ( defined $args->{type} && !is_plain_hashref $args->{type} ) {
        if ( is_plain_arrayref $args->{type} ) {
            $args->{type} = { map { $_ => undef } $args->{type}->@* };
        }
        else {
            $args->{type} = { $args->{type} => undef };
        }
    }

    my $res;

    # file content is provided
    if ( defined $args->{data} ) {

        # convert path
        my $path = $args->{path};
        $path = P->path($path) if !is_path $path;

        # get filter profile
        my $filter_profile = _get_filter_profile( $args, $path, $args->{data} );

        # ignore file
        return res [ 202, $STATUS_REASON ] if !defined $filter_profile;

        # process file
        $res = _process_file( $args, $action, $filter_profile, $path, $args->{data} );
    }

    # file content is not provided
    else {
        $res = _process_files( $args, $action );
    }

    return $res;
}

sub _process_files ( $args, $action ) {
    my $total = res 200;

    my %tasks;

    # build absolute paths list
    for my $path ( is_plain_arrayref $args->{path} ? $args->{path}->@* : $args->{path} ) {
        next if !defined $path;

        # convert path
        $path = P->path($path) if !is_path $path;
        $path->to_abs;

        # path is directory
        if ( -d $path ) {
            return res [ 510, 'Type must be specified in path is directory' ] if !defined $args->{type};

            # read dir
            for my $path ( ( $path->read_dir( abs => 1, max_depth => 0, is_dir => 0 ) // [] )->@* ) {

                # get filter profile
                if ( my $filter_profile = _get_filter_profile( $args, $path ) ) {
                    $tasks{$path} = [ $filter_profile, $path ];
                }
            }
        }

        # path is file
        else {

            # get filter profile
            if ( my $filter_profile = _get_filter_profile( $args, $path ) ) {
                $tasks{$path} = [ $filter_profile, $path ];
            }
        }
    }

    my ( $prefix, $use_prefix );
    my $max_path_len = 0;

    if ( $args->{report} ) {

        # use predefined prefix
        if ( defined $args->{prefix} ) {
            $prefix     = is_path $args->{prefix} ? $args->{prefix} : P->path( $args->{prefix} );
            $prefix     = "$prefix/";
            $use_prefix = 1;

            for my $task ( values %tasks ) {
                $max_path_len = length $task->[1] if length $task->[1] > $max_path_len;
            }
        }

        # find longest common prefix
        else {
            for my $task ( values %tasks ) {
                my $dirname = "$task->[1]->{dirname}/";

                if ( !defined $prefix ) {
                    $prefix = $dirname;

                    $max_path_len = length $task->[1];
                }
                else {
                    $max_path_len = length $task->[1] if length $task->[1] > $max_path_len;

                    if ( "$prefix\x00$dirname" =~ /^(.*).*\x00\1.*$/sm ) {
                        $prefix = $1;

                        $use_prefix = 1;
                    }
                }
            }
        }

        # find max. path length
        $max_path_len -= length $prefix if $use_prefix;
    }

    my $tbl;

    for my $path ( sort keys %tasks ) {
        my $res = _process_file( $args, $action, $tasks{$path}->@* );

        if ( $res != 202 ) {
            if ( $res->{status} > $total->{status} ) {
                $total->{status} = $res->{status};
                $total->{reason} = $STATUS_REASON->{ $total->{status} };
            }

            $total->{ $res->{status} }++;
            $total->{modified}++ if $res->{is_modified};

            _report_file( \$tbl, $use_prefix ? substr $path, length $prefix : $path, $res, $max_path_len ) if $args->{report};
        }
    }

    print $tbl->finish if defined $tbl;

    _report_total($total) if $args->{report} && keys %tasks;

    return $total;
}

sub _process_file ( $args, $action, $filter_profile, $path = undef, $data = undef ) {
    my $res = res [ 200, $STATUS_REASON ],
      is_modified => 0,
      in_size     => 0,
      out_size    => 0,
      size_delta  => 0;

    my $write_data;

    # read file
    if ( !defined $data ) {
        if ( defined $path && -f $path ) {
            $data = P->file->read_bin( $path->encoded );

            $write_data = 1;
        }

        # file not found
        else {
            $res->{status} = 404;
            $res->{reason} = $STATUS_REASON->{404};
            return $res;
        }
    }
    else {
        encode_utf8 $data;
    }

    $res->{in_size} = bytes::length $data;
    my $in_md5 = md5_hex $data;

    # run filter
    if ( my $filter_type = delete $filter_profile->{type} ) {

        # merge filter args
        $filter_profile->@{ keys $args->{filter}->%* } = values $args->{filter}->%* if defined $args->{filter};

        my $filter_res = P->class->load( $filter_type, ns => 'Pcore::Util::Src::Filter' )->new( $filter_profile->%*, data => \$data, )->$action;

        $res->{status} = $filter_res->{status};
        $res->{reason} = $filter_res->{reason};
    }

    # trim
    if ( $action eq 'decompress' ) {
        decode_eol $data;    # decode "\r\n" to internal "\n" representation

        lcut_all $data;      # trim leading horizontal whitespaces

        rcut_all $data;      # trim trailing horizontal whitespaces

        rtrim_multi $data;   # right trim each line

        $data =~ s/\t/    /smg;    # convert tabs to spaces

        $data .= "\n";
    }

    my $out_md5 = md5_hex $data;
    $res->{is_modified} = $in_md5 ne $out_md5;
    $res->{out_size}    = bytes::length $data;
    $res->{size_delta}  = $res->{out_size} - $res->{in_size};

    # write file
    if ($write_data) {
        if ( $res->{is_modified} && !$args->{dry_run} ) { P->file->write_bin( $path->encoded, $data ) }
    }
    else {
        $res->{data} = $data;
    }

    return $res;
}

sub _get_filter_profile ( $args, $path, $data = undef ) {
    my $cfg = cfg();

    my $filter_profile;

    my $path_mime_tags = $path->mime_tags( defined $data ? \$data : 1 );

    for ( keys $cfg->{mime_tag}->%* ) { $filter_profile = $cfg->{mime_tag}->{$_} and last if exists $path_mime_tags->{$_} }

    # file type is known
    if ( defined $filter_profile ) {

        # file is filtered by the type filter and in ignore mode
        if ( defined $args->{type} && !exists $args->{type}->{ $filter_profile->{type} } && $args->{ignore} ) {
            return;
        }
        else {
            return { $filter_profile->%* };
        }
    }

    # filte type is unknown and in ignore mode
    elsif ( $args->{ignore} ) {
        return;
    }
    else {
        return {};
    }
}

sub _report_file ( $tbl, $path, $res, $max_path_len ) {
    if ( !defined $tbl->$* ) {
        $tbl->$* = P->text->table(
            style    => 'compact',
            top_line => 1,
            cols     => [
                path => {
                    width => $max_path_len + 2,
                    align => -1,
                },
                severity => {
                    width => 24,
                    align => 1,
                },
                size => {
                    width => 10,
                    align => 1,
                },
                size_delta => {
                    title => 'SIZE DELTA',
                    width => 12,
                    align => 1,
                },
                modified => {
                    width => 12,
                    align => 1,
                },
            ],
        );

        print $tbl->$*->render_header;
    }

    my @row;

    # path
    push @row, $path;

    # severity
    push @row, $STATUS_COLOR->{ $res->{status} } . uc( $res->{reason} ) . $RESET;

    # size
    push @row, $res->{out_size};

    # size delta
    if ( !$res->{size_delta} ) {
        push @row, ' - ';
    }
    elsif ( $res->{size_delta} > 0 ) {
        push @row, $BOLD . $RED . "+$res->{size_delta}" . $RESET;
    }
    else {
        push @row, $BOLD . $GREEN . "$res->{size_delta}" . $RESET;
    }

    # modified
    push @row, ( $res->{is_modified} ? $BOLD . $WHITE . $ON_RED . ' modified ' . $RESET : ' - ' );

    print $tbl->$*->render_row( \@row );

    return;
}

sub _report_total ( $total ) {
    return if !defined $total;

    my $tbl = P->text->table(
        style => 'full',
        cols  => [
            type => {
                width => 16,
                align => 1,
            },
            count => {
                width => 10,
                align => -1,
            },
        ],
    );

    print $tbl->render_header;

    for my $status ( 200, 201, 500, 404 ) {
        print $tbl->render_row( [ $STATUS_COLOR->{$status} . uc( $STATUS_REASON->{$status} ) . $RESET, $STATUS_COLOR->{$status} . ( $total->{$status} // 0 ) . $RESET ] );
    }

    print $tbl->render_row( [ 'MODIFIED', $total->{modified} // 0 ] );

    print $tbl->finish;

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 161                  | Subroutines::ProhibitExcessComplexity - Subroutine "_process_files" with high complexity score (32)            |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 265, 369             | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 302                  | ValuesAndExpressions::ProhibitLongChainsOfMethodCalls - Found method-call chain of length 4                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Src

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
