package Perlbal::Plugin::Addheader;

use warnings;
use strict;

=head1 NAME

Perlbal::Plugin::Addheader - Add Headers to Perlbal webserver/reverse_proxy responses

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';


=head1 Description

This module allows you to add/change headers to/from perlbal responses.

You can configure headers to be added/changed based on each service declared, although the service role has to be set to web_server or reverse_proxy.

For each header you want to add/change,  you have to specify the header content, this header content can be a set of characters or Perl code that will be evaluated for each response.




=head1 SYNOPSIS

This module provides a Perlbal plugin wich can be loaded and used as follows

    Load Addheader

    #ADDHEADER <service_name> <header_name> <header_content>
    ADDHEADER static Server This is My Webserver
    
    CREATE SERVICE static
        SET ROLE = web_server
        SET docroot /server/static
        SET plugins = Addheader
    ENABLE static

In this case for each response served by the C<Service static>, the header C<Server> will be changed to C<This is my Webserver>.

In cases where you need a dynamic value to be server as header content, you can put Perl code as the header content, surrounding the header content with C<[%> and C<%]>.

    ADDHEADER static Expires [% {use HTTP::Date;HTTP::Date::time2str(time() + 2592000)} %]

In this case, for each response, the header C<Expires> will be added, ant the content will be the time in exactly 30 days from the time the response has been sent .





=head1 AUTHOR

Bruno Martins, C<< <bruno.martins at co.sapo.pt> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-perlbal-plugin-addheader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perlbal-Plugin-Addheader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Perlbal::Plugin::Addheader


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perlbal-Plugin-Addheader>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Perlbal-Plugin-Addheader>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Perlbal-Plugin-Addheader>

=item * Search CPAN

L<http://search.cpan.org/dist/Perlbal-Plugin-Addheader/>

=back


=head1 TODO

Allow add/change response headers on all services (non role dependent)

Allow add/change response headers on all services at a time (one line configuration)



=head1 COPYRIGHT & LICENSE

Copyright 2009 Bruno Martins  C<< <bruno.martins at co.sapo.pt> >> and SAPO C<http://www.sapo.pt>, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

my $added_headers;

sub register {
    my ($class, $svc) = @_;
    use Data::Dumper;
    $svc->register_hook('Addheader','modify_response_headers', sub {

        my Perlbal::HTTPHeaders $res = $_[0]->{res_headers};
        my $service_name = $_[0]->{service}{'name'};
        if (defined $added_headers->{$service_name}) {
            foreach my $header (@{$added_headers->{$service_name}}) {
                my $header_content= $header->{'header_content'};
                if ($header_content =~/^\[\%.*\%]$/) {
                    $header_content =~s/^\[\%//;
                    $header_content =~s/\%\]$//;
                    $header_content = eval($header_content);
                    if ($@) {
                        print "Error on eval for header '$header->{'header_name'}'\n";
                        next;
                    }
                }
                $res->header($header->{'header_name'}, $header_content);
            }
        }
        return 0;
    });

	$svc->register_hook('Addheader','backend_response_received', sub {

        my Perlbal::HTTPHeaders $res = $_[0]->{res_headers};
        my $service_name = $_[0]->{service}{'name'};
        if (defined $added_headers->{$service_name}) {
            foreach my $header (@{$added_headers->{$service_name}}) {
                my $header_content= $header->{'header_content'};
                if ($header_content =~/^\[\%.*\%]$/) {
                    $header_content =~s/^\[\%//;
                    $header_content =~s/\%\]$//;
                    $header_content = eval($header_content);
                    if ($@) {
                        print "Error on eval for header '$header->{'header_name'}'\n";
                        next;
                    }
                }
                $res->header($header->{'header_name'}, $header_content);
            }
        }
        return 0;
    });


    return 0;
}

sub unregister {
    my ($class, $svc) = @_;
    $svc->unregister_hooks('Addheader');
    return 1;
}


sub load {

    Perlbal::register_global_hook('manage_command.addheader', sub {
        my $command_regexp = qr/^addheader\s+(\w+)\s+([^\s]+)\s+(.*?)$/i;
        my $mc = shift->parse($command_regexp,
                              "usage: ADDHEADER <SERVICE> <HEADER_NAME> <HEADER_CONTENT>");
        my ($service, $header_name, $header_content) = $mc->args;

        # Get the original line, since perlbal puts everything to lower case before parsing
        my @args = ($mc->orig =~/$command_regexp/);
        $header_content = pop @args;

        push @{$added_headers->{$service}},{'header_name' => $header_name, 'header_content' => $header_content};
    });
    return 1;
}
sub unload { return 1; }



1; # End of Perlbal::Plugin::Addheader
