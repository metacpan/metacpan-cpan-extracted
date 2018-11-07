package QBit::WebInterface::Routing;
$QBit::WebInterface::Routing::VERSION = '0.010';
use POSIX qw(strftime setlocale LC_TIME);

use qbit;

use QBit::WebInterface::Routing::Routes;
use QBit::WebInterface::Response;

use base qw(QBit::WebInterface QBit::Application);

sub import {
    my ($package, %opts) = @_;

    $package->SUPER::import(%opts);

    my $package_wi = caller(0);

    die gettext('Use only in QBit::WebInterface and QBit::Application descendant')
      unless $package_wi->isa('QBit::WebInterface')
      && $package_wi->isa('QBit::Application');

    {
        no strict 'refs';

        *{"${package_wi}::build_response"}     = \&build_response;
        *{"${package_wi}::routing"}            = \&routing;
        *{"${package_wi}::exception_handling"} = \&exception_handling;
    }
}

sub routing {
    my ($self, %opts) = @_;

    $self->{'__ROUTING__'} = QBit::WebInterface::Routing::Routes->new(%opts);

    return $self->{'__ROUTING__'};
}

sub build_response {
    my ($self) = @_;

    $self->pre_run();

    throw gettext('No request object') unless $self->request;
    $self->response(QBit::WebInterface::Response->new());

    my $cmds = $self->get_cmds();

    my $path   = '';
    my $cmd    = '';
    my %params = ();

    if ($self->{'__ROUTING__'}) {
        my $route = $self->{'__ROUTING__'}->get_current_route($self);

        if (exists($route->{'handler'})) {
            $path = '__HANDLER_PATH__';
            $cmd  = '__HANDLER_CMD__';

            my $package = $self->get_option('controller_class', 'QBit::WebInterface::Controller');

            my $imported = $self->{'__IMPORTED__'}{$package};

            foreach my $p (keys(%$cmds)) {
                last if $imported;

                foreach my $c (keys(%{$cmds->{$p}})) {
                    if ($cmds->{$p}{$c}{'package'} eq $package) {
                        $imported = TRUE;

                        last;
                    }
                }
            }

            unless ($imported) {
                my $req_package = $package . '.pm';
                $req_package =~ s/::/\//g;

                require $req_package;

                $package->import();

                $self->{'__IMPORTED__'}{$package} = TRUE;
            }

            $cmds->{$path}{$cmd} = {
                'package'        => $package,
                'sub'            => $route->{'handler'},
                'type'           => $route->{'type'} // 'CMD',
                'process_method' => $route->{'process_method'},
                'attrs'          => {map {$_ => TRUE} @{$route->{'attrs'} // []}}
            };
        } else {
            $path = $route->{'path'} // '';
            $cmd  = $route->{'cmd'} // '';
        }

        %params = %{$route->{'args'} // {}};
    }

    if ($self->get_option('use_base_routing') && !(length($path) || length($cmd))) {
        ($path, $cmd) = $self->get_cmd();

        $cmd = $cmds->{$path}{'__DEFAULT__'}{'name'} if $cmd eq '';
        $cmd = '' unless defined($cmd);
    }

    $self->set_option(cur_cmd     => $cmd);
    $self->set_option(cur_cmdpath => $path);

    if ($self->{'__EXCEPTION_IN_ROUTING__'}) {
        #nothing do...
    } elsif (exists($cmds->{$path}{$cmd})) {
        try {
            my $cmd = $cmds->{$path}{$cmd};

            my $controller = $cmd->{'package'}->new(
                app   => $self,
                path  => $path,
                attrs => $cmd->{'attrs'}
            );

            $self->{'__BREAK_PROCESS__'} = 0;
            $self->pre_cmd($controller);

            unless ($self->{'__BREAK_PROCESS__'}) {
                $controller->{'__BREAK_CMD__'} = FALSE;
                $controller->pre_cmd() if $controller->can('pre_cmd');

                unless ($controller->{'__BREAK_CMD__'}) {
                    if ($controller->attrs()->{'SAFE'}) {
                        throw Exception::WebInterface::Controller::CSRF gettext('CSRF has been detected')
                          unless $controller->check_anti_csrf_token(
                            $self->request->param(sign => $params{'sign'} // ''),
                            url => $self->get_option('cur_cmdpath') . '/' . $self->get_option('cur_cmd'));
                    }

                    my @data = $cmd->{'sub'}($controller, %params);
                    if (defined(my $method = $cmd->{'process_method'})) {
                        $controller->$method(@data);
                    }
                }
            }

            $self->post_cmd();
        }
        catch Exception::Denied with {
            $self->response->status(403);
            $self->response->data(undef);
        }
        catch Exception::Request::UnknownMethod with {
            $self->response->status(400);
            $self->response->data(undef);
        }
        catch {
            $self->exception_handling(shift);
        };
    } else {
        $self->response->status(404);
    }

    my $ua = $self->request->http_header('User-Agent');
    $self->response->headers->{'Pragma'} = ($ua =~ /MSIE/) ? 'public' : 'no-cache';

    $self->response->headers->{'Cache-Control'} =
      ($ua =~ /MSIE/)
      ? 'must-revalidate, post-check=0, pre-check=0'
      : 'no-cache, no-store, max-age=0, must-revalidate';

    my $tm   = time();
    my $zone = (strftime("%z", localtime($tm)) + 0) / 100;
    my $loc  = setlocale(LC_TIME);
    setlocale(LC_TIME, 'en_US.UTF-8');
    my $GMT = strftime("%a, %d %b %Y %H:%M:%S GMT", localtime($tm - $zone * 3600));
    setlocale(LC_TIME, $loc);

    $self->response->headers->{'Expires'} = $GMT;

    $self->post_run();

    $self->response->timelog($self->timelog);
}

sub exception_handling {
    my ($self, $exception) = @_;

    if (my $dir = $self->get_option('error_dump_dir')) {
        require File::Path;
        File::Path::make_path($dir);
        writefile("$dir/dump_" . format_date(curdate(), '%Y%m%d_%H%M%S') . "${$}.html",
            $self->_exception2html($exception));
        $self->response->status(500);
        $self->response->data(undef);
    } else {
        if (($self->request->http_header('Accept') || '') =~ /(application\/json|text\/javascript)/) {
            $self->response->content_type("$1; charset=UTF-8");
            $self->response->data(to_json({error => $exception->message()}));
        } else {
            $self->response->data($self->_exception2html($exception));
        }
    }
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::WebInterface::Routing - Class for creating routing for web interface.

=head1 GitHub

https://github.com/QBitFramework/QBit-WebInterface-Routing

=head1 Deprecated

See L<QBit::WebInterface|https://github.com/QBitFramework/QBit-WebInterface>

=head1 Install

=over

=item *

cpanm QBit::WebInterface::Routing

=back

For more information. please, see code.

=cut
