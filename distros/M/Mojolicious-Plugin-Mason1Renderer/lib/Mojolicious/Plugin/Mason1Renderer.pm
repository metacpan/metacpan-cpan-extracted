package Mojolicious::Plugin::Mason1Renderer;

use warnings;
use strict;

use Mojo::Base 'Mojolicious::Plugin';

use HTML::Mason;
use HTML::Mason::Interp;
use HTML::Mason::Request;
use Encode;

=head1 NAME

Mojolicious::Plugin::Mason1Renderer - Mason 1 (aka HTML::Mason 1.x) Renderer Plugin.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  ## Mojolicious::Lite

  # example -1-
    use Mojolicious::Lite;
    plugin 'mason1_renderer';
    get '/' => sub {
        my $self = shift;
        $self->render('/index', handler => "mason" );
    };
    app->start;

    # template: MOJO_HOME/mason/index
    <html>
      <body>Welcome</body>
    </html>

  # example -2-
    use Mojolicious::Lite;
    plugin 'mason1_renderer' => { interp_params  => { comp_root => "/path/to/mason/comps",
                                                      ... (other parameters to the new() HTML::Mason::Interp constructor)
                                                    },
                                  request_params => { error_format => "brief",
                                                      ... (other parameters to the new() HTML::Mason::Request constructor)
                                                    },
    };
    get '/' => sub {
        my $self = shift;
        $self->render('/index', handler => "mason", mytext => "Hello world" );
    };
    app->start;

    # template: /path/to/mason/comps/index
    <%args>
    $mytext => undef
    </%args>
    <html>
      <body>Welcome : <% $mytext %></body>
    </html>


  ## Mojolicious

  # example -1-
    package MyApp;
    use Mojo::Base 'Mojolicious';

    sub startup {
      my $self = shift;
      $self->plugin('mason1_renderer');
      $self->routes->get('/' => sub {
          my $self = shift;
          $self->render('/index', handler => "mason" );
        }
      );
    }
    1;

    # template: MOJO_HOME/mason/index
    <html>
      <body>Welcome</body>
    </html>

  # example -2-
    package MyApp;
    use Mojo::Base 'Mojolicious';

    sub startup {
      my $self = shift;
      $self->plugin('mason1_renderer', { interp_params  => { comp_root => "/path/to/mason/comps",
                                                             ... (other parameters to the new() HTML::Mason::Interp constructor)
                                                           },
                                         request_params => { error_format => "brief",
                                                             ... (other parameters to the new() HTML::Mason::Request constructor)
                                                           },
                                       }
      );
      $self->routes->get('/' => sub {
          my $self = shift;
          $self->render('/index', handler => "mason", mytext => "Hello World" );
        }
      );
    }
    1;

    # template: /path/to/mason/comps/index
    <%args>
    $mytext => undef
    </%args>
    <html>
      <body>
        Welcome : <% $mytext %><br/>
        Mason root_comp is <% $c->app->home %><br/>
      </body>
    </html>

=head1 DESCRIPTION

L<Mojolicous::Plugin::Mason1Renderer> is a renderer for Mason 1 (aka L<HTML::Mason> 1.x) template system.

=head2 Mojolicious::Controller object aka. $c

Mason templates have access to the L<Mojolicious::Controller> object as global $c.

=head2 HTML::Mason comp_root

C<comp_root> is set to default "MOJO_HOME/mason"


=head1 METHODS

L<Mojolicious::Plugin::Mason1Renderer> inherits all methods from L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register;

Register renderer in L<Mojolicious> application.

=cut

sub register {
    my ($self, $app, $conf) = @_;

    # Config
    $conf ||= {};

    # HTML::Mason::Interp params
    $conf->{interp_params}->{comp_root} ||= $app->home->rel_dir('mason');
    
    my @allow_globals = ('$c', @{$conf->{interp_params}->{allow_globals} || []});
    $conf->{interp_params}->{allow_globals} = \@allow_globals;

    # make HTML::Mason::Interp
    my $interp = HTML::Mason::Interp->new(%{$conf->{interp_params}});


    # HTML::Mason::Request params
    $conf->{request_params} ||= {};
    $conf->{request_params}->{error_format} ||= "brief" if($app->mode eq 'production');

    my $request_params = $conf->{request_params};


    # Add "mason" handler
    $app->renderer->add_handler(
	mason => sub {
	    my ($r, $c, $output, $options) = @_;

	    # check $interp object
	    if(not $interp) {
		$c->app->log->error("HTML::Mason::Interp not initialized");
		$c->render_exception("HTML::Mason::Interp not initialized");
		$$output = "";
		return 0;
	    }

	    # stash contains args to pass to Mason
	    my $stash = $c->stash;

	    # template name
	    return 0 unless my $template = $options->{template};
	    $template =~ s,^/*,/,;  # Mason component must start with /

	    # set global "$c" in Mason environment
	    $interp->set_global('c' => $c);


	    # call HTML::Mason interpreter
	    my $request = $interp->make_request( args       => [%$stash],
						 out_method => $output,
						 comp       => $template,
						 %{$request_params} );

	    if(not $request) {
		$c->app->log->error("HTML::Mason::Request not initialized");
		$c->render_exception("HTML::Mason::Request not initialized");
		$$output = "";
		return 0;
	    }


	    # All seems OK, let's exec Mason's request
	    $request->exec();

	    # Encoding
            $$output = decode($r->encoding, $$output) if $r->encoding;

	    return 1;
	}
	);

}

=head1 SEE ALSO

Mason 1, L<HTML::Mason>, L<http://www.masonhq.com>.

Mason 2, L<Mason>.

Mason 2 Mojolicious Plugin, L<Mojolicious::Plugin::Mason2Renderer>

=head1 AUTHOR

Alexandre SIMON, C<< <asimon at cpan.org> >>

=head1 BUGS and SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::Mason1Renderer


Bugs and feature requests will be tracked at RT:

    http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-Mason1Renderer
    bug-mojolicious-plugin-mason1renderer at rt.cpan.org

The latest source code can be browsed and fetched at:

    https://github.com/igit/Mojolicious-Plugin-Mason1Renderer
    git clone git://github.com/igit/Mojolicious-Plugin-Mason1Renderer.git


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-Mason1Renderer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-Mason1Renderer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-Mason1Renderer>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-Mason1Renderer/>

=back


=head1 ACKNOWLEDGEMENTS

Original idea was taken from Graham BARR (L<http://search.cpan.org/~gbarr/>)
MojoX::Renderer::Mason module. This module was not longer adapted to Mojolicious new
Plugin philosophy.

Many, many thanks to Sebastian RIEDEL for developping Mojolicious and Jonathan SWARTZ
for developping HTML::Mason and Mason (2).

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alexandre SIMON.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Mojolicious::Plugin::Mason1Renderer
