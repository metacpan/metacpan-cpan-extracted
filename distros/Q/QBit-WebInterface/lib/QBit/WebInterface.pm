package QBit::WebInterface;
$QBit::WebInterface::VERSION = '0.033';
use qbit;

use POSIX qw(strftime setlocale LC_TIME);
use URI::Escape qw(uri_escape_utf8);

use QBit::WebInterface::Routing;
use QBit::WebInterface::Response;

use Exception::WebInterface::Controller::CSRF;
use Exception::Request::UnknownMethod;

our %HTTP_STATUSES = (
    200 => 'OK',
    201 => 'CREATED',
    202 => 'Accepted',
    203 => 'Partial Information',
    204 => 'No Response',
    301 => 'Moved',
    302 => 'Found',
    303 => 'Method',
    304 => 'Not Modified',
    400 => 'Bad request',
    401 => 'Unauthorized',
    402 => 'PaymentRequired',
    403 => 'Forbidden',
    404 => 'Not found',
    500 => 'Internal Error',
    501 => 'Not implemented',
    502 => 'Service temporarily overloaded',
    503 => 'Gateway timeout',
);

sub request {
    my ($self, $request) = @_;

    return defined($request) ? $self->{'__REQUEST__'} = $request : $self->{'__REQUEST__'};
}

sub response {
    my ($self, $response) = @_;

    return defined($response) ? $self->{'__RESPONSE__'} = $response : $self->{'__RESPONSE__'};
}

sub routing {
    my ($self, %opts) = @_;

    $self->{'__ROUTING__'} = QBit::WebInterface::Routing->new(%opts);

    return $self->{'__ROUTING__'};
}

sub get_cmds {
    my ($self) = @_;

    unless (exists($self->{'__ALL_CMDS__'})) {
        my $cmds           = {};
        my @cmd_with_route = ();
        package_merge_isa_data(
            ref($self),
            $cmds,
            sub {
                my ($package, $res) = @_;

                my $pkg_cmds = package_stash($package)->{'__CMDS__'} || {};
                foreach my $path (keys(%$pkg_cmds)) {
                    foreach my $cmd (keys(%{$pkg_cmds->{$path}})) {
                        $cmds->{$path}{$cmd} = $pkg_cmds->{$path}{$cmd};

                        $self->{'__IMPORTED_CONTROLLERS__'}{$cmds->{$path}{$cmd}{'package'}} = TRUE;

                        if ($cmds->{$path}{$cmd}{'attributes'}{'URL'}) {
                            push(
                                @cmd_with_route,
                                {
                                    path         => $path,
                                    cmd          => $cmd,
                                    route_params => $cmds->{$path}{$cmd}{'route_params'}
                                }
                            );
                        }
                    }
                }
            },
            __PACKAGE__
        );

        if (defined($self->{'__ROUTING__'})) {
            my $package = $self->get_option('controller_class', 'QBit::WebInterface::Controller');

            unless ($self->{'__IMPORTED_CONTROLLERS__'}{$package}) {
                require_class($package);
                $package->import(app_pkg => ref($self));

                $self->{'__IMPORTED_CONTROLLERS__'}{$package} = TRUE;
            }

            $self->{'__ROUTING__'}->create_handler_cmds($package, $cmds);
        }

        if (@cmd_with_route) {
            my $routing = $self->{'__ROUTING__'};

            unless (defined($routing)) {
                $routing = $self->routing();
            }

            foreach (@cmd_with_route) {
                $routing->_generate_route(@{$_->{'route_params'}})->to(path => $_->{'path'}, cmd => $_->{'cmd'});
            }
        }

        $self->{'__ALL_CMDS__'} = $cmds;
    }

    return $self->{'__ALL_CMDS__'};
}

sub build_response {
    my ($self) = @_;

    $self->pre_run();

    throw Exception gettext('No request object') unless $self->request;
    $self->response(QBit::WebInterface::Response->new());

    try {
        my $cmds = $self->get_cmds();
        my ($path, $cmd_name, %params) = $self->get_cmd();

        $cmd_name = $cmds->{$path}{'__DEFAULT__'}{'name'} if $cmd_name eq '';
        $cmd_name = '' unless defined($cmd_name);

        $self->set_option(cur_cmd     => $cmd_name);
        $self->set_option(cur_cmdpath => $path);

        if (exists($cmds->{$path}{$cmd_name})) {
            my $cmd = $cmds->{$path}{$cmd_name};

            my $controller = $cmd->{'package'}->new(
                app   => $self,
                path  => $path,
                attrs => $cmd->{'attributes'}
            );

            $self->{'__BREAK_PROCESS__'} = 0;
            $self->pre_cmd($controller);

            unless ($self->{'__BREAK_PROCESS__'}) {
                $controller->{'__BREAK_CMD__'} = FALSE;
                $controller->pre_cmd() if $controller->can('pre_cmd');

                unless ($controller->{'__BREAK_CMD__'}) {
                    if ($cmd->{'attributes'}{'SAFE'}) {
                        throw Exception::WebInterface::Controller::CSRF gettext('CSRF has been detected')
                          unless $controller->check_anti_csrf_token($self->request->param(sign => ''),
                            url => $self->get_option('cur_cmdpath') . '/' . $self->get_option('cur_cmd'));
                    }

                    my @data = $cmd->{'sub'}->($controller, %params);
                    if (defined(my $method = $cmd->{'process_method'})) {
                        $controller->$method(@data);
                    }
                }
            }

            $self->post_cmd();
        } else {
            $self->response->status(404);
        }
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
        ldump(@_);
        $self->_catch_internal_server_error(@_);
    };

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

sub break {
    my ($self, @data) = @_;

    $self->{'__BREAK_PROCESS__'} = 1;
    return @data;
}

sub form_fields { }

sub pre_cmd { }

sub post_cmd { }

sub default_cmd {throw 'Abstract metod'}

sub get_cmd {
    my ($self) = @_;

    my ($path, $cmd, %params);
    if (defined($self->{'__ROUTING__'})) {
        my $route = $self->{'__ROUTING__'}->get_current_route($self);

        $path = $route->{'path'} // '';
        $cmd  = $route->{'cmd'} // '';

        %params = %{$route->{'args'} // {}};

        if (length($path) || length($cmd) || !$self->get_option('use_base_routing')) {
            return ($path, $cmd, %params);
        }
    }

    if ($self->request->uri() =~ /^\/([^?\/]+)(?:\/([^\/?#]+))?/) {
        ($path, $cmd) = ($1, $2);
    } else {
        ($path, $cmd, %params) = $self->default_cmd();
    }

    $path = '' unless defined($path);
    $cmd  = '' unless defined($cmd);

    return ($path, $cmd, %params);
}

sub make_cmd {
    my ($self, $new_cmd, $new_path, @params) = @_;

    my %vars = defined($params[0])
      && ref($params[0]) eq 'HASH' ? %{$params[0]} : @params;

    my ($path, $cmd) = $self->get_cmd();

    $path = uri_escape_utf8($self->_get_new_path($new_path, $path));
    $cmd = uri_escape_utf8($self->_get_new_cmd($new_cmd, $cmd));

    return "/$path/$cmd"
      . (
        %vars
        ? '?'
          . join(
            $self->get_option('link_param_separator', '&amp;'),
            map {uri_escape_utf8($_) . '=' . uri_escape_utf8($vars{$_})} keys(%vars)
          )
        : ''
      );
}

sub _get_new_cmd {
    my ($self, $new_cmd, $cur_cmd) = @_;

    $cur_cmd = '' unless defined($cur_cmd);

    return defined($new_cmd) ? $new_cmd : $cur_cmd;
}

sub _get_new_path {
    my ($self, $new_path, $cur_path) = @_;

    $cur_path = '' unless defined($cur_path);

    return defined($new_path) && length($new_path) ? $new_path : $cur_path;
}

sub _escape_filename {
    my ($self, $filename) = @_;

    $filename =~ s{"}{\\"}g;
    $filename =~ s{\r}{}g;
    $filename =~ s{\n}{}g;

    return $filename;
}

sub _catch_internal_server_error {
    my ($self, $exception) = @_;

    if (my $dir = $self->get_option('error_dump_dir')) {
        require File::Path;
        File::Path::make_path($dir);
        writefile("$dir/dump_" . format_date(curdate(), '%Y%m%d_%H%M%S') . "${$}.html",
            $self->_exception2html($exception));
        $self->response->status(500);
        $self->response->data(undef);
    } else {
        $self->response->status(200);
        if (($self->request->http_header('Accept') || '') =~ /(application\/json|text\/javascript)/) {
            $self->response->content_type("$1; charset=UTF-8");
            $self->response->data(to_json({error => gettext('Internal Server Error: %s', $exception->message())}));
        } else {
            $self->response->data($self->_exception2html($exception));
        }
    }
}

sub _exception2html {
    my ($self, $exception) = @_;

    my $server = `hostname -f`;
    chomp($server);

    my $short_dumper = sub {
        my ($data, $max_depth) = @_;
        local $Data::Dumper::Maxdepth = $max_depth;
        local $Data::Dumper::Varname  = '';
        local $Data::Dumper::Sortkeys = TRUE;
        my $dtext = Dumper($data);

        $dtext =~ /^(\$\d+ = )/;
        my $prefix_length = $1 ? length($1) : 0;
        $dtext =~ s/^.{$prefix_length}//mg;

        $dtext =~ s/\\x\{([a-f0-9]{2,})\}/chr(hex($1))/ge;
        $dtext =~ s/;$//msg;
        $dtext =~ s/\n$//msg;
        utf8::decode($dtext);

        return $dtext;
    };

    my $html =
        '<html>'
      . '<head>'
      . '<meta http-equiv="content-type" content="text/html; charset=UTF-8">'
      . '<title>'
      . gettext('Fatal error')
      . '</title>'
      . '</head>'
      . '<body bgcolor="#FFFFFF" text="#000000">'

      . '<div style="background-color: #CCFF99; padding: 5px 10px; margin: 1px;">' . '<h3>'
      . gettext('Server') . ': '
      . html_encode($server) . '</h3>'
      . '<strong>'
      . gettext('Host')
      . ':</strong> '
      . html_encode($self->request->http_header('host')) . '<br>'
      . '<strong>'
      . gettext('Date')
      . ':</strong> '
      . html_encode(format_date(curdate(), '%c')) . '<br>'
      . '</div>'

      . '<div style="background-color: #FF7777; font-size: 110%; padding: 5px 10px; margin: 1px;">' . '<h3>'
      . html_encode(ref($exception)) . '</h3>'
      . '<h4><pre>'
      . html_encode($exception->{'text'})
      . '</pre></h4>'
      . '<strong>'
      . gettext('Package')
      . ':</strong> '
      . html_encode($exception->{'package'}) . '<br>'
      . '<strong>'
      . gettext('Filename')
      . ':</strong> '
      . html_encode($exception->{'filename'}) . ' ('
      . gettext('line') . ' '
      . html_encode($exception->{'line'}) . ')<br>'
      . '</div>'

      . '<div style="background-color: #EEAA77; padding: 5px 10px; margin: 1px;">' . '<h3>'
      . gettext('Request')
      . ':</h3>'
      . '<table width="100%">'
      . '<tr><th valign="top" align="right">'
      . gettext('Method')
      . '</th><td>'
      . html_encode($self->request->method)
      . '</td></tr>'
      . '<tr><th valign="top" align="right">'
      . gettext('URL')
      . '</th><td>'
      . html_encode($self->request->url)
      . '</td></tr>'
      . join(
        '',
        map {
                '<tr><th valign="top" nowrap="nowrap" align="right">'
              . html_encode($_->[1])
              . '</th><td>'
              . html_encode($self->request->http_header($_->[0]) || '')
              . '</td></tr>'
        } (
            [referer           => gettext('Referer')],
            ['user-agent'      => gettext('User agent')],
            ['remote-addr'     => gettext('Remote address')],
            [accept            => gettext('Accept')],
            ['accept-encoding' => gettext('Accept encoding')],
            ['accept-language' => gettext('Accept languages')],
            [cookie            => gettext('Cookie')]
          )
      )
      . '</table>'
      . '</div>'

      . '<div style="background-color: #FFFACD; padding: 5px 10px; margin: 1px;">'
      . '<h3>Backtrace:</h3>'
      . join(
        '',
        map {
            my $level = $_;
            '<div style="font-family: monospace; margin-bottom: 0.5em;"><strong>'
              . html_encode($_->{'subroutine'})
              . '</strong>('
              . '<pre style="margin: 0px 0px 0px 2em; padding: 0px;">'
              . join("\n\n", map {html_encode($short_dumper->($_, 1)) . ","} @{$_->{'args'}})
              . '</pre>' . ') '
              . gettext('called at %s line %s', html_encode($_->{'filename'}), $_->{'line'})
              . '</div>';
        } @{$exception->{'callstack'}}
      )
      . '</div>'

      . '<div style="background-color: #CCCCCC; padding: 5px 10px; margin: 1px;">' . '<h3>'
      . gettext('Server enviroment')
      . ':</h3>'
      . '<table border="1">'
      . join('',
        map {'<tr><th align="right">' . html_encode($_) . '</th><td>' . html_encode($ENV{$_} || '') . '</td></tr>'}
          keys(%ENV))
      . '</table>'
      . '</div>'

      . '<div style="background-color: #EEEEEE; padding: 5px 10px; margin: 1px;">' . '<h3>'
      . gettext('Application dump')
      . ':</h3>' . '<pre>'
      . html_encode($short_dumper->($self))
      . '</pre>'
      . '</div>'

      . '</body>' . '</html>';
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::WebInterface - Base class for creating web interface.

=head1 GitHub

https://github.com/QBitFramework/QBit-WebInterface

=head1 Install

=over

=item *

cpanm QBit::WebInterface

=back

For more information. please, see code.

=cut
