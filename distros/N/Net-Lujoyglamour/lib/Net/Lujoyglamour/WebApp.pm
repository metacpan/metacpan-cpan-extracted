package Net::Lujoyglamour::WebApp;

use warnings;
use strict;
use Carp;

our $VERSION =   sprintf "%d.%03d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/g; 

use lib qw( ../../../lib ../../lib 
 /home/jmerelo/proyectos/CPAN/Net-Lujoyglamour/lib/); #Just in case we are testing it in-place

use base qw/DBIx::Class::Schema/;

use base 'CGI::Application';

use CGI::Application::Plugin::DBH (qw/dbh_config dbh/);
use CGI::Application::Plugin::DBIx::Class ':all';
use CGI::Application::Plugin::Redirect;
use Net::Lujoyglamour qw(is_valid);
use JSON;

sub cgiapp_init  {
    my $self = shift;
    my (%args ) = @_;
    croak "No DSN" if !$args{'PARAMS'}->{'dsn'};
    croak "No domain" if !$args{'PARAMS'}->{'domain'};
    $self->param('domain', $args{'PARAMS'}->{'domain'} );

    my %params = %{$args{'PARAMS'}};
    $self->dbh_config($params{'dsn'}, 
		      $params{'username'}, 
		      $params{'auth'});
    $self->dbic_config({schema => Net::Lujoyglamour->connect( $params{'dsn'}, 
							      $params{'username'}, 
							      $params{'auth'})});
}


# ( setup() can even be skipped for common cases. See docs below. )
sub setup {
    my $self = shift;
    $self->start_mode('form');
    $self->mode_param('rm');
    $self->run_modes(
	'form' => 'show_form',
	'geturl' => 'get_url',
	'redirect' => 'redirect_url'
        );
}

sub show_form {
    my $self = shift;
    my $tmpl;
    eval {
	$tmpl = $self->load_tmpl;
    };
    croak( "Can't load template from ".$self->{'__TMPL_PATH'}.". Error $@\n" ) if $@;
    $tmpl->param( domain => $self->param('domain') );
    return $tmpl->output;
}

sub get_url {
    my $self = shift;
    my $tmpl = $self->load_tmpl;
    my $long_url  = $self->query->param('longurl');
    my $short_url  = $self->query->param('shorturl');
    my $new_short_url = '';
    eval {
	$new_short_url = $self->schema->create_new_short( $long_url, $short_url );
    };
    if ( $@ ) {
	croak "Error when retrieving short URL: $@";
    }
    my $format = $self->query->param('fmt') || '';
    if ( $format eq '' ) {
	if ($new_short_url ne '') {
	    $tmpl->param( short => $self->param('domain')."/".$new_short_url,
			  long => $long_url );
	} else {
	    $tmpl->param( msg => $@ );
	}
	return $tmpl->output;
    } elsif ( $format eq 'JSON' ) {
	my $json;
	if ($new_short_url ne '') {
	    $json = to_json( { shortu =>  $self->param('domain')."/".$new_short_url,
			       longu => $long_url} );
	} else {
	    $json = to_json( {msg => $@} );
	}
	$self->header_props(-type=>'application/json');
	return $json;
    }
    
}

sub redirect_url {
    my $self   = shift;
    my $url = $self->param('url');
    my $long_url =  $self->schema->get_long_for( $url );
    if ( $long_url ) {
	return $self->redirect("http://".$long_url );
    } else {
	my $tmpl = $self->load_tmpl;
	$tmpl->param( domain => $self->param('domain'),
		      shorturl => $url );
	return $tmpl->output;
    }

}



=head1 NAME

Net::Lujoyglamour::WebApp - Use URL shortener from the web


=head1 SYNOPSIS

    use Net::Lujoyglamour;

    my $app = new Net::Lujoyglamour::WebApp 
        PARAMS => { dsn => $dsn},
        TMPL_PATH => '/luxury/path/to/templates';

    $app->run();

If you want this to work as an URL redirector, you'll have to first
    have mod_rewrite activated, and then write something like this in
    your .htaccess
    RewriteEngine on
    Options +FollowSymlinks
    DirectoryIndex /cgi-bin/lg/lg.cgi
    RewriteRule ^(\w+)$ /cgi-bin/lg/lg.cgi?rm=redirect&url=$1

Change, ofcourse, that path to the path your CGI resides.

=head1 DESCRIPTION

Configure a L<CGI::Application> module for using L<Net::Lujoyglamour>
    from the web.

=head1 INTERFACE 

Mostly intended for using internally; only thing you need to know is
    C<run> and C<new>; however, here's the skinny

=head2 new( PARAMS => { dsn => $dsn },
            TMPL_PATH => '/More/glamourous/templates' )

The DSN must point to a working database, and the templates to a
    directory containing C<form.html> and C<geturl.html>
    templates. Examples can be found in the distribution, and you can
    create your own taking into account that:

=over 4

=item C<form.html> must include the form and all its fields, including
    the hidden field

=item C<geturl.html> must include all the L<HTML::Template> commands,
    which will be substituted by variables or an error message

=back

=head2 run

Start to run the web loop

The rest are included mostly to avoid complains from pod-coverage 

=head2 cgiapp_init

Called internally from C<new> to inialize DB and whatever is needed
    for the application

=head2 get_url

Called from the C<geturl> runmode to obtain a new short URL

=head2 redirect_url

Called from the C<redirect> runmode to retrieve a short URL from the
    DB and redirect it

=head2 setup

Setting up run modes

=head2 show_form

Shows the form to obtain a new URL


=head1 DIAGNOSTICS

See L<Net::Lujoyglamour> for errors

=head1 CONFIGURATION AND ENVIRONMENT

See above; don't forget to configure a database and the two
    templates mentioned above.

=head1 DEPENDENCIES

L<CGI::Application> dependencies, plus
    L<CGI::Application::Plugin::DBIx::Class> used for integration with
    L<DBIx::Class> and L<CGI::Application::Plugin::Redirect>
    redirection. 

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-net-lujoyglamour@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

JJ Merelo  C<< <jj@merelo.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, JJ Merelo C<< <jj@merelo.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
