package Scaffold::Render::TT;

our $VERSION = '0.01';

use 5.8.8;
use Template;

use Scaffold::Class
  version  => $VERSION,
  base     => 'Scaffold::Render',
  utils    => 'self_params',
  constant => {
      RENDER => 'scaffold.handler.render',
  }
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub process {
    my ($self, $sobj) = @_;

    my $page;
    my $template = $sobj->stash->view->template_wrapper;
    my $vars = {
        view    => $sobj->stash->view,
        configs => $sobj->scaffold->config('configs'),
    };

    $self->engine->process(
        $template,
        $vars,
        \$page
    ) or $self->throw_msg(RENDER, 'template', $template, $self->engine->error);

    return $page;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my ($self, $config) = self_params(@_);

    $self->{config} = $config;

    # make sure all the config keys are uppercase for TT.

    foreach my $key (keys %$config) {

        $config->{uc($key)} = delete $config->{$key};

    }

    # initialize TT

    $self->{engine} = Template->new(
        $config
    ) or $self->throw_msg(RENDER, 'render', 'TT', $Template::ERROR);

    return $self;

}

1;

__END__

=head1 NAME

Scaffold::Render::TT - Use the Template Toolkit to render pages.

=head1 SYNOPSIS

    my $server = Scaffold::Server->new(
        render => Scaffold::Render::TT->new(
            include_path => 'html:html/resources/templates',
        ),
    );

=head1 DESCRIPTION

This module loads the Template Toolkit as the renderer. It uses any of 
TT's configuration items and passes them thru. It also uppercases any of 
the configuration keywords to make TT happy.

=head1 SEE ALSO

 Template

 Scaffold
 Scaffold::Base
 Scaffold::Cache
 Scaffold::Cache::FastMmap
 Scaffold::Cache::Manager
 Scaffold::Cache::Memcached
 Scaffold::Class
 Scaffold::Constants
 Scaffold::Engine
 Scaffold::Handler
 Scaffold::Handler::Default
 Scaffold::Handler::Favicon
 Scaffold::Handler::Robots
 Scaffold::Handler::Static
 Scaffold::Lockmgr
 Scaffold::Lockmgr::KeyedMutex
 Scaffold::Lockmgr::UnixMutex
 Scaffold::Plugins
 Scaffold::Render
 Scaffold::Render::Default
 Scaffold::Render::TT
 Scaffold::Routes
 Scaffold::Server
 Scaffold::Session::Manager
 Scaffold::Stash
 Scaffold::Stash::Controller
 Scaffold::Stash::Cookie
 Scaffold::Stash::View
 Scaffold::Uaf::Authenticate
 Scaffold::Uaf::AuthorizeFactory
 Scaffold::Uaf::Authorize
 Scaffold::Uaf::GrantAllRule
 Scaffold::Uaf::Login
 Scaffold::Uaf::Logout
 Scaffold::Uaf::Manager
 Scaffold::Uaf::Rule
 Scaffold::Uaf::User
 Scaffold::Utils

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
