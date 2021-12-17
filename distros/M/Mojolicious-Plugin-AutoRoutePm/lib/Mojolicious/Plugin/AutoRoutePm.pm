package Mojolicious::Plugin::AutoRoutePm;
$Mojolicious::Plugin::AutoRoutePm::VERSION = '0.23';
use Mojo::Base 'Mojolicious::Plugin';

use File::Find::Rule;
use Mojo::Loader qw(load_class);

sub register {
    my ( $self, $app, $conf ) = @_;

    # default index
    my $dindex = $conf->{default_index} || 'index';

    # Parent route
    my $r = $conf->{route} || [ $app->routes ];

    # Excluded routes
    my $exclude = $conf->{exclude} || [];

    #  my %exclude	= map {$_ => 1} @$exclude;

    # Template Base
    my $system_template_base_dirs = $app->renderer->paths;

    # by default renderer->paths appends templates to base_app_path
    # removing it we got the base path
    my $template_base_dirs = [];
    foreach (@$system_template_base_dirs) {
        my $tmpl_base_dir = $_;   # so next replace doesn't affect origianl path
        $tmpl_base_dir =~ s/templates$//;
        push @$template_base_dirs, $tmpl_base_dir;
    }

    # Top directory
    my $top_dir = $conf->{top_dir} || '.';
    $top_dir =~ s#^/##;
    $top_dir =~ s#/$##;

    # Search templates
    my @templates;
    for my $template_base_dir (@$template_base_dirs) {
        $template_base_dir =~ s#/$##;
        my $template_dir = "$template_base_dir/$top_dir";

        if ( -d $template_dir ) {

            # Find templates
            my $rules = File::Find::Rule->file()->name('*.pm')->relative(0)
              ->start($template_dir);
            while ( defined( my $file = $rules->match ) ) {
                $file =~ s/\.pm$//;
                my $excluded = 0;
                foreach (@$exclude) {
                    $excluded = 1 if ( $file =~ /$_/ );
                }
                push @templates, $file unless ($excluded);
            }

        }
    }

    # arrange templates so first existing .pm module which aren't DocumentRoot
    # sort so longer path come first so existing subfolder have major priority
    my @template_index = sort { length($b) cmp length($a) } grep /$dindex$/,
      @templates;
    my @template_nindex = sort { length($b) cmp length($a) } grep !/$dindex$/,
      @templates;
    @templates = ( @template_nindex, @template_index );

    # Register routes
    for my $template (@templates) {

        # Route
        my $ctl = $self->path_to_controller($template);
        load_class $ctl;
        if ( $ctl->isa('Mojolicious::Controller') ) {
            $template = "/$template";
            my $route  = $self->get_best_matched_route( $template, $r );
            my $routep = $route->to_string;
            $template =~ s/^$routep//;

            # support for /url_component/index
            my $tr = $route->any( $template => [ format => 1 ] )
              ->to( app => $ctl, action => 'route', format => undef );
            $tr->any('');

            # and for /url_component/index/a/b/x
            $tr->any('/*query');
            if ( $template =~ s/$dindex$// ) {

                # support for /url_component
                my $tr = $route->any( $template => [ format => 1 ] )
                  ->to( app => $ctl, action => 'route', format => undef );
                $tr->any('/');

                # and for /url_component/a/b/x
                $tr->any('/*query');
            }
        }
    }
}

sub get_best_matched_route {
    my $s   = shift;
    my $url = shift;

    my $routes = shift;

    my @ret;

    foreach my $r (@$routes) {
        push @ret, $r
          if ( substr( $url, 0, length( $r->to_string ) ) eq $r->to_string );
    }

    return $ret[0] if ( scalar(@ret) == 1 );    # only one

    # more than one
    my $ret = $ret[0];
    foreach my $r (@ret) {
        $ret = $r if ( length( $r->name ) > length( $ret->name ) );
    }
    return $ret;
}

sub path_to_controller {
    my $s   = shift;
    my $url = shift;

    $url =~ s{^/}{};
    $url =~ s{/}{::}g;
    $url =~ s{\.(.*?)$}{};

    return $url;
}

1;

=pod

=head1 NAME

Mojolicious::Plugin::AutoRoutePm - Mojolicious plugin to create routes by *.pm modules which are a controller

=for html <p>
    <a href="https://github.com/EmilianoBruni/mojolicious-plugin-autoroutepm/actions/workflows/test.yml">
        <img alt="github workflow tests" src="https://github.com/EmilianoBruni/mojolicious-plugin-autoroutepm/actions/workflows/test.yml/badge.svg">
    </a>
    <img alt="Top language: " src="https://img.shields.io/github/languages/top/emilianobruni/mojolicious-plugin-autoroutepm">
    <img alt="github last commit" src="https://img.shields.io/github/last-commit/emilianobruni/mojolicious-plugin-autoroutepm">
</p>

=head1 VERSION

version 0.23

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin 'AutoRoutePm', {
        route   => [ app->routes ],
        top_dir => 'site',
    };

=head1 DESCRIPTION

This module recursive passes through template_base_dir to find perl modules
(*.pm) that are a subclass of Mojolicious::Controller and adds routes for them.

=encoding UTF-8

=head1 USAGE

For module X::Y::Z it adds the decamelize version

  x/y/z
  x/y/z/index
  x/y/z/index/*query

all redirect to action route inside module.

If Z is default_index it adds also

  x/y
  x/y/*query

The last structure is useful for routing seach. But be careful to correct
relative urls of other items in html page.

This can be done in many ways. One is, as an example, to add to the layout
a base_url like this

  % my $base_url = url_for(undef, {query => undef}); $base_url =~ s|/$||;
  <base href="<%= $base_url %>" />

=head2 register

  plugin->register($app);

Register plugin in L<Mojolicious> application.

=head1 BUGS/CONTRIBUTING

Please report any bugs through the web interface at L<https://github.com/EmilianoBruni/mojo-websocket-pubsub/issues>
If you want to contribute changes or otherwise involve yourself in development, feel free to fork the Git repository from
L<https://github.com/EmilianoBruni/mojo-websocket-pubsub/>.

=head1 SUPPORT

You can find this documentation with the perldoc command too.

    perldoc Mojo::WebSocket::PubSub

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Mojolicious plugin to create routes by *.pm modules which are a controller



