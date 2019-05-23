package Pcore::Util::Src::Filter::perl;

use Pcore -class, -const, -res, -sql;
use Pcore::Util::Text qw[decode_utf8 encode_utf8 rcut_all trim];
use Clone qw[];

with qw[Pcore::Util::Src::Filter];

# decompress
has perl_verbose => 0;     # verbose perltidy, perlcritic output
has perl_tidy    => ();    # additional perltidy params
has perl_critic  => 0;     # perlcritic profile, 1 - detect

# compress
has perl_compress             => 0;    # 0 - Perl::Stripper, 1 - Perl::Strip
has perl_compress_end_section => 0;    # preserve __END__ section
has perl_compress_keep_ln     => 1;
has perl_strip_ws             => 1;
has perl_strip_comment        => 1;
has perl_strip_pod            => 1;

const our $PERLCRITIC_ERROR => 4;
const our $SEVERITY         => {

    # valid
    0 => 200,

    # warning
    1 => [ 201, 'Warning, perlcritic(1)' ],
    2 => [ 201, 'Warning, perlcritic(2)' ],
    3 => [ 201, 'Warning, perlcritic(3)' ],

    # error
    4        => [ 500, 'Error, perlcritic(4)' ],
    5        => [ 500, 'Error, perlcritic(5)' ],
    perltidy => [ 500, 'Error, perltidy' ],
};

sub decompress ( $self ) {
    my $err = $EMPTY;
    my $log = $EMPTY;

    # format heredocs
    $self->_format_heredoc;

    state $init = do {

        # redefine $Coro::State::DIEHOOK, required under MSWin to handle Time::HiRes::utime import
        local $SIG{__DIE__} = undef;

        !!require Perl::Tidy;
    };

    my $perltidy_argv = $self->src_cfg->{perltidy};

    $perltidy_argv .= $EMPTY . $self->dist_cfg->{perltidy} if $self->dist_cfg->{perltidy};

    $perltidy_argv .= " $self->{perl_tidy}" if $self->{perl_tidy};

    $perltidy_argv .= ' --logfile-gap=50' if $self->{perl_verbose};

    # temporary conver source to the utf8
    # https://rt.cpan.org/Public/Bug/Display.html?id=32905
    # decode_utf8 $self->{data}->$*;

    Perl::Tidy::perltidy(
        source      => $self->{data},
        destination => $self->{data},
        stderr      => \$err,
        errorfile   => \$err,
        logfile     => \$log,            # for verbose output only
        argv        => $perltidy_argv,
    );

    # convert source back to raw
    encode_utf8 $self->{data}->$*;

    my $error_log;

    my $res;

    # perltidy error
    if ($err) {
        $res = res $SEVERITY->{perltidy};

        $error_log = "PerlTidy:\n$err";

        $error_log .= "\n$log" if $self->{perl_verbose};
    }

    # perltidy ok, run perlcritic, if enabled
    elsif ( my $perl_critic_profile_name = $self->_get_perlcritic_profile_name( $self->{perl_critic} ) ) {
        require Perl::Critic;

        my @violations = eval { $self->_get_perlcritic_object($perl_critic_profile_name)->critique( $self->{data} ) };

        # perlcritic exception
        if ($@) {
            $res = res $SEVERITY->{5};
        }

        # index violations
        elsif (@violations) {
            my $violations;
            my $max_severity = 0;

            for my $v (@violations) {
                my $policy = $v->policy =~ s/\APerl::Critic::Policy:://smr;

                my $desc_md5 = P->digest->md5_hex( $v->description );

                if ( $violations->{$policy} ) {
                    $violations->{$policy}->{line}->{ $v->line_number }++;

                    $violations->{$policy}->{first_line} = $v->line_number if $violations->{$policy}->{first_line} > $v->line_number;

                    if ( $violations->{$policy}->{desc}->{$desc_md5} ) {
                        push $violations->{$policy}->{desc}->{$desc_md5}->{line}->@*, $v->line_number;
                    }
                    else {
                        $violations->{$policy}->{desc}->{$desc_md5} = {
                            text => $v->description,
                            line => [ $v->line_number ],
                        };
                    }
                }
                else {
                    $max_severity = $v->severity if $v->severity > $max_severity;
                    $violations->{$policy}->{severity} = $v->severity;
                    $violations->{$policy}->{desc}->{$desc_md5} = {
                        text => $v->description,
                        line => [ $v->line_number ],
                    };
                    $violations->{$policy}->{diag} = $v->diagnostics;
                    $violations->{$policy}->{line}->{ $v->line_number }++;
                    $violations->{$policy}->{first_line} = $v->line_number;
                }
            }

            # create table
            my $tbl = P->text->table(
                style => 'compact',
                color => 0,
                cols  => [
                    severity => {
                        title  => 'Sev.',
                        width  => 6,
                        align  => 1,
                        valign => -1,
                    },
                    lines => {
                        title       => 'Lines',
                        width       => 22,
                        title_align => -1,
                        align       => -1,
                        valign      => -1,
                    },
                    policy => {
                        title       => 'Policy',
                        width       => 112,
                        title_align => -1,
                        align       => -1,
                        valign      => -1,
                    },
                ],
            );

            my $report = $tbl->render_header;

            my $total_violations = scalar keys $violations->%*;

            # sorting violations by descending severity, ascending first line then by policy text
            for my $v ( sort { $violations->{$a}->{severity} != $violations->{$b}->{severity} ? $violations->{$b}->{severity} <=> $violations->{$a}->{severity} : $violations->{$a}->{first_line} != $violations->{$b}->{first_line} ? $violations->{$a}->{first_line} <=> $violations->{$b}->{first_line} : $a cmp $b } keys $violations->%* ) {
                my $policy = $v;

                if ( keys $violations->{$v}->{desc}->%* > 1 ) {    # multiple violations with different descriptions
                    $report .= $tbl->render_row( [ $violations->{$v}->{severity}, $EMPTY, $policy ] );

                    # sorting descriptions by ascending first line number, then by description text
                    for my $desc ( sort { $violations->{$v}->{desc}->{$a}->{line}->[0] != $violations->{$v}->{desc}->{$b}->{line}->[0] ? $violations->{$v}->{desc}->{$a}->{line}->[0] <=> $violations->{$v}->{desc}->{$b}->{line}->[0] : $violations->{$v}->{desc}->{$a}->{text} cmp $violations->{$v}->{desc}->{$b}->{text} } keys $violations->{$v}->{desc}->%* ) {
                        $report .= $tbl->render_row( [ $EMPTY, join( ', ', sort { $a <=> $b } $violations->{$v}->{desc}->{$desc}->{line}->@* ), qq[* $violations->{$v}->{desc}->{$desc}->{text}] ] );
                    }
                }
                else {                                             # single violation
                    $policy .= qq[ - $violations->{$v}->{desc}->{[keys $violations->{$v}->{desc}->%*]->[0]}->{text}];

                    $report .= $tbl->render_row( [ $violations->{$v}->{severity}, join( ', ', sort { $a <=> $b } keys $violations->{$v}->{line}->%* ), $policy ] );
                }

                # add diagnostic
                $report .= $tbl->render_row( [ $EMPTY, $EMPTY, "\nDiagnostics:\n$violations->{$v}->{diag}" ] ) if $self->{perl_verbose} && $violations->{$v}->{severity} >= $PERLCRITIC_ERROR;

                # add table row line
                if ( --$total_violations ) {
                    $report .= $tbl->render_row_line;
                }
                else {
                    $report .= $tbl->finish;
                }
            }

            $error_log = qq[PerlCritic profile "$perl_critic_profile_name" policy violations:\n];

            $error_log .= $report;

            $res = res $SEVERITY->{$max_severity};
        }

        # no perlcritic violations found
        else {
            $res = res $SEVERITY->{0};
        }
    }

    # perltidy ok, percritic - not run
    else {
        $res = res $SEVERITY->{0};
    }

    $self->_append_log($error_log);

    return $res;
}

sub compress ( $self ) {
    state $dbh = do {
        my $_dbh = P->handle("sqlite:$ENV->{PCORE_USER_DIR}/perl-compress.sqlite");

        $_dbh->add_schema_patch(
            1 => <<'SQL'
                CREATE TABLE "cache" (
                    "id" TEXT PRIMARY KEY NOT NULL,
                    "code" BLOB NOT NULL
                );
SQL
        );

        $_dbh->upgrade_schema;

        $_dbh;
    };

    # cut __END__ or __DATA__ sections
    my $data_section = $EMPTY;

    if ( $self->{data}->$* =~ s/(\n__(END|DATA)__(?:\n.*|))\z//sm ) {
        $data_section = $1 if $self->{perl_compress_end_section} || $2 eq 'DATA';
    }

    my $md5 = P->digest->md5_hex( $self->{data}->$* );

    my ( $key, $code );

    if ( $self->{perl_compress} ) {

        # NOTE keep_nl is not supported
        $self->{perl_compress_keep_ln} = 0;

        my $optimise_size = 1;

        $key = 'compress_' . $self->{perl_compress_keep_ln} . $optimise_size . $md5;

        $code = $dbh->selectrow( 'SELECT "code" FROM "cache" WHERE "id" = ?', [$key] )->{data}->{code};

        if ( !defined $code ) {
            require Perl::Strip;

            my $transform = Perl::Strip->new( optimise_size => $optimise_size, keep_nl => $self->{perl_compress_keep_ln} );

            $code = rcut_all $transform->strip( $self->{data}->$* );

            $dbh->do( 'INSERT INTO "cache" ("id", "code") VALUES (?, ?)', [ $key, SQL_BYTEA $code ] );
        }
    }
    else {
        $key = 'strip_' . $self->{perl_compress_keep_ln} . $self->{perl_strip_ws} . $self->{perl_strip_comment} . $self->{perl_strip_pod} . $md5;

        $code = $dbh->selectrow( 'SELECT "code" FROM "cache" WHERE "id" = ?', [$key] )->{data}->{code};

        if ( !defined $code ) {
            require Perl::Stripper;

            my $transform = Perl::Stripper->new(
                maintain_linum => $self->{perl_compress_keep_ln},    # keep line numbers unchanged
                strip_ws       => $self->{perl_strip_ws},            # strip extra whitespace
                strip_comment  => $self->{perl_strip_comment},
                strip_pod      => $self->{perl_strip_pod},
                strip_log      => 0,                                 # strip Log::Any log statements
            );

            $code = rcut_all $transform->strip( $self->{data}->$* );

            $dbh->do( 'INSERT INTO "cache" ("id", "code") VALUES (?, ?)', [ $key, SQL_BYTEA $code ] );
        }
    }

    $self->{data}->$* = $code . $data_section;

    return res $SEVERITY->{0};
}

sub _append_log ( $self, $log ) {
    $self->_cut_log;

    if ($log) {
        encode_utf8 $log;

        $log = qq[-----SOURCE FILTER LOG BEGIN-----\n\n$log\n-----SOURCE FILTER LOG END-----\n];

        $log =~ s/^/## /smg;

        # insert log befor __END__ or __DATA__ token
        # or append to end end or src
        if ( $self->{data}->$* =~ /^__(END|DATA)__$/sm ) {
            my $section = $1;

            $self->{data}->$* =~ s/^__${section}__$/${log}__${section}__/sm;
        }
        else {
            $self->{data}->$* .= "\n$log";
        }
    }

    return;
}

sub _get_perlcritic_profile_name ( $self, $profile ) {
    if ( $profile eq '1' ) {
        $profile = 0;

        my $is_pcore = $self->{data}->$* =~ /^use\s+Pcore(?:\s|;)/sm ? 1 : 0;

        for my $name ( keys $self->src_cfg->{perlcritic}->%* ) {
            next if !defined $self->src_cfg->{perlcritic}->{$name}->{__pcore__};

            if ( $self->src_cfg->{perlcritic}->{$name}->{__pcore__} == $is_pcore ) {
                $profile = $name;

                last;
            }
        }
    }

    return $profile;
}

sub _get_perlcritic_object ( $self, $name ) {
    state $perlcritic_object_cache = {};

    unless ( exists $perlcritic_object_cache->{$name} ) {
        my $get_profile = sub ($name) {
            my $profile;

            if ( $self->src_cfg->{perlcritic}->{$name}->{__parent__} ) {
                $profile = P->hash->merge( __SUB__->( $self->src_cfg->{perlcritic}->{$name}->{__parent__} ), $self->src_cfg->{perlcritic}->{$name} );
            }
            else {
                $profile = Clone::clone( $self->src_cfg->{perlcritic}->{$name} );
            }

            delete $profile->@{qw[__pcore__ __parent__]};

            return $profile;
        };

        my $profile = $get_profile->($name);

        # convert profile to Perl::Critic format
        for my $policy ( keys $profile->%* ) {
            if ( !$profile->{$policy} ) {
                delete $profile->{$policy};

                $profile->{"-$policy"} = 0;
            }
        }

        $perlcritic_object_cache->{$name} = Perl::Critic->new(
            '-profile-strictness' => $Perl::Critic::Utils::Constants::PROFILE_STRICTNESS_FATAL,
            -profile              => $profile,
        );
    }

    return $perlcritic_object_cache->{$name};
}

sub _format_heredoc ($self) {

    # TODO PCORE-72
    # parse heredocs in $self->{data}
    # call correspondednt formatters

    return;
}

sub _cut_log ($self) {
    $self->{data}->$* =~ s/^## -----SOURCE FILTER LOG BEGIN-----.*?## -----SOURCE FILTER LOG END-----\n?//sm;    ## no critic qw[RegularExpressions::ProhibitComplexRegexes]

    rcut_all $self->{data}->$*;

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 39                   | Subroutines::ProhibitExcessComplexity - Subroutine "decompress" with high complexity score (29)                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 173                  | BuiltinFunctions::ProhibitReverseSortBlock - Forbid $b before $a in sort blocks                                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Src::Filter::perl

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
