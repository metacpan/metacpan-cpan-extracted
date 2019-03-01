package Tapper::Reports::Web::Controller::Tapper::Testruns;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Controller::Tapper::Testruns::VERSION = '5.0.14';
use parent 'Tapper::Reports::Web::Controller::Base';
use Cwd;
use Data::DPath 'dpath';
use DateTime::Format::DateParse;
use DateTime;
use File::Basename;
use File::Path;
use List::Util 'max';
use Template;
use YAML::Syck;

use Tapper::Cmd::Testrun;
use Tapper::Cmd::Precondition;
use Tapper::Config;
use Tapper::Model 'model';
use Tapper::Reports::Web::Util::Testrun;
use Tapper::Reports::Web::Util::Filter::Testrun;

use common::sense;
## no critic (RequireUseStrict)




sub index :Path :Args()
{
        my ( $self, $c, @args ) = @_;

        my $filter = Tapper::Reports::Web::Util::Filter::Testrun->new(context => $c);
        my $filter_condition = $filter->parse_filters(\@args);

        if ($filter_condition->{error}) {
                $c->flash->{error_msg} = join("; ", @{$filter_condition->{error}});
                $c->res->redirect("/tapper/testruns");
        }
        $c->forward('/tapper/testruns/prepare_testrunlists', [ $filter_condition, $filter->requested_day ]);
        $c->forward('/tapper/testruns/prepare_navi');
        return;
}


sub get_test_list_from_precondition {
        my ($precond) = @_;

        return grep { defined } (
                                 $precond->{testprogram}{execname},
                                 map {
                                      join( " ", $_->{program}, @{$_->{parameters}} )
                                     } @{$precond->{testprogram_list}},
                                );
}


sub get_testrun_overview : Private
{
        my ( $self, $c, $testrun ) = @_;

        my $retval = {};

        return $retval unless $testrun;

        $retval->{shortname} = $testrun->shortname;

        foreach ($testrun->ordered_preconditions) {
                my $precondition = $_->precondition_as_hash;
                if ($precondition->{precondition_type} eq 'virt' ) {
                        $retval->{name}  = $precondition->{name} || "Virtualisation Test";
                        $retval->{arch}  = $precondition->{host}->{root}{arch};
                        $retval->{image} = $precondition->{host}->{root}{image} || $precondition->{host}->{root}{name}; # can be an image or copyfile or package
                        ($retval->{xen_package}) = grep { m!repository/packages/xen/builds! } dpath('/host/preconditions//filename')->match($precondition);
                        push @{$retval->{test}}, get_test_list_from_precondition($precondition->{host});

                        foreach my $guest (@{$precondition->{guests}}) {
                                my $guest_summary;
                                $guest_summary->{arch}  = $guest->{root}{arch};
                                $guest_summary->{image} = $guest->{root}{image} || $guest->{root}{name}; # can be an image or copyfile or package
                                push @{$guest_summary->{test}}, get_test_list_from_precondition($guest);
                                push @{$retval->{guests}}, $guest_summary;
                        }
                        # can stop here because virt preconditions usually defines everything we need for a summary
                        return $retval;
                }
                elsif ($precondition->{precondition_type} eq 'image' ) {
                        $retval->{image} = $precondition->{image};
                        if ($retval->{arch}) {
                                $retval->{arch} = $precondition->{arch};
                        } else {
                                if ($precondition->{image} =~ m/(64b)|(x86_64)/) {
                                        $retval->{arch} = 'unknown (probably linux64)';
                                } elsif ($precondition->{image} =~ m/(32b)|(i386)/) {
                                        $retval->{arch} = 'unknown (probably linux32)';
                                } else {
                                        $retval->{arch} = 'unknown';
                                }
                        }
                } elsif ($precondition->{precondition_type} eq 'prc') {
                        if ($precondition->{config}->{testprogram_list}) {
                                foreach my $thisprogram (@{$precondition->{config}->{testprogram_list}}) {
                                        push @{$retval->{test}}, $thisprogram->{program};
                                }
                        } elsif ($precondition->{config}->{test_program}) {
                                push @{$retval->{test}}, $precondition->{config}->{test_program};
                        }
                }
        }
        return $retval;
}

sub base : Chained PathPrefix CaptureArgs(0) { }

sub id : Chained('base') PathPart('') CaptureArgs(1)
{
        my ( $self, $c, $testrun_id ) = @_;
        $c->stash(testrun => $c->model('TestrunDB')->resultset('Testrun')->find($testrun_id));
        if (not $c->stash->{testrun}) {
                $c->response->body(qq(No testrun with id "$testrun_id" found in the database!));
                return;
        }

}

sub delete : Chained('id') PathPart('delete')
{
        my ( $self, $c, $force) = @_;
        $c->stash(force => $force);

        return if not $force;

        my $cmd = Tapper::Cmd::Testrun->new();
        my $retval = $cmd->del($c->stash->{testrun}->id);
        if ($retval) {
                $c->response->body(qq(Can not delete testrun: $retval));
                return;
        }
        $c->stash(force => 1);
}

sub pause : Chained('id') PathPart('pause')
{
        my ( $self, $c) = @_;

        my $cmd = Tapper::Cmd::Testrun->new();
        my $retval = $cmd->pause($c->stash->{testrun}->id);
        if (not $retval) {
                $c->response->body(qq(Can not pause testrun));
                return;
        }
        $c->stash(testrun => $c->stash->{testrun}->id);
}

sub continue : Chained('id') PathPart('continue')
{
        my ( $self, $c) = @_;

        my $cmd = Tapper::Cmd::Testrun->new();
        my $retval = $cmd->continue($c->stash->{testrun}->id);
        if (not $retval) {
                $c->response->body(qq(Can not continue testrun));
                return;
        }
        $c->stash(testrun => $c->stash->{testrun}->id);
}

sub rerun : Chained('id') PathPart('rerun') Args(0)
{
        my ( $self, $c ) = @_;

        my $cmd = Tapper::Cmd::Testrun->new();
        my $retval = $cmd->rerun($c->stash->{testrun}->id);
        if (not $retval) {
                $c->response->body(qq(Can not rerun testrun));
                return;
        }
        $c->stash(testrun => $retval);
}

sub cancel : Chained('id') PathPart('cancel') Args(0)
{
        my ( $self, $c ) = @_;

        my $cmd = Tapper::Cmd::Testrun->new();
        my $retval = $cmd->cancel($c->stash->{testrun}->id, "Cancelled in Web GUI");
        if ($retval) {
                $c->response->body(qq(Can not cancel testrun: $retval));
                return;
        }
        $c->stash(testrun => $c->stash->{testrun}->id);
}

sub preconditions : Chained('id') PathPart('preconditions') CaptureArgs(0)
{
        my ( $self, $c ) = @_;
        $c->stash(preconditions => [$c->stash->{testrun}->ordered_preconditions]);
        my @preconditions_as_hash = map { $_->precondition_as_hash } $c->stash->{testrun}->ordered_preconditions;
        $YAML::Syck::SortKeys  = 1;
        $c->stash->{precondition_string} = YAML::Syck::Dump(@preconditions_as_hash);
}

sub as_yaml : Chained('preconditions') PathPart('yaml') Args(0)
{
        my ( $self, $c ) = @_;

        my $id = $c->stash->{testrun}->id;

        if (@{$c->stash->{preconditions} || []}) {
                $c->response->content_type ('text/plain');
                $c->response->header ("Content-Disposition" => 'inline; filename="precondition-'.$id.'.yml"');
                $c->response->body ( $c->stash->{precondition_string});
        } else {
                $c->response->body ("No preconditions assigned");
        }
}

sub validate_yaml
{
        my ($data) = @_;
        eval {
                YAML::Syck::Load($data);
        };
        return $@;
}

sub edit : Chained('preconditions') PathPart('edit') Args(0) :FormConfig
{
        my ($self, $c) = @_;
        my ($max_line, $line_count) = (0,0);

        my @lines = split "\n", $c->stash->{precondition_string};
        foreach my $line (@lines) {
                $max_line = max($max_line, length($line));
        }

        my $form = $c->stash->{form};

        if ($form->submitted_and_valid) {
                my $data = $form->input->{preconditions};

                # check whether user entered valid YAML
                my $error = validate_yaml($data);
                if ($error) {
                        $c->stash(message => "<emp>Error</emp>: $error");
                } else {
                        my @precondition_ids = eval {
                                my $precond_cmd = Tapper::Cmd::Precondition->new();
                                $precond_cmd->add($data);
                        };
                        if ($@) {
                                $c->stash(message => "<emp>Error</emp>: $@");
                                return;
                        }

                        $c->stash->{testrun}->disassign_preconditions();
                        my $retval = $c->stash->{testrun}->assign_preconditions(@precondition_ids);
                        if ($retval) {
                                $c->stash(message => "<emp>Error</emp>: $retval");
                        } else {
                                $c->stash(message => "New precondition assigned to testrun");
                        }
                }
        } else {
                my $text = $form->get_element({type => 'Textarea',
                                               name => 'preconditions'});
                $text->rows(int @lines);
                $text->cols($max_line);
                $text->default($c->stash->{precondition_string});
        }
}

sub update_precondition : Chained('base') PathPart('update_precondition')
{
        my ($self, $c) = @_;
}


sub show_precondition : Chained('preconditions') PathPart('show') Args(0)
{
        my ( $self, $c ) = @_;

}


sub similar : Chained('id') PathPart('similar') Args(0)
{
}


sub new_create : Chained('base') :PathPart('create') :Args(0) :FormConfig
{
        my ($self, $c) = @_;
        my $form = $c->stash->{form};

        if ($form->submitted_and_valid) {
                my $data = $form->input();
                $c->session->{testrun_data} = $data;
                $c->session->{valid} = 1;
                $c->session->{usecase_file} = $form->input->{use_case};
                $c->res->redirect('/tapper/testruns/fill_usecase');

        } else {
                my $select;

                $select = $form->get_element({type => 'Select', name => 'owner'});
                $select->options($self->get_owner_names());

                $select = $form->get_element({type => 'Select', name => 'requested_hosts'});
                $select->options($self->get_hostnames());

                my @use_cases;
                my $path = Tapper::Config->subconfig->{paths}{use_case_path};
                foreach my $file (glob "$path/*.mpc") {
                        open my $fh, "<", $file or $c->response->body(qq(Can not open $file: $!)), return;
                        my $desc;
                        my $hide;
                        while (my $line = <$fh>) {
                                ($desc) = $line =~/^#+ *(?:tapper[_-])?description:\s*(.+)/;
                                last if $desc;
                        }
                        while (my $line = <$fh>) {
                                ($hide) = $line =~/^#+ *(?:tapper[_-])?hide-in-webgui:\s*(.+)/;
                                last if $hide;
                        }

                        my ($shortfile, undef, undef) = File::Basename::fileparse($file, ('.mpc'));
                        push @use_cases, [$file, "$shortfile - $desc"] unless $hide;

                }
                my $select = $form->get_element({type => 'Radiogroup', name => 'use_case'});
                $select->options(\@use_cases);
        }

}

sub get_topic_names
{
        my ($self) = @_;
        my @all_topics = model("TestrunDB")->resultset('Topic')->all();
        my @topic_names;
        foreach my $topic (sort {$a->name cmp $b->name} @all_topics) {
                push(@topic_names, [$topic->name, $topic->name." -- ".$topic->description]);
        }
        return \@topic_names;
}

sub get_owner_names
{
        my ($self) = @_;
        my @all_owners = model("TestrunDB")->resultset('Owner')->all();
        my @owners;
        foreach my $owner (sort {$a->name cmp $b->name} @all_owners) {
                if ($owner->login eq 'tapper') {
                        unshift(@owners, [$owner->login, $owner->name." (".$owner->login.")"]);
                } else {
                        push(@owners, [$owner->login, $owner->name." (".$owner->login.")"]);
                }
        }
        return \@owners;
}


sub get_hostnames
{
        my ($self) = @_;
        my @all_machines = model("TestrunDB")->resultset('Host')->search({active => 1});
        my @machines;
 HOST:
        foreach my $host (sort {$a->name cmp $b->name} @all_machines) {

                # if host is bound, is must be bound to
                #  new_testrun_queue (possibly among others)
                if ($host->queuehosts->count()) {
                        my $new_testrun_queue = Tapper::Config->subconfig->{new_testrun_queue};
                        next HOST unless
                          grep {$_->queue->name eq $new_testrun_queue} $host->queuehosts->all;
                }

                push(@machines, [ $host->name, $host->name ]);
        }
        return \@machines;

}



sub parse_macro_precondition :Private
{
        my ($self, $c, $file) = @_;
        my $config;
        my $home = $c->path_to();
        my ($shortfile, undef, undef) = File::Basename::fileparse($file, ('.mpc'));

        open my $fh, "<", $file or return "Can not open use case description $file:$!";
        my ($required, $optional, $mpc_config) = ('', '', '');

        while (my $line = <$fh>) {
                $config->{description_text} .= "$1\n" if $line =~ /^### ?(.*)$/;

                ($required)   = $line =~/^#+ *(?:tapper[_-])?mandatory[_-]fields?:\s*(.+)/ if not $required;
                ($optional)   = $line =~/^#+ *(?:tapper[_-])?optional[_-]fields?:\s*(.+)/ if not $optional;
                ($mpc_config) = $line =~/^#+ *(?:tapper[_-])?config[_-]file:\s*(.+)/ if not $mpc_config;
        }

        my $delim = qr/,+\s*/;
        foreach my $field (split $delim, $required) {
                my ($name, $type) = split /\./, $field;
                $type = 'Text' if not $type;
                push @{$config->{required}}, {type => ucfirst($type),
                                              name => $name,
                                              label => $name,
                                              constraints => [ 'Required' ]
                                             }
        }

        foreach my $field (split $delim, $optional) {
                my ($name, $type) = split /\./, $field;
                $type = 'Text' if not $type;
                push @{$config->{optional}},{type => ucfirst($type),
                                             name => $name,
                                             label => $name,
                                            };
        }

        if ($mpc_config) {
                my $use_case_path = Tapper::Config->subconfig->{paths}{use_case_path};
                $mpc_config = "$use_case_path/$mpc_config"
                  unless substr($mpc_config, 0, 1) eq '/';

                # configs with relative paths are searched in FormFu's
                # config_file_path which is somewhere in root/forms. We
                # want our own config_path which starts at cwd when
                # being a relative path
                $mpc_config = getcwd()."/$mpc_config" if $mpc_config !~ m'^/'o;

                if (not -r $mpc_config) {
                        $c->stash(error => qq(Config file "$mpc_config" does not exists or is not readable));
                        return;
                }
                $config->{mpc_config} = $mpc_config;
        }

        # Default field "testrun_topic" in every form
        if (not grep { $_->{name} eq "testrun_topic" } @{$config->{required}}) {
            unshift @{$config->{required}},
            {
                type => "Text",
                name => "testrun_topic",
                label => "Testrun topic",
                value =>  join("-", "usertest", ($shortfile || ())),
                constraints => [ { type => 'Required', message_xml => '<span style="color:#B40404">Please fill mandatory field</span>' } ],
                attributes => { size => 50 },
            }
        }

        return $config;
}



sub handle_precondition
{
        my ($self, $c, $config) = @_;
        my $form = $c->stash->{form};
        my %macros;
        my %all_form_elements = %{$c->request->{parameters}};

        foreach my $element (@{$config->{required}}, @{$config->{optional}}) {
                my $name = $element->{name};
                next if not defined $all_form_elements{$name};

                if (lc($element->{type}) eq 'file') {
                        my $upload = $c->req->upload($name);
                        my $destdir = sprintf("%s/uploads/%s/%s",
                                              Tapper::Config->subconfig->{paths}{package_dir}, $config->{testrun_id}, $name);
                        my $destfile = $destdir."/".$upload->basename;
                        my $error;

                        mkpath( $destdir, {error => \$error} );

                        foreach my $diag (@$error) {
                                my ($dir, $message) = each %$diag;
                                return("Can not create $dir: $message");
                        }
                        $upload->copy_to($destfile);
                        $macros{$name} = $destfile;
                        delete $all_form_elements{$name};
                }

                if (defined($all_form_elements{$name})) {
                        $macros{$name} = $all_form_elements{$name};
                        delete $all_form_elements{$name};
                } else {
                        # TODO: handle error
                }

        }

        foreach my $name (keys %all_form_elements) {
                next if $name eq 'submit';
                # checkboxgroups return an array but since you don't
                # know its order in advance its easier to access a hash
                if (ref $all_form_elements{$name} =~ /ARRAY/) {
                        foreach my $element (@{$all_form_elements{$name}}) {
                                $macros{$name}->{$element} = 1;
                        }
                } else {
                        $macros{$name} = $all_form_elements{$name};
                }
        }

        open my $fh, "<", $config->{file} or return(qq(Can not open $config->{file}: $!));
        my $mpc = do {local $/; <$fh>};

        my $ttapplied;

        my $tt = new Template ();
        return $tt->error if not $tt->process(\$mpc, \%macros, \$ttapplied);

        my $cmd = Tapper::Cmd::Precondition->new();
        my @preconditions;
        eval {  @preconditions = $cmd->add($ttapplied)};
        return $@ if $@;

        $cmd->assign_preconditions($config->{testrun_id}, @preconditions);
        return \@preconditions;
}


sub fill_usecase : Chained('base') :PathPart('fill_usecase') :Args(0) :FormConfig
{
        my ($self, $c) = @_;
        my $form       = $c->stash->{form};
        my $position   = $form->get_element({type => 'Submit'});
        my $file       = $c->session->{usecase_file};
        my ($shortfile, undef, undef) = File::Basename::fileparse($file, ('.mpc'));
        my %macros;
        $c->res->redirect('/tapper/testruns/create') unless $file;

        my $config = $self->parse_macro_precondition($c, $file);

        # adding these elements to the form has to be done both before
        # and _after_ submit. Otherwise FormFu won't see the constraint
        # (required) in the form
        $c->stash->{description_text} = $config->{description_text};
        foreach my $element (@{$config->{required}}) {
                $element->{label} .= '*'; # mark field as required
                $form->element($element);
        }

        foreach my $element (@{$config->{optional}}) {
                $element->{label} .= ' ';
                $form->element($element);
        }

        if ($config->{mpc_config}) {
                $form->load_config_file( $config->{mpc_config} );
        }

        $form->elements({type => 'Submit', name => 'submit', value => 'Submit'});
        $form->process();

        if ($form->submitted_and_valid) {
                my $testrun_data = $c->session->{testrun_data};
                my @testhosts;

                # allow overwrite testrun topic
                my $testrun_topic = $form->input->{testrun_topic};
                if ($testrun_topic) {
                    $testrun_data->{topic} = $testrun_topic;
                } else {
                    $testrun_data->{topic} = "undefined-topic";
                }

                # hosts
                if ( defined ($testrun_data->{requested_hosts})){
                        if ( ref($testrun_data->{requested_hosts}) eq 'ARRAY') {
                                @testhosts = @{$testrun_data->{requested_hosts}};
                        } else {
                                @testhosts = ( $testrun_data->{requested_hosts} );
                        }
                } else {
                        @testhosts = map { $_->[0] } @{get_hostnames()};
                }

                $c->stash->{all_testruns} = [];
        HOST:
                for( my $i=0; $i < @testhosts; $i++) {
                        my $host = $testhosts[$i];
                        # we need a copy since we modify the hash before
                        # giving it to Tapper::Cmd and this
                        # modification would be used when the user clicks reload
                        my %testrun_settings     = %$testrun_data;
                        $testrun_settings{queue} = Tapper::Config->subconfig->{new_testrun_queue};

                        $c->stash->{all_testruns}[$i]{host} = $host;

                        $testrun_settings{requested_hosts} = $host;
                        my $cmd = Tapper::Cmd::Testrun->new();
                        eval { $config->{testrun_id} = $cmd->add(\%testrun_settings)};
                        if ($@) {
                                $c->stash->{all_testruns}[$i]{error} = $@;
                                next HOST;
                        }
                        $c->stash->{all_testruns}[$i]{id} = $config->{testrun_id};

                        $config->{file} = $file;
                        my $preconditions = $self->handle_precondition($c, $config);
                        if (ref($preconditions) eq 'ARRAY') {
                                $c->stash->{all_testruns}[$i]{ preconditions } = $preconditions;
                        } else {
                                $c->stash->{all_testruns}[$i]{ error } = $preconditions;
                        }

                }
        }
}


sub prepare_testrunlists : Private {

        my ( $or_self, $or_c, $hr_filter_condition ) = @_;

        my $b_view_pager  = 0;
        my $hr_params     = $or_c->req->params;
        my $hr_query_vals = {
            testrun_id          => $hr_filter_condition->{testrun_id},
            host                => $hr_filter_condition->{host},
            topic               => $hr_filter_condition->{topic},
            state               => $hr_filter_condition->{state},
            success             => $hr_filter_condition->{success},
            owner               => $hr_filter_condition->{owner},
        };

        require DateTime;
        if ( $hr_params->{testrun_date} ) {
            $hr_filter_condition->{testrun_date} = DateTime::Format::Strptime->new(
                pattern => '%F',
            )->parse_datetime( $hr_params->{testrun_date} );
        }
        elsif (! $hr_filter_condition->{testrun_id} ) {
                $hr_filter_condition->{testrun_date} = DateTime->now();
        }
        if ( $hr_params->{pager_sign} && $hr_params->{pager_value} ) {
            if ( $hr_params->{pager_sign} eq 'negative' ) {
                $hr_filter_condition->{testrun_date}->subtract(
                    $hr_params->{pager_value} => 1
                );
            }
            elsif ( $hr_params->{pager_sign} eq 'positive' ) {
                $hr_filter_condition->{testrun_date}->add(
                    $hr_params->{pager_value} => 1
                );
            }
        }

        if ( $hr_filter_condition->{testrun_date} ) {

            $or_c->stash->{pager_interval}  = $hr_params->{pager_interval} || 1;
            $or_c->stash->{testrun_date}    = $hr_filter_condition->{testrun_date};

            # set testrun date
            my $d_testrun_date_from = $hr_filter_condition->{testrun_date}->clone->subtract( days => $or_c->stash->{pager_interval} - 1 )->strftime('%d %b %Y');
            my $d_testrun_date_to   = $hr_filter_condition->{testrun_date}->strftime('%d %b %Y');

            if ( $d_testrun_date_from ne $d_testrun_date_to ) {
                $or_c->stash->{head_overview}   = "Testruns ($d_testrun_date_to - $d_testrun_date_from)";
            }
            else {
                $or_c->stash->{head_overview}   = "Testruns ($d_testrun_date_from)";
            }

            $hr_query_vals->{testrun_date_from} = $hr_filter_condition->{testrun_date}->clone->subtract( days => $or_c->stash->{pager_interval} - 1 )->strftime('%F');
            $hr_query_vals->{testrun_date_to}   = $hr_filter_condition->{testrun_date}->strftime('%F');

            $or_c->stash->{view_pager} = 1;

        }
        else {
            $or_c->stash->{head_overview}   = 'Testruns';
        }

        $or_c->stash->{testruns} = $or_c->model('TestrunDB')->fetch_raw_sql({
                query_name  => 'testruns::web_list',
                fetch_type  => '@%',
                query_vals  => $hr_query_vals,
        });

        return 1;

}

sub prepare_navi : Private
{
        my ( $self, $c ) = @_;

        my @a_args = @{$c->req->arguments};

        $c->stash->{navi} = [
                {
                        title  => 'Control',
                        href   => q##,
                        active => 0,
                        subnavi => [
                                {
                                        title  => 'Create new Testrun',
                                        href   => '/tapper/testruns/create/',
                                 },
                        ],
                },
        ];

        my @a_subnavi;
        OUTER: for ( my $i = 0; $i < @a_args; $i+=2 ) {
            my $s_reduced_filter_path = q##;
            for ( my $j = 0; $j < @a_args; $j+=2 ) {
                    next if $i == $j;
                    $s_reduced_filter_path .= "/$a_args[$j]/".$a_args[$j+1];
            }
            push @a_subnavi, {
                    title   => "$a_args[$i]: ".$a_args[$i+1],
                    image   => '/tapper/static/images/minus.png',
                    href    => '/tapper/testruns'
                             . $s_reduced_filter_path
                             . (
                                $c->stash->{view_pager}
                                    ? '?testrun_date='
                                    . $c->stash->{testrun_date}->strftime('%F')
                                    . '&amp;pager_interval='
                                    . $c->stash->{pager_interval}
                                    : ''
                                )
            };
        } # OUTER

        push @{$c->stash->{navi}},
            { title   => 'Active Filters', subnavi => \@a_subnavi, },
            { title   => 'New Filters', id => 'idx_new_filter' },
            { title   => 'Help', id => 'idx_help', subnavi => [{ title => 'Press Shift for multiple Filters' }] },
        ;

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Testruns

=head1 DESCRIPTION

Catalyst Controller.

=head2 index

Prints a list of a testruns together with their state, start time and
end time. No options, not return values.

TODO: Too many testruns, takes too long to display. Thus, we need to add
filter facility.

=head2 get_test_list_from_precondition

Utility function to extract testprograms from a given (sub-) precondition.

=head2 get_testrun_overview

This function reads and parses all precondition of a testrun to generate
a summary of the testrun which will then be shown as an overview. It
returns a hash reference containing:
* name
* arch
* image
* test

@param testrun result object

@return hash reference

=head2 new_create

This function handles the form for the first step of creating a new
testrun.

=head2 get_hostnames

Get an array of all hostnames that can be used for a new testrun.  Note:
The array contains array that contain the hostname twice (i.e. (['host',
'host'], ...) because that is what the template expects.

@return success - ref to array of [ hostname, hostname ]

=head2 parse_macro_precondition

Parse the given file as macro precondition and return a has ref
containing required, optional and mcp_config fields.

@param catalyst context
@param string - file name

@return success - hash ref
@return error   - string

=head2 handle_precondition

Check whether each required precondition has a value, uploads files and
so on.

@param  Catalyst context
@param  config hash

@return success - list of precondition ids
@return error   - error message

=head2 fill_usecase

Creates the form for the last step of creating a testrun. When this form
is submitted and valid the testrun is created based on the gathered
data. The function is used directly by Catalyst which therefore cares
for params and returns.

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Testruns - Catalyst Controller

=head1 METHODS

=head2 index

=head1 AUTHOR

Steffen Schwigon,,,

=head1 LICENSE

This program is released under the following license: freebsd

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
