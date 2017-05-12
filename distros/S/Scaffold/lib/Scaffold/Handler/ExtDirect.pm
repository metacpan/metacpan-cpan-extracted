package Scaffold::Handler::ExtDirect;

our $VERSION = '0.01';

use 5.8.8;
use Scaffold::Class
  version  => $VERSION,
  base     => 'Scaffold::Handler',
  constant => 'TRUE FALSE ARRAY',
  codec    => 'JSON',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub do_api {
    my ($self) = @_;

    my $code;
    my $json;
    my $actions;
    my $introspection = $self->introspect();
    my $params = $self->scaffold->request->parameters->mixed();

    foreach my $action (keys %{$instrospection}) {

        my @methods;

        foreach my $method (keys %{$introspection->{$action}}) {

            push(@methods, 
                {
                    name => $method,
                    len  => $introspection->{$action}->{$method}->{params},
                    $introspection->{$action}->{$method}->{formHandler} ? (formHandler => \TRUE) : (),
                }
            );

            $actions->{$action} = \@methods;

        }

    }

    $url = $self->scaffold->request->path_info;
    $url =~ s/api/router/;

    $code = {
        url => $url,
        type => 'remoting',
        actions => $actions,
    }
    $json = encode($code);

    if (($params->{format}) and ($params->{format} eq 'json')) {

        $self->view->content_type('application/json');
        $js = $json;

    } else {

        # Note: This is not JSON, it is actual JavaScript being loaded!
        # Thus the "Ext.app... ="

        $self->view->content_type('text/javascript');
        $js = 'Ext.app.REMOTING_API = ' . $json;

    }

    $self->view->data($js);
    $self->view->template_disable(TRUE);

}

sub do_router {
    my ($self) = @_;

    my $datum;
    my @results;
    my $type = 'JSON';
    my $params = $self->scaffold->request->params;

    if ($params->{POSTDATA}) {

        $datum = decode(params->{POSTDATA});
        $datum = [ $datum ] if (ref($datum) ne ARRAY);

    } else {

        $type = 'FORM';
        $datum = [
            {
                action => delete($params->{extAction}),
                method => delete($params->{extMethod}),
                tid    => delete($params->{extTID}),
                type   => delete($params->{extType}),
                upload => delete($params->{extUpload}),
                data   => [ $params ]
            }
        ];

    }

    foreach my $request (@$datum) {

        my $action = $request->{action};
        my $method = $request->{method};
        my $data   = $request->{data};

        my $status = {
            type   => 'rpc',
            tid    => $request->{tid},
            action => $action,
            method => $method,
        };

        if ($self->can($method)) {

            try {

                $status->{result} = $self->$method(ref($data) eq ARRAY ? @$data : ());

            } catch {
		
                my $ex = $_;
                my $ref = ref($ex);

                $status->{type} = 'exception';

                if ($ref && $ex->isa('Badger::Exception')) {

                    $status->{message} = $ex->info;
                    $status->{where}   = $ex->type;

                } else {

                    $status->{message} => sprintf("%s", $ex);
                    $status->{where}   => "Action: $action";

                }

            };

        } else {

            $status->{type}    => 'exception';
            $status->{message} => "Unknown method: $method";
            $status->{where}   => "Action: $action";

        }

        push(@results, $status);

    }

    # Return JSON or textarea wrapped HTML and JSON data.

    if ($type eq 'UPLOAD') {

        my $html = qq(
            <html><body><textarea>
            encode(\@results);
            </textarea></body></html>
        );

        $self->view->data($html);
        $self->view->template_disable(TRUE);

    } else {

        $self->view->data(encode(\@results));
        $self->view->template_disable(TRUE);
        $self->view->content_type('application/json');

    }

}

sub introspect {
    my ($self) = @_;

    # Note on conventions
    #
    # Keys are currently case sensitive
    #    "Action" is passed in from Ext.Direct call
    #    "Method" is passed in from Ext.Direct call (and also must match 
    #             a Perl method)
    #
    # List of classes by name
    #

    my $methods = {
        Test => {
            Methods => {
                echo => { params => 1 },
            },
        },
    };

    return $methods;

};

sub echo {
    my ($self, $in) = @_;

    return $in;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

Scaffold::Handler::ExtDirect - A handler for Ext.Direct RPC requests

=head1 SYNOPSIS

 use Scaffold::Server;

 my $server = Scaffold::Server->new(
    configs => {
        doc_rootp => 'html',
    },
    locations => [
        {
            route   => qr{^/$},
            handler => 'App::Main'
        },{ 
            route   => qr{^/robots.txt$},
            handler => 'Scaffold::Handler::Robots',
        },{
            route   => qr{^/favicon.ico$},
            handler => 'Scaffold::Handler::Favicon',
        },{
            route   => qr{^/static/(.*)$},
            handler => 'Scaffold::Handler::Static',
        },{
            route   => qr{^/rpc$},
            handler => 'Scaffold::Handler::ExtDirect',
        }
    ] 
 );

=head1 DESCRIPTION

=head1 SEE ALSO

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
