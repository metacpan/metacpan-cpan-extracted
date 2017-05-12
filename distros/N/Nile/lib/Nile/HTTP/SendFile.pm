#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::HTTP::SendFile;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::HTTP::SendFile - Send files to browser.

=head1 SYNOPSIS
        
=head1 DESCRIPTION

Nile::HTTP::SendFile - Send files to browser.

=cut

use Nile::Base;
use Module::Load;

use List::Util qw(min);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub send_file  {

    my ($self, $res, $file, $opt) = @_;

    my %options = (
        type => $self->app->mime->for_file($file) || "application/x-download",
        range => !ref($file),
        cache => 0,
        inline => 0,
        %{$opt || {}},
    );

    if (!$options{cache}) {
        $res->header(Expires => "Sat, 01 Jan 2000 00:00:00 GMT");
    }
    else {
        $res->remove_header("Expires");
        if (!ref($file)) {
            my $lastmod = $res->http_date((stat $file)[9]);
            my $ifmod = $ENV{HTTP_IF_MODIFIED_SINCE};
            if ($ifmod && $ifmod eq $lastmod) {
                $res->header(Status => "304 Not Modified";
                return \"";
            }
            else {
                $res->header('Last-Modified' => $lastmod);
            }
        }
    }

    my $len = ref($file) ? length(${$file}) : -s $file;

    my ($start, $end) = (0, $len-1);
    
    #if ($options{range}) {
    #   ($start, $end) = $self->parse_range($ENV{HTTP_RANGE}, $len);
    #}
    #require PerlIO::subfile;
    #open my $fh, "<:raw:subfile(start=$start,end=".($end+1).")", $file or return $self->return_403;


    if ($options{range} && defined $ENV{HTTP_RANGE} && $ENV{HTTP_RANGE} =~ /\Abytes=(\d*)-(\d*)\z/ixms) {
        my ($from, $to) = ($1, $2);
        if ($from ne "" && $to ne "" && $from <= $to && $to < $len) {
            # 0-0, 0-499, 500-999
            $start = $from;
            $end = $to;
        }
        elsif ($from ne "" && $to eq "" && $from < $len) {
            # 0-, 500-, 999-
            $start  = $from;
        }
        elsif ($from eq "" && $to ne "" && $to > 0 && $to <= $len) {
            # -1, -500, -1000
            $start  = $len - $to;
        }
    }

    my $size = $end - $start + 1;

    $res->header("Accept-Ranges" => "bytes");
    $res->header("Content-Length" => $size);
    $res->header("Content-Type" => $options{type});

    # Content-Disposition: attachment; filename="filename.jpg"
    if (!$options{inline}) {
        $res->header("Content-Disposition" => "attachment");
    }

    if (!($start == 0 && $end == $len-1)) {
        $res->header("Status" => "206 Partial Content");
        $res->header("Content-Range" => "bytes $start-$end/$len");
    }

    return _read_block($file, $start, $size);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub parse_range {

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
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub _read_block {

    my ($file, $start, $size) = @_;

    my $data = "";

    open my $fh, '<', $file or croak "open: $!";
    seek $fh, $start, 0;

    my ($n, $buf);
    while ($n = read $fh, $buf, min($size, 64*1024)) {
        $size -= length $buf;
        $data .= $buf;
    }

    croak "read: $!" if !defined $n;
    close $fh or croak "close: $!";

    return \$data;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
