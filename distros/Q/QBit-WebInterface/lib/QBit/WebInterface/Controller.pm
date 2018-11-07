package QBit::WebInterface::Controller;
$QBit::WebInterface::Controller::VERSION = '0.033';
use qbit;

use base qw(QBit::Application::Part);

use Exception::WebInterface::Controller::CSRF;

use Template 2.20;
use Template::Config;
use Digest::MD5 qw(md5_hex);

use B qw(svref_2object);

use QBit::WebInterface::Controller::Form;

our %TEMPLATE_PRE_DEFINE;

__PACKAGE__->mk_ro_accessors(qw(path attrs));

sub MODIFY_CODE_ATTRIBUTES {
    my ($package, $sub, @attrs) = @_;

    my @unknown_attrs = ();
    my $cmd           = {};
    foreach my $attr (@attrs) {
        unless ($package->_process_attribute($attr, $cmd)) {
            push(@unknown_attrs, $attr);
        }
    }

    if (%$cmd) {
        $cmd->{'package'} = $package;
        $cmd->{'sub'}     = $sub;

        my $cv       = svref_2object($sub);
        my $gv       = $cv->GV;
        my $sub_name = $gv->NAME;

        $cmd->{'sub_name'} = $sub_name;

        my $pkg_stash = package_stash($package);
        $pkg_stash->{'__CMDS__'}{$sub_name} = $cmd;
    }

    return @unknown_attrs;
}

sub _process_attribute {
    my ($package, $attr, $cmd) = @_;

    my $result = TRUE;
    if ($attr =~ /^CMD$/) {
        $cmd->{'attributes'}{'CMD'} = TRUE;
    } elsif ($attr =~ /^DEFAULT$/) {
        $cmd->{'attributes'}{'DEFAULT'} = TRUE;
    } elsif ($attr =~ /^FORMCMD$/) {
        $cmd->{'attributes'}{'FORM'} = TRUE;
        $cmd->{'process_method'} = '_process_form';
    } elsif ($attr =~ /^SAFE$/) {
        $cmd->{'attributes'}{'SAFE'} = TRUE;
    } elsif ($attr =~ /^URL\((.+)\)/) {
        my @params = eval($1);
        throw Exception $@ if $@;

        $cmd->{'attributes'}{'URL'} = TRUE;
        $cmd->{'route_params'} = \@params;
    } else {
        $result = FALSE;
    }

    return $result;
}

sub import {
    my ($package, %opts) = @_;

    $package->SUPER::import(%opts);

    $opts{'path'} ||= '';

    my $app_pkg = $opts{'app_pkg'} // caller();
    die gettext('Use only in QBit::WebInterface and QBit::Application descendant')
      unless $app_pkg->isa('QBit::WebInterface')
      && $app_pkg->isa('QBit::Application');

    my $pkg_stash = package_stash($package);

    $pkg_stash->{'import_opts'} = \%opts;

    my $app_pkg_stash = package_stash($app_pkg);
    $app_pkg_stash->{'__CMDS__'} = {}
      unless exists($app_pkg_stash->{'__CMDS__'});

    foreach my $sub_name (sort keys(%{$pkg_stash->{'__CMDS__'} || {}})) {
        my $cmd = $pkg_stash->{'__CMDS__'}{$sub_name};

        throw Exception gettext("Cmd \"%s\" is exists in package \"%s\"",
            $sub_name, $app_pkg_stash->{'__CMDS__'}{$opts{'path'}}{$sub_name}{'package'})
          if exists($app_pkg_stash->{'__CMDS__'}{$opts{'path'}}{$sub_name});

        $app_pkg_stash->{'__CMDS__'}{$opts{'path'}}{$sub_name} = $cmd;

        if ($cmd->{'attributes'}{'DEFAULT'}) {
            $app_pkg_stash->{'__CMDS__'}{$opts{'path'}}{'__DEFAULT__'} =
              $app_pkg_stash->{'__CMDS__'}{$opts{'path'}}{$sub_name};
        }
    }

    {
        no strict 'refs';
        foreach my $method (qw(get_option request response)) {
            *{"${package}::${method}"} = sub {shift->app->$method(@_)};
        }
    }
}

sub timelog {shift->app->timelog}

sub break {
    my ($self) = @_;

    $self->{'__BREAK_CMD__'} = TRUE;
}

sub redirect2url {
    my ($self, $url) = @_;

    $url =~ s/[\r\n]//gs;

    $self->response->status(302);
    $self->response->location($url);
}

sub redirect2url_internal {
    my ($self, $url) = @_;

    $url = $self->_get_url_absolute($url);

    return $self->redirect2url($url);
}

sub _get_url_absolute {
    my ($self, $url, %opts) = @_;

    if ($url =~ /\/\//) {
        my $my_host = $self->request->server_name;
        return $self->denied if $url =~ /^(https?:)?\/\/(?!\Q$my_host\E)/i;
    } else {
        $url = $self->request->url(no_uri => 1) . $url unless $url =~ /\/\//;
    }

    return $url;
}

sub redirect {
    my ($self, $cmd, %params) = @_;

    my $path   = delete($params{'path'});
    my $anchor = delete($params{'#anchor'});

    my $url = $self->app->make_cmd($cmd, $path, %params);

    $url .= '#' . uri_escape($anchor) if defined($anchor);

    return $self->redirect2url($url);
}

sub denied {
    my ($self) = @_;

    $self->response->status(403);
}

sub not_found {
    my ($self) = @_;

    $self->response->status(404);
}

sub as_text {
    my ($self, $text) = @_;

    $self->response->content_type('text/plain; charset=UTF-8');
    $self->response->data($text);
}

sub as_json {
    my ($self, $data) = @_;

    $self->response->content_type('application/json; charset=UTF-8');
    $self->response->data(to_json($data));
}

sub as_jsonp {
    my ($self, $func, $data) = @_;

    $self->response->content_type('text/javascript; charset=UTF-8');
    $self->response->data("$func(" . to_json($data) . ')');
}

sub from_template {
    my ($self, $name, %opts) = @_;

    $self->response->data($self->_process_template($name, %opts, pre_process => ['common.tt2']));

    return TRUE;
}

sub send_file {
    my ($self, %opts) = @_;

    throw Exception::BadArguments gettext("No 'data'") unless defined($opts{data});
    $opts{content_type} = 'application/octet-stream' unless defined($opts{content_type});

    $self->response->data($opts{data});
    $self->response->filename($opts{filename});
    $self->response->content_type($opts{content_type});

    return TRUE;
}

sub import_opts {
    my ($self) = @_;

    return package_stash(ref($self))->{'import_opts'};
}

sub stash_set {
    my ($self, $name, $value) = @_;

    $self->response->add_cookie($name => $value);

    return $value;
}

sub stash_get {
    my ($self, $name) = @_;

    my $value = $self->request->cookie($name);

    return $value;
}

sub stash_delete {
    my ($self, $name) = @_;

    my $value = $self->request->cookie($name);
    $self->response->delete_cookie($name);

    return $value;
}

sub gen_anti_csrf_token {
    my ($self, %opts) = @_;

    my $date = int(name2date($opts{'yesterday'} ? 'yesterday' : 'today', oformat => 'sec') / 86400);
    my $cur_user_id = $self->get_option(cur_user => {})->{'id'} || '';
    $opts{'url'} ||= '';

    my $res = md5_hex($self->get_option('salt', '') . $date . $cur_user_id . $opts{'url'});

    return $res;
}

sub check_anti_csrf_token {
    my ($self, $token, %opts) = @_;

    my %gen_opts = hash_transform(\%opts, [qw(url)]);

    return $token eq $self->gen_anti_csrf_token(%gen_opts)
      || $token eq $self->gen_anti_csrf_token(%gen_opts, yesterday => TRUE);
}

sub _process_template {
    my ($self, $name, %opts) = @_;

    $self->timelog->start(gettext('Processing template'));

    my $wself = $self;
    weaken($wself);

    $self->timelog->start(gettext('Creating TT2'));
    local $Template::Config::STASH    = 'Template::Stash::XS';
    local $Template::Config::PROVIDER = 'QBit::WebInterface::Controller::Template::Provider';

    my $template = Template->new(
        INCLUDE_PATH => [
            @{$self->get_option('TemplateIncludePaths') || []},
            $self->get_option('ApplicationPath') . 'templates',
            $self->get_option('FrameworkPath') . 'QBit/templates',
        ],
        COMPILE_EXT => '.ttc',
        COMPILE_DIR => $self->get_option('TemplateCachePath')
          || '/tmp/tt_cache-' . $self->request->server_name() . '-' . $self->request->server_port() . "_$<",
        EVAL_PERL  => 1,
        MINIMIZE   => $self->get_option('MinimizeTemplate'),
        PRE_CHOMP  => 2,
        POST_CHOMP => 2,
        TRIM       => 2,
        RECURSION  => 1,
        FILTERS    => $wself->{'FILTERS'},
        PRE_DEFINE => {
            request => $wself->request,

            get_option   => sub {$wself->get_option(@_)},
            check_rights => sub {$wself->check_rights(@_)},
            gettext      => sub {return gettext(shift, @_)},
            ngettext     => sub {return ngettext(shift, shift, shift, @_)},
            pgettext     => sub {return pgettext(shift, shift, @_)},
            npgettext    => sub {return npgettext(shift, shift, shift, shift, @_)},

            dumper => sub {
                local $Data::Dumper::Terse = 1;
                my $dump_text = Data::Dumper::Dumper(@_);
                for ($dump_text) {
                    s/&/&amp;/g;
                    s/ /&nbsp;/g;
                    s/</&lt;/g;
                    s/>/&gt;/g;
                    s/\n/<br>\n/g;
                }
                return $dump_text;
            },
            to_json => sub {
                return to_json(shift);
            },
            cmd_link => sub {
                my ($new_cmd, $new_path, $params) = @_;
                return $wself->app->make_cmd($new_cmd, $new_path, %{$params || {}});
            },
            safecmd_link => sub {
                my ($new_cmd, $new_path, $params) = @_;
                return $wself->app->make_cmd(
                    $new_cmd,
                    $new_path,
                    %{$params || {}},
                    sign => $wself->gen_anti_csrf_token(
                        url => $wself->app->_get_new_path($new_path, $wself->get_option('cur_cmdpath')) . '/'
                          . $wself->app->_get_new_cmd($new_cmd, $wself->get_option('cur_cmd'))
                    )
                );
            },
            sign_token => sub {
                my ($new_cmd, $new_path) = @_;

                return $wself->gen_anti_csrf_token(
                    url => $wself->app->_get_new_path($new_path, $wself->get_option('cur_cmdpath')) . '/'
                      . $wself->app->_get_new_cmd($new_cmd, $wself->get_option('cur_cmd')));
            },
            format_date => sub {
                return format_date(shift, shift, %{shift || {}});
            },
            format_number => sub {
                return format_number(shift, %{shift || {}});
            },
            %TEMPLATE_PRE_DEFINE,
        },
        PRE_PROCESS  => $opts{'pre_process'},
        POST_PROCESS => $opts{'post_process'},
      )
      || throw $Template::ERROR;

    $self->timelog->finish();

    my $tt_res = '';
    $template->process($name, {%{$opts{'vars'} || {}}, template_name => $name}, \$tt_res) || throw $template->error();

    $self->timelog->finish();

    return \$tt_res;
}

sub _process_form {
    my ($self, %opts) = @_;

    QBit::WebInterface::Controller::Form->new(%opts, controller => $self)->process();
}

TRUE;
