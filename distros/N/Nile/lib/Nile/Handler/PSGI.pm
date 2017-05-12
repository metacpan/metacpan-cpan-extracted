#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Handler::PSGI;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Handler::PSGI - PSGI Handler.

=head1 SYNOPSIS

    # run the app in PSGI mode and return the PSGI closure subroutine
    my $psgi = $app->object("Nile::Handler::PSGI")->run();
        
=head1 DESCRIPTION

Nile::Handler::PSGI - PSGI Handler.

=cut

use Nile::Base;
use Nile::App;
use Plack::Builder;
use Plack::Middleware::Deflater;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub run {
    
    my ($self) = shift;

    #$app->log->debug("PSGI app handler start");
    
    my $apps = $self->app(); # Nile object

    # PSGI mode. PSGI app will loop inside this closure, so reset any user session shared data inside it.
    my $psgi = sub {

        my $env = shift;
        
        my $app = Nile::App->new(app => $apps);

        #$app->dump($env);

        #$app->start_logger;
        #$app->log->debug("PSGI request start");

        $app->env($env);
        
        #*ENV = $env;
         #%ENV = %$env;
        #----------------------------------------------
        $app->new_request($app->env());

        my $request = $app->request();
        $self->dump($request);

        $app->response($app->object("Nile::HTTP::Response"));
        my $response = $app->response();

        $app->start();

        $app->hook->off_request();
        #----------------------------------------------
        #my $path = $app->env->{PATH_INFO} || $app->env->{REQUEST_URI};
        #$path = $app->file->catfile($app->var->get("path"), $path);
        #if (-f $path) {
        #   # file response: /favicon.ico
        #   $response->file_response($path);
        #   $app->stop_logger;
        #   return $response->finalize;
        #}
        #--------------------------------------------------
        # dispatch the action
        my $content = $app->dispatcher->dispatch();
        #--------------------------------------------------
        $app->hook->on_response();

        my $ctype = $response->header('Content-Type');
        if ($app->charset && $ctype && $app->content_type_text($ctype)) {
            $response->header('Content-Type' => "$ctype; charset=" . $app->charset) if $ctype !~ /charset/i;
        }

        $response->content($content);

        if (!$ctype) {
            $response->content_type('text/html;charset=' . $app->charset || "utf-8");
        }

        if (!defined $response->header('Content-Length')) {
            use bytes; # turn off character semantics
            $response->header('Content-Length' => length($content));
        }

        #$response->code(200) unless ($response->code);
        #$response->content_type('text/html') unless ($response->content_type);
        
        #$response->content_encoding('gzip');
        #$response->cookies->{username} = {value => 'mewsoft', path  => "/", domain => '.mewsoft.com', expires => time + 24 * 60 * 60,};
        #$response->header(Content_Base => 'http://www.mewsoft.com/');
        #$response->header(Accept => "text/html, text/plain, image/*");
        #$response->header(MIME_Version => '1.0', User_Agent   => 'Nile Web Client/0.26');
        #$response->content("Hello world content.");

        $response->content($content);
        
        #$app->log->debug("PSGI request end");
        $app->stop_logger();
        
        $app->hook->off_response();
        # return the PSGI response array ref
        return $response->finalize();
    };
    
    #return $psgi;

    # support Middleware
    return builder {
        # serve static files with Plack
        #enable "Static", path => qr{^/(web|file|theme)/}, root => './';
        #Plack::Middleware::Deflater
        enable "Static", 
            path => sub {
                my $path = $_;
                if ( $path =~ m/^\/(web|file|theme|favicon\.)/ ) {
                    # if matched, the value of $_ is being used as a request path, modify it to your needs
                    $_ = $path;
                    return 1;
                }
                return 0;
            },
            root => './';
        
        #enable "Deflater", content_type => ['text/css','text/html','text/javascript','application/javascript'], vary_user_agent => 1;

        $psgi;
    }
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
