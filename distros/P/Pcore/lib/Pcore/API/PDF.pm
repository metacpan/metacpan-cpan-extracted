package Pcore::API::PDF;

use Pcore -class, -const, -res;
use Config;
use Pcore::Util::Data qw[to_json from_json];
use Pcore::Util::Scalar qw[is_plain_scalarref];
use Pcore::Util::Sys::Proc qw[:PROC_REDIRECT];

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

has bin         => 'princexml';
has max_threads => P->sys->cpus_num;
has page_size   => $PAGE_SIZE->{A4};

has _semaphore => sub ($self) { Coro::Semaphore->new( $self->{max_threads} ) }, is => 'lazy';
has _princexml => ();

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
#         title    => $EMPTY,
#         subject  => $EMPTY,
#         author   => $EMPTY,
#         keywords => $EMPTY,
#         creator  => $EMPTY,
#     },
#     raster => {                                        #
#         dpi => 300,
#     },
#     'job-resource-count' => 1,
# };

sub generate_pdf ( $self, $html ) {

    # block thread
    my $guard = $self->{max_threads} && $self->_semaphore->guard;

    my $princexml;

    while ( defined( $princexml = pop $self->{_princexml}->@* ) ) {
        last if $princexml->is_active;
    }

    $princexml //= $self->_create_princexml_proc;

    my $res = $self->_run_task( $princexml, \$html );

    push $self->{_princexml}->@*, $princexml;

    return $res;
}

sub remove_logo ( $self, $pdf_ref ) {
    require CAM::PDF;

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

    $pdf_ref->$* = $pdf->cleansave->{content};

    return;
}

sub _create_princexml_proc ($self) {
    my $proc = P->sys->run_proc(
        [ $self->{bin}, '--control' ],
        stdin  => $PROC_REDIRECT_SOCKET,
        stdout => $PROC_REDIRECT_SOCKET,
        stderr => $PROC_REDIRECT_SOCKET,
    );

    undef $proc->{child_stdout};
    undef $proc->{child_stderr};

    my $line = $proc->{stdout}->read_line("\n");

    my ( $tag, $len ) = split /\s/sm, $line->$*, 2;

    die q[princexml protocol error: no version] if !$len;

    my $data = $proc->{stdout}->read_chunk( $len + 1 );

    chop $data->$*;

    return $proc;
}

sub _run_task ( $self, $princexml, $task_ref ) {
    my ( $job, $resources );

    if ( is_plain_scalarref $task_ref->$* ) {
        $job->{input}->{src} = 'job-resource:0';

        push $resources->@*, $task_ref->$*;
    }
    else {
        $job->{input}->{src} = $task_ref->$*;
    }

    $job->{'job-resource-count'} = $resources ? scalar $resources->@* : 0;

    # write job
    my $json = to_json $job;

    $princexml->{stdin}->write( 'job ' . length($json) . "\n$json\n" );

    if ($resources) {
        for my $resource ( $resources->@* ) {
            $princexml->{stdin}->write( 'dat ' . length( $resource->$* ) . "\n$resource->$*\n" );
        }
    }

    my $line = $princexml->{stdout}->read_line("\n");

    # protocol error, connection closed
    return res 500 if !$line;

    my ( $tag, $len ) = split /\s/sm, $line->$*, 2;

    # protocol error
    return res 500 if !$len;

    my $data = $princexml->{stdout}->read_chunk( $len + 1 );

    chop $data->$*;

    # protocol error
    return res [ 500, $data->$* ] if $tag eq 'err';

    # read log
    $line = $princexml->{stdout}->read_line("\n");

    my ( $tag1, $len1 ) = split /\s/sm, $line->$*, 2;

    # protocol error
    return res 500 if !$len1;

    my $log = $princexml->{stdout}->read_chunk( $len1 + 1 );

    chop $log->$*;

    return res 200, $data, log => $log;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::PDF - non-blocking HTML to PDF converter

=head1 SYNOPSIS

    use Pcore::API::PDF;

    my $pdf = Pcore::API::PDF->new({
        bin         => 'path-to-princexml-executable',
        max_threads => 4,
    });

    # $res->{data} contains ScalarRef to generated PDF content
    my $res = $pdf->generate_pdf($html);

=head1 DESCRIPTION

Generate PDF from HTML templates, using princexml.

=head1 ATTRIBUTES

=over

=item bin

Path to F<princexml> executable. Mandatory attribute.

=item max_threads

Maximum number of princexml processes. Default value is C<< 4 >>.

=back

=head1 METHODS

=over

=item generate_pdf( $self, $html )

Generates PDF from C<< $html >> template. C<< $result >> is a standard Pcore API result object, see L<Pcore::Util::Result> documentation for details.

=back

=head1 SEE ALSO

=over

=item L<Pcore>

=item L<Pcore::Util::Result>

=item L<https://www.princexml.com/|https://www.princexml.com/>

=back

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

=cut
