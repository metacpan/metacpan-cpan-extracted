#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Handler::CGI;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Handler::CGI - CGI Handler.

=head1 SYNOPSIS
        
    # run the app in CGI standalone mode
    $app->object("Nile::Handler::CGI")->run();

=head1 DESCRIPTION

Nile::Handler::CGI - CGI Handler.

=cut

use Nile::Base;
use Nile::App;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub run {
    
    my ($self) = shift;
    
    my $app = Nile::App->new(app => $self->app());
    
    # direct CGI mode.
    my $request = $app->new_request();

    $app->response($app->object("Nile::HTTP::Response"));
    my $response = $app->response();
    
    #$app->log->debug("CGI/FCGI request start");

    $app->start();

    #$app->hook->on_request();
    $app->hook->off_request();
    #------------------------------------------------------
    # dispatch the action
    my $content = $app->dispatcher->dispatch;
    #------------------------------------------------------
    $app->hook->on_response;

    # assume OK response if not set
    $response->code(200) unless ($response->code);

    if (ref($content) eq 'GLOB') {
        # response is file handle
        if (!defined $response->header('Content-Length')) {
            my $size = (stat($content))[7];
            $response->header('Content-Length' => $size);
        }
        $response->content($content);
    }
    else {

        my $ctype = $response->header('Content-Type');
        if ($app->charset && $ctype && $app->content_type_text($ctype)) {
            $response->header('Content-Type' => "$ctype; charset=" . $app->charset) if $ctype !~ /charset/i;
        }

        $response->content($content);

        if (!$ctype) {
            $response->content_type('text/html;charset=' . $app->charset);
        }

        if (!defined $response->header('Content-Length')) {
            use bytes; # turn off character semantics
            $response->header('Content-Length' => length($content));
        }
    }

    # run any plugin action or route
    #$app->dispatcher->dispatch('/accounts/register/create');
    #$app->dispatcher->dispatch('/accounts/register/create', 'POST');

    #$response->cookies->{username} = {value => 'mewsoft', path  => "/", domain => '.mewsoft.com', expires => time + 24 * 60 * 60,};
    #$response->content_type('text/html;charset=utf-8');
    #$response->content_encoding('utf-8');
    #$response->header('Content-Type' => 'text/html');
    #$response->header(Content_Base => 'http://www.mewsoft.com/');
    #$response->header(Accept => "text/html, text/plain, image/*");
    #$response->header(MIME_Version => '1.0', User_Agent   => 'Nile Web Client/0.26');
    #$response->content("Hello world content.");
    #my $res = $response->finalize;
    #my $res = $response->headers_as_string;
    
    $app->hook->off_response;

    my $res = $response->as_string;
    
    #print "Content-type: text/html;charset=utf-8\n\n";
    #print $res, "\n", $response->content;
    #binmode STDOUT, ":UTF8";
    #binmode STDOUT, ':encoding(utf8)';

    #$app->log->debug("CGI/FCGI request end");
    #$app->stop_logger;

    print $res;
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
