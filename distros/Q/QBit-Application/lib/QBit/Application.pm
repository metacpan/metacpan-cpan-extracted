
=encoding UTF-8

=head1 Name

QBit::Application - base class for create applications.

=head1 Description

It union all project models.

=cut

package QBit::Application;
$QBit::Application::VERSION = '0.017';
use qbit;

use base qw(QBit::Class);

use QBit::Application::_Utils::TmpLocale;
use QBit::Application::_Utils::TmpRights;

=head1 RO accessors

=over

=item

B<timelog>

=back

=cut

__PACKAGE__->mk_ro_accessors(qw(timelog));

=head1 Package methods

=head2 init

Initialization application.

B<It is done:>

=over

=item

Set options ApplicationPath and FrameworkPath

=item

Read all configs

=item

Install die handler if needed

=item

Set default locale

=item

Initialization accessors (see "set_accessors")

=item

Preload accessors if needed

=back

B<No arguments.>

B<Example:>

  my $app = Application->new(); # Application based on QBit::Application

=cut

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    $self->{'__OPTIONS__'} = $self->{'__ORIG_OPTIONS__'} = {};

    my $app_module = ref($self) . '.pm';
    $app_module =~ s/::/\//g;

    $self->{'__ORIG_OPTIONS__'}{'FrameworkPath'} = $INC{'QBit/Class.pm'} =~ /(.+?)QBit\/Class\.pm$/ ? $1 : './';
    $self->{'__ORIG_OPTIONS__'}{'ApplicationPath'} =
        ($INC{$app_module} || '') =~ /(.*?\/?)(?:[^\/]*lib\/*)?$app_module$/
      ? ($1 || './')
      : './';

    package_merge_isa_data(
        ref($self),
        $self->{'__ORIG_OPTIONS__'},
        sub {
            my ($package, $res) = @_;

            my $pkg_stash = package_stash($package);

            foreach my $cfg (@{$pkg_stash->{'__OPTIONS__'} || []}) {
                $cfg->{'config'} //= $self->read_config($cfg->{'filename'});

                foreach (keys %{$cfg->{'config'}}) {
                    warn gettext('%s: option "%s" replaced', $cfg->{'filename'}, $_)
                      if exists($res->{$_});
                    $res->{$_} = $cfg->{'config'}{$_};
                }
            }
        },
        __PACKAGE__
    );

    if ($self->get_option('install_die_handler')) {
        $SIG{__DIE__} = \&qbit::Exceptions::die_handler;
    }

    my $locales = $self->get_option('locales', {});
    if (%$locales) {
        my ($locale) = grep {$locales->{$_}{'default'}} keys(%$locales);
        ($locale) = keys(%$locales) unless $locale;

        $self->set_app_locale($locale);
    }

    $self->init_accessors();

    if ($self->get_option('preload_accessors')) {
        $self->$_ foreach keys(%{$self->get_models()});
    }

    delete($self->{'__OPTIONS__'});    # Options initializing in pre_run
}

=head2 set_accessors

Set accessors. Initialization accessors - one of the steps in sub "init".
If you used B<set_accessors> after B<init>, call sub B<init_accessors>.

You can use standard way for set accessors

  use Application::Model::Users accessor => 'users';
  use QBit::Application::Model::RBAC::DB accessor => 'rbac', models => {db => 'app_db'};

B<But use this method preferable.>

B<Reserved keys:>

=over

=item

accessor

=item

package

=item

models

=item

init

=item

app_pkg

=back

B<Arguments:>

=over

=item

B<%accessors> - Accessors (type: hash). Keys is accessor name, values is options for import.

=back

B<Example:>

  __PACKAGE__->set_accessors(
      app_db => {
          package => 'Application::Model::DB',             # key "package" required (Package name)
      },
      rbac => {
          package => 'QBit::Application::Model::RBAC::DB',
          models => {                                      # key "models" redefine accessors into rbac
              db => 'app_db'
          },
      },
  );

  # or run time

  $app->set_accessors(...);
  $app->init_accessors();

  #after

  $app->app_db; # returns object of a class "Application::Model::DB"
  $app->rbac;   # returns object of a class "QBit::Application::Model::RBAC::DB"

  $app->rbac->db; # returns object of a class "Application::Model::DB", but into package used "QBit::Application::Model::DB::RBAC"

=cut

sub set_accessors {
    my ($self, %accessors) = @_;

    my $package = ref($self) || $self;

    my $app_stash = package_stash($package);
    my $models = $app_stash->{'__MODELS__'} //= {};

    my $all_models = $self->get_models();

    foreach my $accessor (sort keys(%accessors)) {
        throw gettext(
            'Accessor "%s" with class "%s" is exists, try set this accessor for class "%s" in package "%s"',
            $accessor,
            $all_models->{$accessor}{'package'},
            $accessors{$accessor}->{'package'}, $package
          )
          if exists($all_models->{$accessor});

        $accessors{$accessor}->{'app_pkg'}  = $package;
        $accessors{$accessor}->{'accessor'} = $accessor;

        $models->{$accessor} = $accessors{$accessor};
    }
}

=head2 init_accessors

Initialization accessors. Used after calling B<set_accessors> in run time a code

B<No arguments.>

B<Example:>

  $app->set_accessors(...);
  $app->init_accessors();

=cut

sub init_accessors {
    my ($self) = @_;

    no strict 'refs';
    package_merge_isa_data(
        ref($self) || $self,
        undef,
        sub {
            my ($package) = @_;

            my $models = package_stash($package)->{'__MODELS__'} || {};

            foreach my $accessor (sort keys(%$models)) {
                next if $models->{$accessor}{'init'};

                throw gettext('Accessor cannot have name "%s", it is name of method', $accessor)
                  if $self->can($accessor);

                my %import_args = %{$models->{$accessor}};
                my $app_pkg     = $import_args{'app_pkg'};
                my $package     = $import_args{'package'};

                *{"${app_pkg}::${accessor}"} = sub {
                    $_[0]->{$accessor} //= do {
                        my $file_path = "$package.pm";
                        $file_path =~ s/::/\//g;

                        unless ($INC{$file_path}) {
                            try {
                                require $file_path;
                            }
                            catch {
                                throw gettext('Failed require "%s": %s', $file_path, shift->message);
                            };

                            $package->import(%import_args);
                        }

                        $package->new(app => $_[0], accessor => $accessor);
                    };
                };

                $models->{$accessor}{'init'} = TRUE;
            }

        },
        __PACKAGE__
    );
}

=head2 config_opts

Set options in config

B<Arguments:>

=over

=item

B<%opts> - Options (type: hash)

=back

B<Example:>

  __PACKAGE__->config_opts(param_name => 'Param');
  
  # later in your code:
  
  my $param = $app->get_option('param_name'); # 'Param'

=cut

sub config_opts {
    my ($self, %opts) = @_;

    my $class = ref($self) || $self;

    my $pkg_name = $class;
    $pkg_name =~ s/::/\//g;
    $pkg_name .= '.pm';

    $self->_push_pkg_opts($INC{$pkg_name} || $pkg_name => \%opts);
}

=head2 use_config

Set a file in config queue. The configuration is read in sub "init". In the same place are set the settings B<ApplicationPath> and B<FrameworkPath>.

B<QBit::Application options:>

=over

=item

B<locales> - type: hash

  locales => {
      ru => {name => 'Русский', code => 'ru_RU', default => 1},
      en => {name => 'English', code => 'en_GB'},
  },

=item

B<preload_accessors> - type: int, values: 1/0 (1 - preload accessors, 0 - lazy load, default: 0)

=item

B<install_die_handler> - type: int, values: 1/0 (1 - set die handler B<qbit::Exceptions::die_handler>, default: 0)

=item

B<timelog_class> - type: string, values: B<QBit::TimeLog::XS/QBit::TimeLog> (default: B<QBit::TimeLog> - this is not a production solution, in production use XS version)

=item

B<locale_domain> - type: string, value: <your domain> (used in set_locale for B<Locale::Messages::textdomain>, default: 'application')

=item

B<find_app_mem_cycle> - type: int, values: 1/0 (1 - find memory cycle in post_run, used Devel::Cycle, default: 0)

=back

B<QBit::WebInterface options:>

=over

=item

B<error_dump_dir> - type: string, value: <your path for error dumps>

=item

B<salt> - type: string, value: <your salt> (used for generate csrf token)

=item

B<TemplateCachePath> - type: string, value: <your path for template cache> (default: "/tmp")

=item

B<show_timelog> - type: int, values: 1/0 (1 - view timelog in html footer, default: 0)

=item

B<TemplateIncludePaths> - type: array of a string: value: [<your path for templates>]

  already used:
  - <project_path>/templates         # project_path   = $self->get_option('ApplicationPath')
  - <framework_path>/QBit/templates  # framework_path = $self->get_option('FrameworkPath')

=back

B<QBit::WebInterface::Routing options:>

=over

=item

B<controller_class> - type: string, value: <your controller class> (default: B<QBit::WebInterface::Controller>)

=item

B<use_base_routing> - type: int, values: 1/0 (1 - also use routing from B<QBit::WebInterface::Controller>, 0 - only use routing from B<QBit::WebInterface::Routing>)

=back

B<Arguments:>

=over

=item

B<$filename> - Config name (type: string)

=back

B<Example:>

  __PACKAGE__->use_config('Application.cfg');  # or __PACKAGE__->use_config('Application.json');

  # later in your code:

  my preload_accessors = $app->get_option('preload_accessors');

=cut

sub use_config {
    my ($self, $filename) = @_;

    $self->_push_pkg_opts($filename);
}

=head2 read_config

read config by path or name from folder "configs".

  > tree ./Project

  Project
  ├── configs
  │   └── Application.cfg
  └── lib
      └── Application.pm

B<Formats:>

=over

=item

B<cfg> - perl code

  > cat ./configs/Application.cfg

  preload_accessors => 1,
  timelog_class => 'QBit::TimeLog::XS',
  locale_domain => 'domain.local',
  TemplateIncludePaths => ['${ApplicationPath}lib/QBit/templates'],

=item

B<json> - json format

  > cat ./configs/Application.json

  {
    "preload_accessors" : 1,
    "timelog_class" : "QBit::TimeLog::XS",
    "locale_domain" : "domain.local",
    "TemplateIncludePaths" : ["${ApplicationPath}lib/QBit/templates"]
  }

=back

B<Arguments:>

=over

=item

B<$filename> - Config name (type: string)

=back

B<Return value:>  Options (type: ref of a hash)

B<Example:>

  my $config = $app->read_config('Application.cfg');

=cut

sub read_config {
    my ($self, $filename) = @_;

    unless (-f $filename) {
        foreach (qw(lib configs)) {
            my $possible_file = $self->get_option('ApplicationPath') . "$_/$filename";

            if (-f $possible_file) {
                $filename = $possible_file;

                #TODO: use only configs
                if ($_ eq 'lib') {
                    warn gettext('For configs, use the "configs" folder in the project root.');
                }

                last;
            }
        }
    }

    my $config = {};

    try {
        if ($filename =~ /\.cfg\z/) {
            $config = {do $filename};
        } elsif ($filename =~ /\.json\z/) {
            $config = from_json(readfile($filename));
        } else {
            throw gettext('Unknown config format: %s', $filename);
        }
    }
    catch {
        my ($exception) = @_;

        throw gettext('Read config file "%s" failed: %s', $filename, $exception->message);
    };

    throw gettext('Config "%s" must be a hash') if ref($config) ne 'HASH';

    return $config;
}

=head2 get_option

Returns option value by name

B<Arguments:>

=over

=item

B<$name> - Option name (type: string)

=item

B<$default> - Default value

=back

B<Return value:> Option value

B<Example:>

  my $salt = $app->get_option('salt', 's3cret');

  my $stash = $app->get_option('stash', {});

=cut

sub get_option {
    my ($self, $name, $default) = @_;

    my $res = $self->{'__OPTIONS__'}{$name} // $default;

    if (defined($res) && (!ref($res) || ref($res) eq 'ARRAY')) {
        foreach my $str (ref($res) eq 'ARRAY' ? @$res : $res) {
            while ($str =~ /^(.*?)(?:\$\{([\w\d_]+)\})(.*)$/) {
                $str = ($1 || '') . ($self->get_option($2) || '') . ($3 || '');
            }
        }
    }

    return $res;
}

=head2 set_option

Set option value by name.

B<Arguments:>

=over

=item

B<$name> - Option name (type: string)

=item

B<$value> - Option value

=back

B<Return value:> Option value

B<Example:>

  $app->set_option('salt', 's3cret');

  $app->set_option('stash', {key => 'val'});

=cut

sub set_option {
    my ($self, $name, $value) = @_;

    $self->{'__OPTIONS__'}{$name} = $value;
}

=head2 cur_user

set or get current user

B<Arguments:>

=over

=item

B<$user> - hash ref

=back

B<Return value:> hash ref

    my $user = {id => 1};

    $cur_user = $app->cur_user($user); # set current user

    # if use rbac
    # {id => 1, roles => {3 => {id => 3, name => 'ROLE 3', description => 'ROLE 3'}}, rights => ['RIGHT1', 'RIGHT2']}
    # or
    # {id => 1}

    $cur_user = $app->cur_user(); # return current user or {}

    $app->cur_user({}); # remove current user

=cut

sub cur_user {
    my ($self, $user) = @_;

    my $cur_user = $self->{'__OPTIONS__'}{'cur_user'} // {};

    return $cur_user unless defined($user);

    $self->revoke_cur_user_rights($cur_user->{'rights'} // []);

    $self->set_option('cur_user', $user);

    $self->_fix_cur_user($user);

    return $user;
}

sub _fix_cur_user {
    my ($self, $cur_user) = @_;

    if (%$cur_user && $self->can('rbac')) {
        $cur_user->{'roles'}  = $self->rbac->get_cur_user_roles();
        $cur_user->{'rights'} = [
            map {$_->{'right'}} @{
                $self->rbac->get_roles_rights(
                    fields  => {right => {distinct => ['right']}},
                    role_id => [keys(%{$cur_user->{'roles'}})]
                )
            }
        ];

        $self->set_cur_user_rights($cur_user->{'rights'});
    }
}

=head2 set_cur_user_rights

set rights for current user

B<Arguments:>

=over

=item

B<$rights> - array ref

=back

    $app->set_cur_user_rights([qw(RIGHT1 RIGHT2)]);

=cut

sub set_cur_user_rights {
    my ($self, $rights) = @_;

    $self->{'__CURRENT_USER_RIGHTS__'}{$_}++ foreach @$rights;
}

=head2 revoke_cur_user_rights

revoke rights for current user

B<Arguments:>

=over

=item

B<$rights> - array ref

=back

    $app->revoke_cur_user_rights([qw(RIGHT1 RIGHT2)]);

=cut

sub revoke_cur_user_rights {
    my ($self, $rights) = @_;

    foreach (@$rights) {
        delete($self->{'__CURRENT_USER_RIGHTS__'}{$_}) unless --$self->{'__CURRENT_USER_RIGHTS__'}{$_};
    }
}

=head2 refresh_rights

refresh rights for current user

    my $cur_user_id = $app->cur_user()->{'id'};

    $app->rbac->set_user_role($cur_user_id, 3); # role_id = 3

    $app->refresh_rights();

=cut

sub refresh_rights {
    my ($self) = @_;

    my $cur_user = $self->cur_user();

    $self->revoke_cur_user_rights($cur_user->{'rights'} // []);

    $self->_fix_cur_user($cur_user);

    return TRUE;
}

=head2 get_models

Returns all models.

B<No arguments.>

B<Return value:> $models - ref of a hash

B<Examples:>

  my $models = $app->get_models();

  # $models = {
  #     users => 'Application::Model::Users',
  #     ...
  # }

=cut

sub get_models {
    my ($self) = @_;

    my $models = {};

    package_merge_isa_data(
        ref($self) || $self, $models,
        sub {
            my ($package, $res) = @_;

            my $pkg_models = package_stash($package)->{'__MODELS__'} || {};
            $models->{$_} = $pkg_models->{$_} foreach keys(%$pkg_models);
        },
        __PACKAGE__
    );

    return $models;
}

=head2 get_registered_rights

Returns all registered rights

B<No arguments.>

B<Return value:> ref of a hash

B<Example:>

  my $registered_rights = $app->get_registered_rights();
  
  # $registered_rights = {
  #     view_all => {
  #         name  => 'Right to view all elements',
  #         group => 'elemets'
  #     },
  #     ...
  # }

=cut

sub get_registered_rights {
    my ($self) = @_;

    my $rights = {};
    package_merge_isa_data(
        ref($self),
        $rights,
        sub {
            my ($ipackage, $res) = @_;

            my $ipkg_stash = package_stash($ipackage);
            $res->{'__RIGHTS__'} = {%{$res->{'__RIGHTS__'} || {}}, %{$ipkg_stash->{'__RIGHTS__'} || {}}};
        },
        __PACKAGE__
    );

    return $rights->{'__RIGHTS__'};
}

sub get_registred_rights {&get_registered_rights;}

=head2 get_registered_right_groups

Returns all registered right groups.

B<No arguments.>

B<Return value:> $registered_right_groups - ref of a hash

B<Example:>

  my $registered_right_groups = $app->get_registered_right_groups();

  # $registered_right_groups = {
  #     elements => 'Elements',
  # }

=cut

sub get_registered_right_groups {
    my ($self) = @_;

    my $rights = {};
    package_merge_isa_data(
        ref($self),
        $rights,
        sub {
            my ($ipackage, $res) = @_;

            my $ipkg_stash = package_stash($ipackage);
            $res->{'__RIGHT_GROUPS__'} =
              {%{$res->{'__RIGHT_GROUPS__'} || {}}, %{$ipkg_stash->{'__RIGHT_GROUPS__'} || {}}};
        },
        __PACKAGE__
    );

    return $rights->{'__RIGHT_GROUPS__'};
}

sub get_registred_right_groups {&get_registered_right_groups;}

=head2 check_rights

Check rights for current user.

B<Arguments:>

=over

=item

B<@rights> - array of strings or array ref

=back

B<Return value:> boolean

B<Example:>

  $app->check_rights('RIGHT1', 'RIGHT2'); # TRUE if has rights 'RIGHT1' and 'RIGHT2'

  $app->check_rights(['RIGHT1', 'RIGHT2']); # TRUE if has rights 'RIGHT1' or 'RIGHT2'

=cut

sub check_rights {
    my ($self, @rights) = @_;

    return FALSE unless @rights;

    foreach (@rights) {
        return FALSE
          unless ref($_)
          ? scalar(grep($self->{'__CURRENT_USER_RIGHTS__'}{$_}, @$_))
          : $self->{'__CURRENT_USER_RIGHTS__'}{$_};
    }

    return TRUE;
}

=head2 set_app_locale

Set locale for Application.

B<Arguments:>

=over

=item

B<$locale_id> - type: string, values: from config (key "locales")

=back

B<Example:>

  $app->set_app_locale('ru');

=cut

sub set_app_locale {
    my ($self, $locale_id) = @_;

    my $locale = $self->get_option('locales', {})->{$locale_id};
    throw gettext('Unknown locale') unless defined($locale);
    throw gettext('Undefined locale code for locale "%s"', $locale_id) unless $locale->{'code'};

    set_locale(
        project => $self->get_option('locale_domain', 'application'),
        path    => $self->get_option('ApplicationPath') . '/locale',
        lang    => $locale->{'code'},
    );

    $self->set_option(locale => $locale_id);
}

=head2 set_tmp_app_locale

Set temporary locale.

B<Arguments:>

=over

=item

B<$locale_id> - type: string, values: from config (key "locales")

=back

B<Return value:> $tmp_locale - object B<QBit::Application::_Utils::TmpLocale>

B<Example:>

  my $tmp_locale = $app->set_tmp_app_locale('ru');
  
  #restore locale
  undef($tmp_locale);

=cut

sub set_tmp_app_locale {
    my ($self, $locale_id) = @_;

    my $old_locale_id = $self->get_option('locale');
    $self->set_app_locale($locale_id);

    return QBit::Application::_Utils::TmpLocale->new(app => $self, old_locale => $old_locale_id);
}

=head2 add_tmp_rights

Add temporary rights.

B<Arguments:>

=over

=item

B<@rights> - Rights (type: array of a string)

=back

B<Return value:> $tmp_rights - object B<QBit::Application::_Utils::TmpRights>

B<Example:>

  my $tmp_rights = $app->add_tmp_rights('view_all', 'edit_all');
  
  #restore rights
  undef($tmp_rights);

=cut

sub add_tmp_rights {
    my ($self, @rights) = @_;

    return QBit::Application::_Utils::TmpRights->new(app => $self, rights => \@rights);
}

=head2 pre_run

Called before the request is processed.

B<It is done:>

=over

=item

Resets current user

=item

Refresh options

=item

Resets timelog

=item

Call "pre_run" for models

=back

B<No arguments.>

B<Example:>

  $app->pre_run();

=cut

sub pre_run {
    my ($self) = @_;

    $self->{'__CURRENT_USER_RIGHTS__'} = {};

    $self->{'__OPTIONS__'} = clone($self->{'__ORIG_OPTIONS__'});

    unless (exists($self->{'__TIMELOG_CLASS__'})) {
        my $tl_package = $self->{'__TIMELOG_CLASS__'} = $self->get_option('timelog_class', 'QBit::TimeLog');

        $tl_package =~ s/::/\//g;
        $tl_package .= '.pm';
        require $tl_package;
    }

    $self->{'timelog'} = $self->{'__TIMELOG_CLASS__'}->new();
    $self->{'timelog'}->start(gettext('Total application run time'));

    foreach (keys(%{$self->get_models()})) {
        $self->$_->pre_run() if exists($self->{$_}) && $self->{$_}->can('pre_run');
    }
}

=head2 post_run

Called after the request is processed.

B<It is done:>

=over

=item

Call "post_run" for models

=item

Finish timelog

=item

Call "process_timelog"

=item

Find memory cycles and call "process_mem_cycles" if needed

=back

B<No arguments.>

B<Example:>

  $app->post_run();

=cut

sub post_run {
    my ($self) = @_;

    foreach (keys(%{$self->get_models()})) {
        $self->$_->post_run() if exists($self->{$_}) && $self->{$_}->can('post_run');
    }

    $self->timelog->finish();
    $self->process_timelog($self->timelog);

    if ($self->get_option('find_app_mem_cycle')) {
        if (eval {require 'Devel/Cycle.pm'}) {
            Devel::Cycle->import();
            my @cycles;
            Devel::Cycle::find_cycle($self, sub {push(@cycles, shift)});
            $self->process_mem_cycles(\@cycles) if @cycles;
        } else {
            l(gettext('Devel::Cycle is not installed'));
        }
    }
}

=head2 process_mem_cycles

Process memory cycles

B<Arguments:>

=over

=item

B<$cycles> - Cycles. (result: B<Devel::Cycle::find_cycle>)

=back

B<Return value:> $text - info (type: string)

=cut

sub process_mem_cycles {
    my ($self, $cycles) = @_;

    my $counter = 0;
    my $text    = '';
    foreach my $path (@$cycles) {
        $text .= gettext('Cycle (%s):', ++$counter) . "\n";
        foreach (@$path) {
            my ($type, $index, $ref, $value, $is_weak) = @$_;
            $text .= gettext(
                "\t%30s => %-30s\n",
                ($is_weak ? 'w-> ' : '') . Devel::Cycle::_format_reference($type, $index, $ref, 0),
                Devel::Cycle::_format_reference(undef, undef, $value, 1)
            );
        }
        $text .= "\n";
    }

    l($text);
    return $text;
}

=head2 process_timelog

Process time log. Empty method.

B<No arguments.>

=cut

sub process_timelog { }

sub _push_pkg_opts {
    my ($self, $filename, $config) = @_;

    my $pkg_stash = package_stash(ref($self) || $self);

    $pkg_stash->{'__OPTIONS__'} = []
      unless exists($pkg_stash->{'__OPTIONS__'});

    push(
        @{$pkg_stash->{'__OPTIONS__'}},
        {
            filename => $filename,
            config   => $config,
        }
    );
}

TRUE;
