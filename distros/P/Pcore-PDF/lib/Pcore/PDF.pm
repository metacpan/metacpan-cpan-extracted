package Pcore::PDF v0.2.1;

use Pcore -dist, -class, -const, -result;
use Config;
use Pcore::Util::Data qw[to_json from_json];

const our $PAGE_SIZE => {
    A0        => '841 x 1189 mm',
    A1        => '594 x 841 mm',
    A2        => '420 x 594 mm',
    A3        => '297 x 420 mm',
    A4        => '210 x 297 mm, 8.26 x 11.69 inches',
    A5        => '148 x 210 mm',
    A6        => '105 x 148 mm',
    A7        => '74 x 105 mm',
    A8        => '52 x 74 mm',
    A9        => '37 x 52 mm',
    B0        => '1000 x 1414 mm',
    B1        => '707 x 1000 mm',
    B2        => '500 x 707 mm',
    B3        => '353 x 500 mm',
    B4        => '250 x 353 mm',
    B5        => '176 x 250 mm, 6.93 x 9.84 inches',
    B6        => '125 x 176 mm',
    B7        => '88 x 125 mm',
    B8        => '62 x 88 mm',
    B9        => '33 x 62 mm',
    B10       => '31 x 44 mm',
    C5E       => '163 x 229 mm',
    Comm10E   => '105 x 241 mm, U.S. Common 10 Envelope',
    DLE       => '110 x 220 mm',
    Executive => '7.5 x 10 inches, 190.5 x 254 mm',
    Folio     => '210 x 330 mm',
    Ledger    => '431.8 x 279.4 mm',
    Legal     => '8.5 x 14 inches, 215.9 x 355.6 mm',
    Letter    => '8.5 x 11 inches, 215.9 x 279.4 mm',
    Tabloid   => '279.4 x 431.8 mm',
};

has page_size => ( is => 'ro', isa => Enum [ keys $PAGE_SIZE->%* ], default => 'A4' );

has threads => ( is => 'ro', isa => Int, default => 0, init_arg => undef );

has _proc => ( is => 'ro', isa => InstanceOf ['Pcore:PM::Proc'], init_arg => undef );
has _queue => ( is => 'ro', isa => ArrayRef, default => sub { [] }, init_arg => undef );

our $PRINCEXML_PATH = '/bin/princexml' . ( $MSWIN ? '-win' : '-linux' ) . ( $Config{archname} =~ /x64|x86_64/sm ? '-x64' : q[] ) . '-v11/';
our $PRINCEXML_BIN = $ENV->share->get( $PRINCEXML_PATH . ( $MSWIN ? 'bin/prince.exe' : 'bin/prince' ) );

# NOTE job config example
# {   input => {
#         src                     => 'job-resource:0',
#         type                    => <string>,
#         base                    => <string>,
#         media                   => <string>,
#         styles                  => [<list of URLs>],
#         scripts                 => [<list of URLs>],
#         'default-style'         => <bool>,
#         'author-style'          => <bool>,
#         javascript              => <bool>,
#         xinclude                => <bool>,
#         'xml-external-entities' => <bool>
#     },
#     pdf => {
#         'color-options'           => 'auto',    # 'auto' | 'use-true-black' | 'use-rich-black',
#         'embed-fonts'             => \1,
#         'subset-fonts'            => \1,
#         'artificial-fonts'        => \1,
#         'force-identity-encoding' => \1,
#         compress                  => \1,
#         encrypt                   => {
#             'key-bits'          => 128,         # 40 | 128,
#             'user-password'     => <string>,
#             'owner-password'    => <string>,
#             'disallow-print'    => <bool>,
#             'disallow-modify'   => <bool>,
#             'disallow-copy'     => <bool>,
#             'disallow-annotate' => <bool>
#         },
#         attach                  => [<list of URLs>],
#         'pdf-profile'           => <string>,
#         'pdf-output-intent'     => <URL>,
#         'fallback-cmyk-profile' => <URL>,
#         'color-conversion'      => 'none',             # 'none' | 'full'
#     },
#     metadata => {
#         title    => q[],
#         subject  => q[],
#         author   => q[],
#         keywords => q[],
#         creator  => q[],
#     },
#     raster => {                                        #
#         dpi => 300,
#     },
#     'job-resource-count' => 1,
# };

sub generate_pdf ( $self, $src, $cb ) {
    my ( $job, $resources );

    if ( ref $src ) {
        $job->{input}->{src} = 'job-resource:0';

        push $resources->@*, $src;
    }
    else {
        $job->{input}->{src} = $src;
    }

    $job->{'job-resource-count'} = $resources ? scalar $resources->@* : 0;

    if ( $self->{threads} ) {
        push $self->{_queue}->@*, [ to_json($job), $resources, $cb ];
    }
    else {
        $self->_run_job( to_json($job), $resources, $cb );
    }

    return;
}

sub remove_logo ( $self, $pdf_ref ) {
    state $init = !!require CAM::PDF;

    # re-pack created PDF
    my $pdf = CAM::PDF->new( $pdf_ref->$* );

    foreach my $objnum ( sort { $a <=> $b } keys %{ $pdf->{xref} } ) {
        my $xobj = $pdf->dereference($objnum);

        if ( $xobj->{value}->{type} eq 'dictionary' ) {
            my $im = $xobj->{value}->{value};

            if ( defined $im->{Type} and defined $im->{Subtype} and $pdf->getValue( $im->{Type} ) eq 'Annot' ) {
                $pdf->deleteObject($objnum);
            }
        }
    }

    $pdf_ref->$* = $pdf->cleansave->{content};    ## no critic qw[Variables::RequireLocalizedPunctuationVars]

    return;
}

sub _run_job ( $self, $job, $resources, $cb ) {
    return if $self->{threads};

    $self->{threads}++;

    $self->_get_proc(
        sub ($proc) {
            $proc->stdin->push_write( 'job ' . length( $job->$* ) . $LF . $job->$* . $LF );

            if ($resources) {
                for my $resource ( $resources->@* ) {
                    $proc->stdin->push_write( 'dat ' . length( $resource->$* ) . $LF . $resource->$* . $LF );
                }
            }

            my $on_finish = sub ( $status, $reason, $pdf_ref = undef, $log_ref = undef ) {
                $self->{threads}--;

                $proc->stdout->on_read(undef);

                my $res = result [ $status, $reason ], { pdf => $pdf_ref, log => $log_ref };

                $cb->($res);

                if ( my $job = shift $self->{_queue}->@* ) {
                    $self->_run_job( $job->@* );
                }

                return;
            };

            $proc->stdout->on_read(
                sub ($h) {

                    # read pdf
                    $h->unshift_read(
                        line => sub ( $h, $line, $eol ) {
                            my ( $tag, $len ) = split /\s/sm, $line, 2;

                            if ( !$len ) {
                                $on_finish->( 500, q[princexml protocol error: no version] );
                            }
                            else {
                                $h->unshift_read(
                                    chunk => $len + 1,
                                    sub ( $h, $data ) {
                                        chop $data;

                                        # protocol error
                                        if ( $tag eq 'err' ) {
                                            $on_finish->( 500, $data );
                                        }

                                        # read log
                                        else {
                                            my $pdf_ref = \$data;

                                            $h->unshift_read(
                                                line => sub ( $h, $line, $eol ) {
                                                    my ( $tag1, $len1 ) = split /\s/sm, $line, 2;

                                                    if ( !$len1 ) {
                                                        $on_finish->( 500, q[princexml protocol error: no version] );
                                                    }
                                                    else {
                                                        $h->unshift_read(
                                                            chunk => $len1 + 1,
                                                            sub ( $h, $data ) {
                                                                chop $data;

                                                                $on_finish->( 200, 'OK', $pdf_ref, [ split /\n/sm, $data ] );

                                                                return;
                                                            }
                                                        );
                                                    }

                                                    return;
                                                }
                                            );
                                        }

                                        return;
                                    }
                                );
                            }

                            return;
                        }
                    );

                    return;
                }
            );

            return;
        }
    );

    return;
}

sub _get_proc ( $self, $cb ) {
    if ( $self->{_proc} ) {
        $cb->( $self->{_proc} );
    }
    else {
        P->pm->run_proc(
            [ 'prince', '--no-network', '--control' ],
            stdin    => 1,
            stdout   => 1,
            stderr   => 1,
            on_ready => sub ($proc) {
                $self->{_proc} = $proc;

                $proc->stdout->on_read(
                    sub ($h) {
                        $h->unshift_read(
                            line => sub ( $h, $line, $eol ) {
                                my ( $tag, $len ) = split /\s/sm, $line, 2;

                                if ( !$len ) {
                                    die q[princexml protocol error: no version];
                                }
                                else {
                                    $h->unshift_read(
                                        chunk => $len + 1,
                                        sub ( $h, $data ) {
                                            chop $data;

                                            $h->on_read(undef);

                                            $cb->( $self->{_proc} );

                                            return;
                                        }
                                    );
                                }

                                return;
                            }
                        );

                        return;
                    }
                );

                return;
            },
            on_finish => sub ($proc) {
                delete $self->{_proc};

                return;
            }
        );
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::PDF - HTML to PDF convertor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

=cut
