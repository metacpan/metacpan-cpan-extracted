package Pcore::Util::Src;

use Pcore -const, -res, -ansi, -export;
use Pcore::Util::Scalar qw[is_path is_plain_arrayref is_plain_hashref];
use Pcore::Util::Text qw[encode_utf8 decode_eol lcut_all rcut_all rtrim_multi remove_bom];
use Pcore::Util::Digest qw[md5_hex];

our $EXPORT = {    #
    FILTER_STATUS => [qw[$SRC_OK $SRC_WARN $SRC_ERROR $SRC_FATAL]],
};

const our $STATUS => {
    200 => [ 'OK',             1, $BOLD . $GREEN ],
    201 => [ 'Warn',           1, $BOLD . $YELLOW ],
    202 => [ 'File Ignored',   1, $YELLOW ],
    400 => [ 'Error',          1, $BOLD . $WHITE . $ON_RED ],
    404 => [ 'File Not Found', 1, $BOLD . $RED ],
    500 => [ 'Fatal',          1, $BOLD . $WHITE . $ON_RED ],
    510 => [ 'Params Error',   0, $BOLD . $RED ],
};

const our $SRC_OK    => res [ 200, $STATUS->{200}->[0] ];    # content is OK
const our $SRC_WARN  => res [ 201, $STATUS->{201}->[0] ];    # content has warnings
const our $SRC_ERROR => res [ 400, $STATUS->{400}->[0] ];    # content has errors
const our $SRC_FATAL => res [ 500, $STATUS->{500}->[0] ];    # unable to run filter, runtime error

const our $SRC_FILE_IGNORED   => res [ 202, $STATUS->{202}->[0] ];
const our $SRC_FILE_NOT_FOUND => res [ 404, $STATUS->{404}->[0] ];

const our $SRC_PARAMS_ERROR => res [ 510, $STATUS->{510}->[0] ];

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
                desc => 'define source files to process. Mandatory, if <source> is a directory. Recognized types: ' . join( ', ', supported_types()->@* ),
                isa  => supported_types(),
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
            report_ignored => {
                short   => undef,
                desc    => q[report ignored files],
                default => 1,
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
        $opt->{action}         = 'decompress';
        $opt->{report_ignored} = 0;
        $opt->{type}           = 'perl';
        $opt->{prefix}         = P->path( $opt->{prefix}, from_mswin => 1 )->to_abs;
    }
    else {
        undef $opt->{prefix};
    }

    my $res = P->src->run(
        $opt->{action},
        {   path           => $arg->{path},
            type           => $opt->{type},
            report         => $opt->{report},
            dry_run        => $opt->{dry_run},
            prefix         => $opt->{prefix},
            report_ignored => $opt->{report_ignored},
        }
    );

    exit( $res ? 0 : 3 );
}

sub cfg {
    state $cfg = $ENV->{share}->read_cfg('/Pcore/data/src.yaml');

    return $cfg;
}

sub supported_types {
    my $cfg = cfg();

    return state $types = [ sort keys { map { $cfg->{mime_tag}->{$_}->{type} => 1 } keys $cfg->{mime_tag}->%* }->%* ];
}

sub decompress ( %args ) { return run( 'decompress', \%args ) }

sub compress ( %args ) { return run( 'compress', \%args ) }

sub obfuscate ( %args ) { return run( 'obfuscate', \%args ) }

# path, Scalar, ArrayRef
# data, Str
# type, ArrayRef[ Enum ['css', 'html', 'js', 'json', 'perl']], list of types to process, used if path is directory
# ignore, Bool, ignore unsupported file types
# report_ignored, Bool
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
        return $SRC_FILE_IGNORED if !defined $filter_profile;

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
            return res [ $SRC_PARAMS_ERROR, 'Type must be specified in path is directory' ] if !defined $args->{type};

            # read dir
            for my $path ( ( $path->read_dir( abs => 1, max_depth => 0, is_dir => 0 ) // [] )->@* ) {

                # ignore any file inside "node_modules" dir
                if ( $path =~ m[/node_modules/]sm ) {
                    next;
                }

                # get filter profile
                if ( my $filter_profile = _get_filter_profile( $args, $path ) ) {
                    $tasks{$path} = [ $filter_profile, $path ];
                }
            }
        }

        # path is file
        else {

            # get filter profile
            my $filter_profile = _get_filter_profile( $args, $path );

            # file is ignored
            if ( !$filter_profile ) {
                $tasks{$path} = [ $filter_profile, $path, $SRC_FILE_IGNORED ] if $args->{report} && $args->{report_ignored};
            }
            else {
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

    # process files
    for my $path ( sort keys %tasks ) {
        my $res = $tasks{$path}->[2] // _process_file( $args, $action, $tasks{$path}->@* );

        # update result status
        $total->set_status( [ $res, $STATUS->{ $res->{status} }->[0] ] ) if $res->{status} > $total->{status};

        $total->{data}->{ $res->{status} }++;
        $total->{modified}++ if $res->{is_modified};

        _report_file( \$tbl, $use_prefix ? substr $path, length $prefix : $path, $res, $max_path_len ) if $args->{report};
    }

    print $tbl->finish if defined $tbl;

    _report_total($total) if $args->{report} && keys %tasks;

    return $total;
}

sub _process_file ( $args, $action, $filter_profile, $path = undef, $data = undef ) {
    my $res = res $SRC_OK,
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
            $res->set_status($SRC_FILE_NOT_FOUND);

            return $res;
        }
    }
    else {
        encode_utf8 $data;
    }

    $res->{in_size} = length $data;
    my $in_md5 = md5_hex $data;

    # run filter
    if ( my $filter_type = delete $filter_profile->{type} ) {

        # merge filter args
        $filter_profile->@{ keys $args->{filter}->%* } = values $args->{filter}->%* if defined $args->{filter};

        my $filter_res = P->class->load( $filter_type, ns => 'Pcore::Util::Src::Filter' )->$action( \$data, $path, $filter_profile->%* );

        $res->{status} = $filter_res->{status};
        $res->{reason} = $filter_res->{reason};

        encode_utf8 $data;
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
    $res->{out_size}    = length $data;
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

    # return empty filter profile
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
                    width => 30,
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
    push @row, "$STATUS->{ $res->{status} }->[2] $res->{reason} $RESET";

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
    return if !defined $total || !$total->{data}->%*;

    my $tbl = P->text->table(
        style => 'full',
        cols  => [
            type => {
                width => 20,
                align => 1,
            },
            count => {
                width => 10,
                align => -1,
            },
        ],
    );

    print $tbl->render_header;

    for my $status ( sort grep { $STATUS->{$_}->[1] } keys $STATUS->%* ) {
        print $tbl->render_row( [    #
            "$STATUS->{$status}->[2] $STATUS->{$status}->[0] $RESET",
            "$STATUS->{$status}->[2]  @{[ $total->{data}->{$status} // 0 ]}  $RESET",
        ] );
    }

    print $tbl->render_row( [ 'Modified', $total->{modified} // 0 ] );

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
## |    3 | 183                  | Subroutines::ProhibitExcessComplexity - Subroutine "_process_files" with high complexity score (35)            |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 295, 403             | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
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
