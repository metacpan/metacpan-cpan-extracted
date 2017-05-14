package Plack::ResponseHelper::Attachment;
use strict;
use warnings;

use Plack::Response;


sub helper {
    my $init = shift;
    my $content_type = $init && $init->{content_type} || 'application/octet-stream';

    return sub {
        my $r = shift;

        my $response = Plack::Response->new(200);
        $response->headers(
            [
                'Content-Type' => $content_type,
                'Content-Disposition' => qq[attachment; filename="$r->{filename}"],
            ],
        );
        $response->body($r->{data});
        return $response;
    };
}

1;

__END__

=head1 NAME

Plack::ResponseHelper::Attachment

=head1 SYNOPSIS

    use Plack::ResponseHelper pdf => [Attachment => {content_type => 'application/pdf'}];
    respond pdf => {filename => 'report.pdf', data => $report};

=head1 SEE ALSO

Plack::ResponseHelper

=cut
