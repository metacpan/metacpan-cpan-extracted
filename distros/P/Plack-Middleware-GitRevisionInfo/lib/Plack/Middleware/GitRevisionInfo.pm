package Plack::Middleware::GitRevisionInfo;
use Moo;
use Plack::Util;
use 5.008008;

extends 'Plack::Middleware';

our $VERSION = '0.002';

has 'path' => (
    is => 'ro',
);

has 'git_command' => (
    is      => 'ro',
    default => sub { 'LC_ALL=C git log -1 --pretty=medium' }
);

sub call {
    my ($self, $env) = @_;

    my $response = $self->app->($env);
    $self->response_cb($response, sub { $self->_handle_response(shift) });
}

sub _handle_response {
    my ($self, $response)   = @_;
    my $header              = Plack::Util::headers($response->[1]);
    my $content_type        = $header->get('Content-Type');
    my $path                = $self->path;
    
    return unless defined $content_type && $content_type =~ qr[text/html] && $path;
    
    my $body = [];
    Plack::Util::foreach( $response->[2], sub { push @$body, $_[0] });
    $body = join '', @$body;

    $body .= $self->_get_revision_info;
    
    $response->[2] = [$body];
    $header->set('Content-Length', length $body);

    return;
}

sub _get_revision_info {
    my $self = shift;
    if ( -d $self->path ) {
        my $path    = $self->path;
        my $command = $self->git_command;
        my $output  = `cd $path;$command`;

        my ($sha)   = $output =~ m/commit\s([^\n]*)\n/s;
        my ($date)  = $output =~ m/Date:\s+([^\n]*)\n/s;

        return qq[<!-- Revision: $sha Date: $date -->];
    }
    return;
}

1;
=head1 NAME

Plack::Middleware::GitRevisionInfo - Middleware that appends git revision information to html

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable "Plack::Middleware::GitReivisionInfo", path => '../repo';
        $app;
    };

=head1 DESCRIPTION

L<Plack::Middleware::GitRevisionInfo> will display the git revision
information in the source of an html document in the following format:

    <!-- REVISION #:... DATE:MM/DD/YYYY -->

=head1 ARGUMENTS

This middleware accepts the following arguments.

=head2 path

This is the path to the git repository. This is a required argument.

=head1 SEE ALSO

L<Plack>, L<Plack::Middleware>, L<Moo> 

=head1 AUTHOR

Logan Bell, C<< <logie@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012, Logan Bell

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

