package Mojolicious::Plugin::Mason2Renderer;

use warnings;
use strict;

use Mojo::Base 'Mojolicious::Plugin';

use Mason;
use Mason::Interp;
use Mason::Request;
use Mason::Result;
use Encode;

=head1 NAME

Mojolicious::Plugin::Mason2Renderer - Mason 2 (aka Mason 2.x) Renderer Plugin.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  ## Mojolicious::Lite

  # example -1-
    use Mojolicious::Lite;
    plugin 'mason2_renderer';
    get '/' => sub {
        my $self = shift;
        $self->render('/index', handler => "mason" );
    };
    app->start;

    # template: MOJO_HOME/mason/index.mc
    <html>
      <body>Welcome</body>
    </html>

  # example -2-
    use Mojolicious::Lite;
    plugin 'mason2_renderer' => { preload_regexps => [ '.mc$', '/path/to/comps/to/preload', ... ],
                                  interp_params   => { comp_root => "/path/to/mason/comps",
                                                       ... (other parameters to the new() Mason::Interp constructor)
                                                     },
                                  request_params  => { ... (other parameters to the new() Mason::Request constructor)
                                                     },
    };
    get '/' => sub {
        my $self = shift;
        $self->render('/index', handler => "mason", mytext => "Hello world" );
    };
    app->start;

    # template: /path/to/mason/comps/index.mc
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
      $self->plugin('mason2_renderer');
      $self->routes->get('/' => sub {
          my $self = shift;
          $self->render('/index', handler => "mason" );
        }
      );
    }
    1;

    # template: MOJO_HOME/mason/index.mc
    <html>
      <body>Welcome</body>
    </html>

  # example -2-
    package MyApp;
    use Mojo::Base 'Mojolicious';

    sub startup {
      my $self = shift;
      $self->plugin('mason2_renderer', { preload_regexps => [ '.mc$', '/path/to/comps/to/preload', ... ],
                                         interp_params   => { comp_root => "/path/to/mason/comps",
                                                              ... (other parameters to the new() Mason::Interp constructor)
                                                            },
                                         request_params  => { ... (other parameters to the new() Mason::Request constructor)
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

    # template: /path/to/mason/comps/index.mc
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

L<Mojolicous::Plugin::Mason2Renderer> is a renderer for L<Mason> 2 (aka L<Mason> 2.x) template system.

=head2 Mojolicious::Controller object aka. $c

Mason templates have access to the L<Mojolicious::Controller> object as global $c.

=head2 Mason comp_root

C<comp_root> is set to default "MOJO_HOME/mason"


=head1 METHODS

L<Mojolicious::Plugin::Mason2Renderer> inherits all methods from L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register;

Register renderer in L<Mojolicious> application.

=cut

sub register {
    my ($self, $app, $conf) = @_;

    # Config
    $conf ||= {};

    # Mason::Interp params
    $conf->{interp_params}->{comp_root} ||= $app->home->rel_dir('mason');
    
    my @allow_globals = ('$c', @{$conf->{interp_params}->{allow_globals} || []});
    $conf->{interp_params}->{allow_globals} = \@allow_globals;


    # make Mason::Interp
    my $interp = Mason->new(%{$conf->{interp_params}});


    # preload comps ?
    if( (defined $conf->{preload_regexps}) && (ref($conf->{preload_regexps}) eq "ARRAY") ) {
	foreach my $regexp (@{$conf->{preload_regexps}}) {
	    foreach my $comp ($interp->all_paths) {
		next if($comp=~/.+~$/);
		$interp->load($comp) if($comp =~ /$regexp/);
	    }
	}
    }


    # Mason::Request params
    $conf->{request_params} ||= {};

    my $request_params = $conf->{request_params};


    # Add "mason" handler
    $app->renderer->add_handler(
	mason => sub {
	    my ($r, $c, $output, $options) = @_;

	    # check $interp object
	    if(not $interp) {
		$c->app->log->error("Mason::Interp not initialized");
		$c->render_exception("Mason::Interp not initialized");
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


	    # call Mason interpreter
	    $request_params->{out_method} = $output;
	    my $result = $interp->run( $request_params, $template, %{$stash});

	    if(not $result) {
		$c->app->log->error("Mason::Request not initialized");
		$c->render_exception("Mason::Request not initialized");
		$$output = "";
		return 0;
	    }
	    

	    # Encoding
            $$output = decode($r->encoding, $$output) if $r->encoding;


	    # All seems OK
	    return 1;
	}
	);

}

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin>, L<http://mojolicio.us>.

Mason 1, L<HTML::Mason>, L<http://www.masonhq.com>.

Mason 2, L<Mason>.

Mason 1 Mojolicious Plugin, L<Mojolicious::Plugin::Mason1Renderer>

=head1 AUTHOR

Alexandre SIMON, C<< <asimon at cpan.org> >>

=head1 BUGS and SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::Mason2Renderer


Bugs and feature requests will be tracked at RT:

    http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-Mason2Renderer
    bug-mojolicious-plugin-mason2renderer at rt.cpan.org

The latest source code can be browsed and fetched at:

    https://github.com/igit/Mojolicious-Plugin-Mason2Renderer
    git clone git://github.com/igit/Mojolicious-Plugin-Mason2Renderer.git


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-Mason2Renderer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-Mason2Renderer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-Mason2Renderer>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-Mason2Renderer/>

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

1; # End of Mojolicious::Plugin::Mason2Renderer
