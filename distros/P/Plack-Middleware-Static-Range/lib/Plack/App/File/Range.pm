package Plack::App::File::Range;
use 5.008001;
use strict;
use warnings;
use parent 'Plack::App::File';

sub serve_path {
    my ($self, $env, $file) = @_;
    my $range = $env->{HTTP_RANGE}
        or return $self->SUPER::serve_path($env, $file);

    $range =~ s/^bytes=//
        or return $self->return_416;

    my @ranges = split(/\s*,\s*/, $range)
        or return $self->return_416;

    my $content_type = $self->content_type || Plack::MIME->mime_type($file) || 'text/plain';
    if ($content_type =~ m!^text/!) {
        $content_type .= "; charset=" . ($self->encoding || "utf-8");
    }

    my @stat = stat $file;
    my $len = $stat[7];

    if (@ranges == 1) {
        my ($start, $end) = $self->_parse_range($range, $len)
            or return $self->return_416;

        require PerlIO::subfile;
        open my $fh, "<:raw:subfile(start=$start,end=".($end+1).")", $file
            or return $self->return_403;

        Plack::Util::set_io_path($fh, Cwd::realpath($file));

        return [
            206,
            [
                'Content-Type'   => $content_type,
                'Content-Range'  => "bytes $start-$end/$len",
                'Last-Modified'  => HTTP::Date::time2str( $stat[9] )
            ],
            $fh,
        ];
    }

    # Multiple ranges:
    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec19.html#sec19.2
    open my $fh, "<:raw", $file
        or return $self->return_403;

    require HTTP::Message;
    my $msg = HTTP::Message->new([
        'Content-Type'   => 'multipart/byteranges',
        'Last-Modified'  => HTTP::Date::time2str( $stat[9] ),
    ]);
    my $buf = '';
    for my $range (@ranges) {
        my ($start, $end) = $self->_parse_range($range, $len)
            or return $self->return_416;

        sysseek $fh, $start, 0;
        sysread $fh, $buf, ($end-$start+1);

        $msg->add_part(HTTP::Message->new(
            ['Content-Type' => $content_type, 'Content-Range' => "bytes $start-$end/$len"],
            $buf,
        ));
    }

    my $headers = $msg->headers;
    return [
        206,
        [map { ($_ => scalar $headers->header($_)) } $headers->header_field_names],
        [$msg->content],
    ];
}

sub _parse_range {
    my ($self, $range, $len) = @_;

    $range =~ /^(\d*)-(\d*)$/ or return;

    my ($start, $end) = ($1, $2);

    if (length $start and length $end) {
        return if $start > $end; # "200-100"
        return if $end >= $len;  # "0-0" on a 0-length file
        return ($start, $end);
    }
    elsif (length $start) {
        return if $start >= $len;  # "0-" on a 0-length file
        return ($start, $len-1);
    }
    elsif (length $end) {
        return if $end > $len;  # "-1" on a 0-length file
        return ($len-$end, $len-1);
    }

    return;
}

sub return_416 {
    my $self = shift;
    return [416, ['Content-Type' => 'text/plain', 'Content-Length' => 29], ['Request Range Not Satisfiable']];
}

1;

__END__

=encoding utf8

=head1 NAME

Plack::App::File::Range - Serve static files with support for Range requests

=head1 SYNOPSIS

    use Plack::App::File::Range;
    my $app = Plack::App::File::Range->new(root => "/path/to/htdocs")->to_app;

=head1 DESCRIPTION

This module is a subclass of L<Plack::App::File> with additional support for
requests with C<Range> headers.

It is used internally by L<Plack::Middleware::Static::Range>.

=head1 SEE ALSO

L<Plack::Middleware::Static::Range>, L<Plack::App::File>

=head1 AUTHORS

唐鳳 E<lt>cpan@audreyt.orgE<gt>

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<Plack::App::File::Range>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
