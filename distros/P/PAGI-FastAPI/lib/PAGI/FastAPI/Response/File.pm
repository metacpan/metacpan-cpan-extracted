package PAGI::FastAPI::Response::File;

use v5.38;
use experimental 'class';
use version;

our $VERSION   = qv('v1.2.5');
our $AUTHORITY = 'cpan:MANWAR';

use PAGI::FastAPI::Response;
use Exporter 'import';

our @EXPORT_OK = qw(file_response);

# Built on PAGI::FastAPI::Response's documented public contract
# (status/body/headers + prepare_headers), the same extension point
# PAGI::FastAPI::Response::HTML uses.
#
# DELIBERATE SCOPE LIMIT: this reads the whole file into memory rather than
# streaming it in chunks. PAGI::FastAPI::Response::SSE achieves true
# streaming via a dispatch($scope,$receive,$send) method that talks to the
# raw PAGI protocol directly, but it does so through PAGI::SSE, part of
# the base PAGI framework distribution, whose response-side protocol
# internals this module doesn't rely on or assume. Reusing the well-defined
# Response base-class contract instead is the tradeoff: correct and safe
# for small/moderate files (templates, generated reports, small assets),
# not appropriate for huge files or video. A true chunked-streaming version
# is a reasonable future upgrade for whoever wants to build directly on the
# response-side PAGI protocol the way Response::SSE does.

class PAGI::FastAPI::Response::File :isa(PAGI::FastAPI::Response) {
    field $filename :param = undef;

    method prepare_headers ($c, $default_content_type = 'application/octet-stream') {
        $self->SUPER::prepare_headers($c, $default_content_type);
        if (defined $filename) {
            (my $safe_name = $filename) =~ s/"/\\"/g;
            $c->set_header('content-disposition' => qq{attachment; filename="$safe_name"});
        }
    }
}

# A plain sub with a signature must come AFTER a `class ... :isa(...)` block
# in this Perl version, see PAGI::FastAPI::Response::Redirect for the
# isolated reproduction of why.
#
# Reads $path entirely into memory and returns a File response. Guesses a
# small set of common content types from the extension; pass content_type
# explicitly for anything else.
sub file_response ($path, %opts) {
    die "file_response: '$path' does not exist or is not readable\n"
        unless -e $path && -r _;

    open my $fh, '<:raw', $path or die "file_response: cannot open '$path': $!\n";
    local $/;
    my $data = <$fh>;
    close $fh;

    my $content_type = $opts{content_type} // _guess_content_type($path);
    my $filename      = $opts{filename} // do { (my $n = $path) =~ s{.*/}{}; $n };

    return PAGI::FastAPI::Response::File->new(
        body     => $data,
        status   => $opts{status} // 200,
        headers  => [ ['content-type', $content_type] ],
        filename => (($opts{as_attachment} // 1) ? $filename : undef),
    );
}

sub _guess_content_type ($path) {
    return 'text/plain; charset=utf-8'        if $path =~ /\.te?xt$/i;
    return 'text/html; charset=utf-8'         if $path =~ /\.html?$/i;
    return 'application/json'                 if $path =~ /\.json$/i;
    return 'text/csv'                         if $path =~ /\.csv$/i;
    return 'application/pdf'                  if $path =~ /\.pdf$/i;
    return 'image/png'                        if $path =~ /\.png$/i;
    return 'image/jpeg'                       if $path =~ /\.jpe?g$/i;
    return 'image/gif'                        if $path =~ /\.gif$/i;
    return 'image/svg+xml'                    if $path =~ /\.svg$/i;
    return 'application/octet-stream';
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Response::File - File Download Response for PAGI::FastAPI

=head1 VERSION

Version v1.2.5

=head1 SYNOPSIS

    use PAGI::FastAPI::Response::File qw(file_response);

    $app->get('/reports/{id}',
        handler => async sub ($c) {
            my $path = "/var/reports/" . $c->path_param('id') . ".pdf";
            return file_response($path);
        }
    );

    # Inline (view in browser) instead of "Save As" download prompt:
    $app->get('/logo.png',
        handler => async sub ($c) {
            return file_response('/var/assets/logo.png', as_attachment => 0);
        }
    );

    # Or construct directly:
    use PAGI::FastAPI::Response::File;

    my $res = PAGI::FastAPI::Response::File->new(
        body     => $binary_data,
        headers  => [ ['content-type', 'application/pdf'] ],
        filename => 'report.pdf',
    );

=head1 FUNCTIONS

=head2 C<file_response($path, %opts)>

Exported on request. Reads C<$path> from disk and returns a ready-to-return
L<PAGI::FastAPI::Response::File> instance.

=over 4

=item * C<content_type> - (Optional) Overrides the guessed MIME type.
Recognises C<.txt>, C<.html>, C<.json>, C<.csv>, C<.pdf>, C<.png>, C<.jpg>/C<.jpeg>,
C<.gif>, C<.svg> by extension; falls back to C<application/octet-stream>.

=item * C<filename> - (Optional) Overrides the C<Content-Disposition>
filename. Defaults to the basename of C<$path>.

=item * C<as_attachment> - (Optional) Boolean, defaults to true. When true,
sends C<Content-Disposition: attachment; filename="...">, prompting a
download. Set to false for inline display (e.g. images shown directly in
the browser).

=item * C<status> - (Optional) HTTP status code. Defaults to C<200>.

=back

Dies if C<$path> doesn't exist or isn't readable.

=head1 METHODS

=head2 C<new(%options)>

=over 4

=item * C<body> - (Required, inherited) The raw file content.

=item * C<headers> - (Optional, inherited) ArrayRef of C<[name, value]> pairs;
set C<content-type> here.

=item * C<filename> - (Optional) If set, adds a C<Content-Disposition:
attachment; filename="...">-header automatically.

=item * C<status> - (Optional, inherited) Defaults to C<200>.

=back

=head1 SEE ALSO

L<PAGI::FastAPI::Response>, L<PAGI::FastAPI::Response::HTML>, L<PAGI::FastAPI::Response::SSE>

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/PAGI-FastAPI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/PAGI-FastAPI/issues>.
I will be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PAGI::FastAPI::Response::File

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/PAGI-FastAPI/issues>

=item * Search MetaCPAN

L<https://metacpan.org/dist/PAGI-FastAPI/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0).

=cut

1; # End of PAGI::FastAPI::Response::File
