#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Handler::FCGI;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Handler::FCGI - FCGI Handler.

=head1 SYNOPSIS
    
    # run the app in FCGI standalone mode
    $app->object("Nile::Handler::FCGI")->run();

=head1 DESCRIPTION

Nile::Handler::FCGI - FCGI Handler.

=cut

use Nile::Base;
use FCGI;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    our $fcgi_request_count = 0; # the number of requests this fcgi process handled.
    our $handling_request = 0;
    our $exit_requested = 0;
    our $app_quit_request = 0; # End the application but not the FCGI process

    # workaround for known bug in libfcgi
    while ((our $ignore) = each %ENV) { }

    our $fcgi_request = FCGI::Request();
    #$fcgi_request = FCGI::Request(\*STDIN, \*STDOUT, \*STDERR, \%ENV, $socket);
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub run {

    my ($self) = shift;

    my $app = $self->app;

    # The goal of fast cgi is to load the program once, and iterate in a loop for every request.

    while ($handling_request = ($fcgi_request->Accept() >= 0)) {
        
        #$app->log->debug("FCGI request start");

        $app->env(\%ENV);

        # handle it as the normal CGI request
        $app->object("Nile::Handler::CGI")->run();

        $handling_request = 0;
        last if $exit_requested;
        #exit if -M $ENV{SCRIPT_FILENAME} < 0; # Autorestart
        
        #$app->log->debug("FCGI request end");
        #$app->stop_logger;
    }

    $fcgi_request->Finish();
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub request {
    $fcgi_request;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub is_fcgi {
    my ($self) = shift;
    if (defined($fcgi_request) && ref($fcgi_request) && $fcgi_request->IsFastCGI()) {
        return 1;
    } else {
        return 0;
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub accept {
    my ($self) = shift;
    $fcgi_request->Accept() >= 0;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub finish {
    my ($self) = shift;
    $exit_requested = 1;
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
