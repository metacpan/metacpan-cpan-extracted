package Muster;
$Muster::VERSION = '0.92';
# ABSTRACT: web application for content management
=head1 NAME

Muster - web application for content management

=head1 VERSION

version 0.92

=head1 SYNOPSIS

    use Muster;

=head1 DESCRIPTION

Content management system; muster your pages.
This uses
Mojolicious
Mojolicious::Plugin::Foil

=cut

use Mojo::Base 'Mojolicious';
use Muster::Assemble;
use Path::Tiny;
use File::ShareDir;

# This method will run once at server start
sub startup {
    my $self = shift;

    # -------------------------------------------
    # Configuration
    # check:
    # * current working directory
    # * relative to the calling program
    # -------------------------------------------
    my $the_prog = path($0)->absolute;
    my $conf_basename = "muster.conf";
    my $conf_file = path(Path::Tiny->cwd, $conf_basename);
    if (! -f $conf_file)
    {
        $conf_file = path($the_prog->parent->stringify, $conf_basename);
        if (! -f $conf_file)
        {
            $conf_file = path($the_prog->parent->parent->stringify, $conf_basename);
        }
    }
    # the MUSTER_CONFIG environment variable overrides the default
    if (defined $ENV{MUSTER_CONFIG} and -f $ENV{MUSTER_CONFIG})
    {
        $conf_file = $ENV{MUSTER_CONFIG};
    }
    print STDERR "Muster::VERSION=$Muster::VERSION CONFIG: $conf_file\n";
    my $mojo_config = $self->plugin('Config' => { file => $conf_file });

    # -------------------------------------------
    # New commands in Muster::Command namespace
    # -------------------------------------------
    push @{$self->commands->namespaces}, 'Muster::Command';

    # -------------------------------------------
    # Append public directories
    # Find the Muster "public" directory
    # It could be relative to the CWD
    # It could be relative to the calling program
    # It could be in a FileShared location.
    my $pubdir = path(Path::Tiny->cwd, "public");
    if (!-d $pubdir)
    {
        $pubdir = path($the_prog->parent->stringify, "public");
        if (!-d $pubdir)
        {
            # use File::ShareDir with the distribution name
            my $dist = __PACKAGE__;
            $dist =~ s/::/-/g;
            my $dist_dir = path(File::ShareDir::dist_dir($dist));
            $pubdir = $dist_dir;
        }
    }
    if (-d $pubdir)
    {
        # this takes priority over the default public dir
        unshift @{$self->static->paths}, $pubdir;
    }
    # -------------------------------------------
    # Cache
    # -------------------------------------------
    if (!$mojo_config->{cache_dir})
    {
        $mojo_config->{cache_dir} = path(Path::Tiny->cwd, "cache")->stringify;
    }
    my $cache_dir = path($mojo_config->{cache_dir})->absolute;
    # create the cache dir if it's not there
    if (!-d $cache_dir)
    {
        if (-d -w $cache_dir->parent->stringify)
        {
            mkdir $cache_dir;
        }
    }
    if (!-d -w $cache_dir)
    {
        die "cache dir '$cache_dir' not writable";
    }
    push @{$self->static->paths}, $cache_dir->stringify;

    # -------------------------------------------
    # Pages
    # -------------------------------------------
    $self->plugin('Muster::PagesHelper');
    
    $self->plugin('Foil');
    #$self->plugin(NYTProf => $mojo_config);

    # -------------------------------------------
    # Templates
    # -------------------------------------------
    push @{$self->renderer->classes}, __PACKAGE__;

    # -------------------------------------------
    # secrets, cookies and defaults
    # -------------------------------------------
    $self->secrets([qw(aft3CoidIttenImtuj)]);
    $self->sessions->cookie_name('muster');
    $self->sessions->default_expiration(60 * 60 * 24 * 3); # 3 days
    foreach my $key (keys %{$self->config->{defaults}})
    {
        $self->defaults($key, $self->config->{defaults}->{$key});
    }

    # -------------------------------------------
    # Rendering
    # -------------------------------------------
    $self->{assemble} = Muster::Assemble->new();

    my $do_pagelist = sub {
        my $c  = shift;
        $c->render(template=>'pagelist');
    };
    my $do_page = sub {
        my $c  = shift;
        $self->{assemble}->serve_page($c);
    };
    my $do_meta = sub {
        my $c  = shift;
        $self->{assemble}->serve_meta($c);
    };
    my $do_debug = sub {
        my $c  = shift;

        my $pagename = $c->param('cpath');
        $c->reply->exception("Debug" . (defined $pagename ? " $pagename" : ''));
    };
    my $r = $self->routes;

    $r->get('/' => $do_page);
    $r->get('/pagelist' => $do_pagelist);
    $r->get('/_debug' => $do_debug);
    $r->get('/_debug/*cpath' => $do_debug);
    $r->get('/_meta/*cpath' => $do_meta);
    # anything else should be a page or file
    $r->get('/*cpath' => $do_page);
}

1; # end of Muster

# Here come the TEMPLATES!

__DATA__
@@apperror.html.ep
% layout 'foil';
% content_for 'verso' => begin
<%== muster_sidebar %>
% end
% content_for 'recto' => begin
<%== foil_theme_selector %>
<%== muster_rightbar %>
% end
<h1>Error: <%= param('db') %></h1>
<%== $errormsg %>

@@not_found.html.ep
% layout 'foil';
% content_for 'verso' => begin
<%== muster_sidebar %>
% end
% content_for 'recto' => begin
<%== foil_theme_selector %>
<%== muster_rightbar %>
% end
<h1>Not Found</h1>
<p>Page <%= param 'cpath' %> not found <%= $status %></p>

@@page.html.ep
% layout 'foil';
% content_for 'head_extra' => begin
<link rel="stylesheet" href="<%= url_for('/css') %>/muster.css" type="text/css" />
<%== $head_append %>
% end
% content_for 'verso' => begin
<%== muster_sidebar %>
% end
% content_for 'recto' => begin
<%== foil_referrer %>
<%== foil_theme_selector %>
<%== muster_rightbar %>
% end
<%== $content %>

@@page.txt.ep
% layout 'bare';
<%== $content %>

@@pagelist.html.ep
% layout 'foil';
% content_for 'head_extra' => begin
<link rel="stylesheet" href="<%= url_for('/css') %>/muster.css" type="text/css" />
<%== $head_append %>
% end
% content_for 'verso' => begin
<%== muster_sidebar %>
% end
% content_for 'recto' => begin
<%== foil_referrer %>
<%== foil_theme_selector %>
<%== muster_rightbar %>
% end
<h1>Page List:</h1>
<%== muster_pagelist %>

@@ layouts/bare.txt.ep
<%== content %>

@@ layouts/plain.html.ep
<!DOCTYPE html>
<html>
<head>
    <title><%= title %></title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    %= content 'head_extra'
</head>
<body>
<main>
<%== content %>
</main>
</body>
</html>
