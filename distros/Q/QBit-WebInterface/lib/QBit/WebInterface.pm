package QBit::WebInterface;
$QBit::WebInterface::VERSION = '0.031';
use POSIX qw(strftime setlocale LC_TIME);

use qbit;

use QBit::WebInterface::Response;

use Exception::WebInterface::Controller::CSRF;
use Exception::Request::UnknownMethod;

sub request {
    my ($self, $request) = @_;

    return defined($request) ? $self->{'__REQUEST__'} = $request : $self->{'__REQUEST__'};
}

sub response {
    my ($self, $response) = @_;

    return defined($response) ? $self->{'__RESPONSE__'} = $response : $self->{'__RESPONSE__'};
}

sub get_cmds {
    my ($self) = @_;

    my $cmds = {};

    package_merge_isa_data(
        ref($self),
        $cmds,
        sub {
            my ($package, $res) = @_;

            my $pkg_cmds = package_stash($package)->{'__CMDS__'} || {};
            foreach my $path (keys(%$pkg_cmds)) {
                foreach my $cmd (keys(%{$pkg_cmds->{$path}})) {
                    $cmds->{$path}{$cmd} = $pkg_cmds->{$path}{$cmd};
                }
            }
        },
        __PACKAGE__
    );

    return $cmds;
}

sub build_response {
    my ($self) = @_;

    $self->pre_run();

    throw gettext('No request object') unless $self->request;
    $self->response(QBit::WebInterface::Response->new());

    my $cmds = $self->get_cmds();
    my ($path, $cmd) = $self->get_cmd();

    $cmd = $cmds->{$path}{'__DEFAULT__'}{'name'} if $cmd eq '';
    $cmd = '' unless defined($cmd);

    $self->set_option(cur_cmd     => $cmd);
    $self->set_option(cur_cmdpath => $path);

    if (exists($cmds->{$path}{$cmd})) {
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
                          unless $controller->check_anti_csrf_token($self->request->param(sign => ''),
                            url => $self->get_option('cur_cmdpath') . '/' . $self->get_option('cur_cmd'));
                    }

                    my @data = $cmd->{'sub'}($controller);
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
            $self->_catch_internal_server_error(@_);
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

sub break {
    my ($self, @data) = @_;

    $self->{'__BREAK_PROCESS__'} = 1;
    return @data;
}

sub form_fields { }

sub pre_cmd { }

sub post_cmd { }

sub default_cmd {throw 'Abstract metod'}

sub get_cmd {throw 'Abstract metod'}

sub make_cmd {throw 'Abstract metod'}

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

=item *

apt-get install libqbit-webinterface-perl (http://perlhub.ru/)

=back

For more information. please, see code.

=cut
