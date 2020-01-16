package Net::Hadoop::Oozie;
$Net::Hadoop::Oozie::VERSION = '0.116';
use 5.010;
use strict;
use warnings;

use parent qw( Clone );

use URI;
use Carp qw( confess );
use Moo;
use Ref::Util qw(
    is_arrayref
    is_hashref
);
use Hash::Flatten  qw( :all );
use Date::Parse    qw( str2time );
use XML::Simple    qw( xml_in );
use XML::Twig;

use Constant::FromGlobal DEBUG => { int => 1, default => 0, env => 1 };

use Net::Hadoop::Oozie::Constants qw(:all);

with qw(
    Net::Hadoop::Oozie::Role::Common
    Net::Hadoop::Oozie::Role::LWP
);

has api_version => (
    is      => 'rw',
    isa     => sub {
        my $param = shift;
        if ( ! $RE_VALID_ENDPOINT->{ $param } ) {
            confess sprintf '%s is not a valid version', $param;
        }
    },
    default => 'v1',
    lazy    => 1,
);

has 'offset' => (
    is  => 'rw',
    isa => sub {
        confess "$_[0] is not an positive Int" if defined $_[0] && ($_[0] !~ /^[0-9]+$/ || $_[0] < 1);
    },
    default => sub { 1 },
    lazy    => 1,
);

has 'len' => (
    is  => 'rw',
    isa => sub {
        confess "$_[0] is not an positive Int" if defined $_[0] && ($_[0] !~ /^[0-9]+$/ || $_[0] < 1);
    },
    default => sub { 50 },
    lazy    => 1,
);

has 'order' => (
    is  => 'rw',
    isa => sub {
        confess "$_[0] should be asc or desc" if defined $_[0] && $_[0] !~ /^(desc|asc)$/;
    },
    default => sub { "asc" },
    lazy    => 1,
);

has doas => (
    is      => 'rw',
    isa     => sub {
        my $param = shift;
        confess "$param is not a valid username" if $param !~ /^[a-z]+$/;
    },
    lazy    => 1,
);

has 'show' => (
    is  => 'rw',
    isa => sub {
        if ( $_[0] && ! $IS_VALID_SHOW{ $_[0] || q{} } ) {
            confess "$_[0] is not a recognized show type";
        }
    },
    default => sub { q{} },
    lazy    => 1,
);

has 'action' => (
    is  => 'rw',
    isa => sub {
        if ( $_[0] && ! $IS_VALID_ACTION{ $_[0] || q{} } ) {
            confess "$_[0] is not a recognized action type";
        }
    },
    default => sub { q{} },
    lazy    => 1,
);

has 'jobtype' => (
    is  => 'rw',
    isa => sub {
        confess "$_[0] is not a recognized jobtype"
          if $_[0] && $_[0] !~ /^(|workflows|coordinators|bundles)$/;
    },
    coerce => sub { ($_[0] || '') eq 'workflows' ? '' : $_[0] },
    default => '',    # this seems to be the default, equivalent to 'workflows'
    lazy    => 1,
);

has 'filter' => (
    is      => 'rw',
    isa     => \&_process_filters,
    default => sub { return {} },
    lazy    => 1,
);

has expand_xml_conf => (
    is      => 'rw',
    default => sub { 0 },
);

has shortcircuit_via_callback => (
    is      => 'rw',
    default => sub { 0 },
);

#------------------------------------------------------------------------------#

# API

sub admin {
    my $self     = shift;
    my $endpoint = shift || confess "No endpoint specified for admin";
    my $valid    = $RE_VALID_ENDPOINT->{ $self->api_version };
    my $ep       = "admin/$endpoint";

    if ( $ep !~ $valid ) {
        confess sprintf '%s is not a valid admin endpoint!', $endpoint;
    }

    return $self->agent_request( $self->_make_full_uri( $ep ) );
}

sub kerberos_enabled {
    # All relevant config keys:
    #
    # oozie.authentication.kerberos.keytab
    # oozie.authentication.kerberos.name.rules
    # oozie.authentication.kerberos.principal
    # oozie.authentication.type
    # oozie.server.authentication.type
    # oozie.service.HadoopAccessorService.kerberos.enabled
    # oozie.service.HadoopAccessorService.kerberos.principal
    # oozie.service.HadoopAccessorService.keytab.file
    #

    state $krb_key = 'oozie.service.HadoopAccessorService.kerberos.enabled';
    my $self = shift;
    my $conf = $self->admin('configuration')
                    || confess "Failed to collect admin/configuration";
    my $krb_val = $conf->{ $krb_key } || return;
    return $krb_val eq 'true';
}

sub build_version {
    my $self = shift;
    my $version = $self->admin("build-version")->{buildVersion};
    return $version;
}

sub oozie_version {
    my $self = shift;
    my $build = $self->build_version;
    my($v) = split m{ [-] }xms, $build, 2;
    return $v;
}

sub max_node_name_len {
    my $self    = shift;
    my $version = $self->oozie_version;

    # A simple grep in oozie.git shows that it was always set to "50"
    # up until v4.3.0. So, no need to check any older version for even
    # lower limits.

    return $version ge '4.3.0' ? 128 : 50;
}

# Takes a hash[ref] for the options

sub jobs {
    my $self = shift->clone; # as we are clobbering lots of attributes

    my $options = @_ > 1 ? {@_} : ($_[0] || {});

    # TODO: this is a broken logic!
    #
    for (qw(len offset jobtype)) {
        $self->$_($options->{$_}) if defined $options->{$_};
    }

    # TODO: rework this, logic makes no sense. Filter should have a default and
    # be overridable in a flexible manner
    $self->filter(
        $options->{filter}
        || $self->filter
        || { status => "RUNNING" }
    ); # maybe merge instead?

    my $jobs = $self->agent_request( $self->_make_full_uri('jobs') );

    $self->_expand_meta_data($jobs); # make this optional given the horrible implementation?

    return $jobs;
}

# IMPORTANT ! FIXME ?
#
# when querying a coordinator, the actions field will contain action details,
# in execution order. Since the defaults are offset 1 and len 50, for most
# coordinators this information will be useless. the proper way of querying
# would then be (to obtain the last 50 actions):
#
#  my $details = Net::Hadoop::Oozie->new({ len => 1 })->job( $coordJobId );
#  my $total_actions = $details->{total};
#  my $offset = $details->{total} - 49;
#  $offset = 1 if $offset < 1;
#  $details = Net::Hadoop::Oozie->new({ len => 50, offset => $offset })->job( $coordJobId );
#
#  NOTE: this should be fixed in oozie 4, which has an 'order' (asc by default, can be desc) parameter

sub job {
    my $self = shift->clone; # as we are clobbering lots of attributes
    my $id = shift || confess "No job id specified";
    my $options;
    if ( ref $_[0] eq 'HASH') {
        $options = shift;
    }
    else {
        $options = {@_};
    }

    for ( JOB_OPTIONS ) {
        $self->$_($options->{$_}) if defined $options->{$_};
    }

    $self->show( 'info' ) if !$self->show;

    my $job = $self->agent_request( $self->_make_full_uri('job/' . $id ) );
    $self->_expand_meta_data($job); # make this optional given the horrible implementation?

    return $job;
}

# Take hashes for options

sub coordinators {
    my $self = shift;
    return $self->jobs( jobtype => 'coordinators', @_ );
}

sub workflows {
    my $self = shift;
    return $self->jobs( jobtype => '', @_ );
}

#------------------------------------------------------------------------------#

# EXTENSIONS

# This will return the job data if the job exists to prevent a second call
#
sub job_exists {
    my $self = shift;
    my $id   = shift || confess "No job id specified";
    my $ok;

    eval {
        $ok = $self->job( $id, @_ );
        1;
    } or do {
        my $eval_error = $@ || 'Zombie error';
        confess $eval_error if $eval_error !~ $RE_BAD_REQUEST;
    };

    return $ok;
}

sub submit_job {
    # TODO: verify the existence of the workflow on HDFS

    my $self = shift;
    my ($config) = @_ == 1 ? $_[0] : { @_ };
    
    $config = {
        'user.name' => 'mapred',
        %{ $config },
    };

    for (qw(
        appName
        oozie.wf.application.path
    )) {
        if ( ! $config->{$_} ) {
            die "No $_ provided in submit_job()";
        }
    }

    my $xml_config = XML::Twig->new();
    $xml_config->set_encoding("UTF-8");
    $xml_config->set_root(my $root = XML::Twig::Elt->new('configuration'));
    while (my ($k, $v) = each %$config) {
        $xml_config->root->insert_new_elt(
            'last_child', 'property', {},
            XML::Twig::Elt->new( 'name',  {}, $k ),
            XML::Twig::Elt->new( 'value', {}, $v ),
        );
    }
    $xml_config->trim->set_pretty_print('indented');
    my $content = $xml_config->sprint;

    if ($config->{debug}) {
        warn sprintf "XML payload (job config): %s\n", $content;
    }

    # remove some params, add one, to get a valid endpoint url
    # really not happy about how I did this initially, it needs to be cleaned
    # up at some stage (state is way too permanent, should be reinitialized
    # between calls)
    my $saved_offset = $self->offset();
    my $saved_len    = $self->len();
    my $saved_action = $self->action();

    $self->offset(undef);
    $self->len(undef);
    $self->action('start');

    my $uri = $self->_make_full_uri('jobs');
    my $res = $self->agent_request( $uri, 'post', $content );

    if ($config->{debug} || !$res->{id}) {
        local $Data::Dumper::Terse = 1;
        print "JSON response: ", Data::Dumper::Dumper $res;
    }
    
    $self->offset($saved_offset);
    $self->len($saved_len);
    $self->action($saved_action);
    
    return $res->{id}; 
}

sub _collect_suspended {
    my $self = shift;
    my $opt  = shift || {};

    die "Options need to be a HASH" if ! is_hashref $opt;

    my $is_coord = $opt->{is_coord};
    my $key      = $is_coord ? 'coordinatorjobs' : 'workflows';

    $self->filter( { status => [qw( SUSPENDED )] } );

    my(@wanted);

    $self->_jobs_iterator(
        jobtype => $is_coord ? 'coordinators' : '',
        {
            ( $is_coord ? (
            is_coordinator => 1,
            ):()),
            callback => sub {
                my $job = shift;
                return 1 if ! $job->{ $key };
                push @wanted, @{ $job->{ $key } };
                return 1;
            },
        }
    );

    return \@wanted;
}

sub suspended_workflows {
    shift->_collect_suspended;
}

sub suspended_coordinators {
    shift->_collect_suspended({ is_coord => 1 });
}

sub active_coordinators {
    my $self = shift;
    my $opt  = ref $_[0] eq 'HASH' ? shift @_ : {};
    $opt->{status} ||= [qw(
        RUNNING
        PREP
    )];

    $self->filter( { status => $opt->{status} } );

    my(@wanted, $default_cb);
    $opt->{callback} ||= do {
        $default_cb = 1;
        sub {
            my $job = shift;
            push @wanted, @{ $job->{coordinatorjobs} };
            return 1;
        }
    };

    $self->_jobs_iterator(
        jobtype => 'coordinators',
        {
            callback       => delete $opt->{callback},
            is_coordinator => 1,
        }
    );

    return $default_cb ? \@wanted : ();
}

sub standalone_active_workflows {
    my $self  = shift;
    my $opt  = ref $_[0] eq 'HASH' ? shift @_ : {};
    $opt->{status} ||= [qw(
        RUNNING
        PREP
    )];

    $self->filter( { status => $opt->{status} } );

    my(@wanted, $default_cb);
    $opt->{callback} ||= do {
        $default_cb = 1;
        sub {
            my $job = shift;
            push @wanted,
                map  {
                    # - /jobs endpoint might be lying to you about certain fields:
                    #       https://issues.apache.org/jira/browse/OOZIE-2418
                    # Also check the status of the above ticket and remove
                    # the aggressive logic down below if it's fixed.
                    defined $_->{appPath}
                                ? $_
                                : $self->job( $_->{id} )
                }
                grep { ! $_->{parentId} }
                    @{ $job->{workflows} };
            return 1;
        }
    };

    $self->_jobs_iterator(
        jobtype => '',
        {
            callback => $opt->{callback},
        }
    );

    return $default_cb ? \@wanted : ();
}

sub active_job_paths {
    state $is_type = {
        map { $_ => 1 } qw(
            all
            coordinator
            wf
        )
    };

    my $self    = shift;
    my $type    = shift;
    my $oozie_base_path = shift || '';
    my $re_hdfs_base;
    if ( $oozie_base_path ) {
        $re_hdfs_base = qr{ \A \Q$oozie_base_path\E }xms;
    }
    

    if ( ! $type || ! $is_type->{ $type } ) {
        die sprintf "Unknown type `%s` was specified. Valid options are: '%s'.",
                        $type // '[undefined]',
                        join(q{', '}, sort keys %{ $is_type }),
        ;
    }

    my %path;

    my $collect = sub {
        my($all_jobs, $id_name, $path_name, $wanted_fields) = @_;

        foreach my $this_job ( @{ $all_jobs } ) {
            my $hdfs_path = $this_job->{ $path_name };
            push @{ $path{ $hdfs_path } ||= [] },
                {
                    $this_job->{ $id_name } => {
                        (
                            map { $_ => $this_job->{ $_ } }
                                @{ $wanted_fields }
                        ),
                        ( $re_hdfs_base && $hdfs_path !~ $re_hdfs_base ? (
                            # shouldn't happen, but you can never know
                            alien => 1,
                        ): ()),
                    },
                }
            ;
        }

        return 1;
    };

    my @status = qw/
        PREP
        RUNNING
        SUSPENDED
    /;

    if ( $type eq 'coordinator' || $type eq 'all' ) {
        $self->active_coordinators({
            status   => \@status,
            callback => sub {
                my $job = shift;
                $collect->(
                    $job->{coordinatorjobs},
                    'coordJobId',
                    'coordJobPath',
                    [qw( coordJobName status )],
                );
                return 1;
            },
        });
    }

    if ( $type eq 'wf' || $type eq 'all' ) {
        $collect->(
            $self->standalone_active_workflows({ status => \@status }),
            'id',
            'appPath',
            [qw( appName status )],
        );
    }

    return \%path;
}

# better be verbose than a cryptic shortname
#
sub coordinators_with_the_same_appname_on_the_same_path {
    my $self  = shift;
    my $apath = $self->active_job_paths('coordinator');

    my $multi = {
        map  { $_ => $apath->{$_} }
        grep { @{ $apath->{$_} } > 1 }
        keys %{ $apath }
    };

    my $dupe = {};
    for my $path ( keys %{ $multi } ) {
        for my $coord ( @{ $multi->{ $path } }) {
            foreach my $cid ( keys %{ $coord } ) {
                my $meta = $coord->{ $cid };
                # filter status=RUNNING?
                push @{ $dupe->{ $meta->{ coordJobName } } ||= [] }, $cid;
            }
        }
    }
    return map   { $_ => $dupe->{$_}    }
           grep  { @{ $dupe->{$_} } > 1 }
           keys %{ $dupe };
}

sub coordinators_on_the_same_path {
    my $self  = shift;
    my $apath = $self->active_job_paths('coordinator');

    my $multi = {
        map  { $_ => $apath->{$_} }
        grep { @{ $apath->{$_} } > 1 }
        keys %{ $apath }
    };

    my %rv;
    for my $path ( keys %{ $multi } ) {
        for my $coord ( @{ $multi->{ $path } }) {
            foreach my $cid ( keys %{ $coord } ) {
                my $meta = $coord->{ $cid };
                # filter status=RUNNING?
                $rv{ $path }{ $cid } = $meta->{ coordJobName };
            }
        }
    }

    return %rv;
}

# param 1 : fractional hours
# param 2 : pattern for appname filtering

sub failed_workflows_last_n_hours {
    my $self    = shift;
    my $n_hours = shift || 1;
    my $pattern = shift;
    my $opt     = shift || {
                    parent_info => 1,
                };

    confess "Options need to be a hash" if ! is_hashref $opt;

    # can be slow to collect if there are too many coordinators
    # as there will be a single api request per coordinator id
    # might be good to investigate a bulk request for that.
    #
    my $want_parent_info = $opt->{parent_info};

    $self->filter( { status => [qw(FAILED SUSPENDED KILLED)] } );
    my $jobs = $self->jobs(jobtype => 'workflows');

    my @failed;
    my $console_url_base;    # not available in coordinators, we'll use a trick
    for my $workflow ( @{ $jobs->{workflows} } ) {

        next if ($pattern && $workflow->{appName} !~ /$pattern/);

        if ((     !$workflow->{endTime_epoch}
                && $workflow->{startTime_epoch} >= time - $n_hours * 3600
            )
            || $workflow->{endTime_epoch}
            && $workflow->{endTime_epoch} >= time - $n_hours * 3600
            )
        {
            if ( !$console_url_base ) {
                ( $console_url_base = $workflow->{consoleUrl} ) =~ s/job=.*/job=/;
            }
            my $details =  $self->job( $workflow->{id} );

            my ($error) = map { $_->{errorMessage} ? $_->{errorMessage} : () } @{$details->{actions}||[]};

            # Extract some data from the workflow xml config to:
            # - check wether the workflow should be skipped from this list: if
            #   it has parameters.timeoutSkipErrorMail set (emk workflows,
            #   for instance, where timeout is a normal condition)
            # - gather the parameters.errorEmailTo addresses, for automated
            #   sending
            my $conf = eval { xml_in($details->{conf}) } || {};
            for (qw(timeoutSkipErrorMail errorEmailTo)) {
                $workflow->{$_} = $conf->{property}{$_}{value};
            }

            my $parent_id = $workflow->{parentId} = $details->{parentId}
                // "";

            # This workflow was triggered by a coordinator, let's get some info
            if ($parent_id && $want_parent_info ) {
                $parent_id =~ s/\@[0-9]+$//;
                my $parent = $self->job($parent_id);
                $workflow->{parentConsoleUrl}
                    = $parent->{coordJobId}
                    ? $console_url_base . $parent->{coordJobId}
                    : 'not found';
                $workflow->{parentStatus}  = $parent->{status};
                $workflow->{parentAppname} = $parent->{coordJobName};
                $workflow->{parentId}      = $parent->{coordJobId};
                $workflow->{scheduled}++;
            }
            $workflow->{errorMessage}  = $error || '-';
            push @failed, $workflow;
        }
    }
    return \@failed;
}

sub failed_workflows_last_n_hours_pretty {
    my $self             = shift;
    my $failed_workflows = $self->failed_workflows_last_n_hours(shift);

    return if ! is_arrayref( $failed_workflows ) || ! @{ $failed_workflows };

    my ($out, $previous_is_scheduled);
    for my $wf (
        sort {
            ( $b->{scheduled} || 0 ) <=> ( $a->{scheduled} || 0 )
                || $b->{lastModTime_epoch} <=> $a->{lastModTime_epoch}
        } @$failed_workflows
        )
    {
        # insert a separation between scheduled and standalone wfs
        if ($previous_is_scheduled && !$wf->{scheduled}) {
            $out .= "\n" . "-"x50 . "\n" if $out;
            $previous_is_scheduled = 0;
        }
        $previous_is_scheduled++ if $wf->{scheduled};

        $out .= "\n" if $out;

        $out .= sprintf
            "* %s (%s):\n    Id: %s\n    ConsoleURL: %s\n    Status: %s\n    Error: %s\n",
            $wf->{appName}, ( $wf->{scheduled} ? "SCHEDULED" : "standalone" ),
            @{$wf}{qw(id consoleUrl status errorMessage)};

        if ( $wf->{parentId} ) {
            $out
                .= sprintf
                "  Coordinator info:\n    Appname: %s\n    Id: %s\n    ConsoleURL: %s\n    Status: %s\n",
                @{$wf}{qw(parentAppname parentId parentConsoleUrl parentStatus)};
        }
    }
    return $out;
}

sub coord_rerun {
    my $self = shift;

    # coord ID is like 0390096-150728120555443-oozie-oozi-C
    # actions can be like '1', '10-12', '1,2,4-6', etc.
    my ( $coord_id, $actions, $debug ) = @_;
    $actions =~ s/\s+//g;
    my $saved_action = $self->action();
    $self->action('coord-rerun');

    my $uri = $self->_make_full_uri( 'job/' . $coord_id );
    $uri->query_form(
        $uri->query_form,
        type      => 'action',
        scope     => $actions,
        refresh   => 'true',
        nocleanup => 'false',
    );
    my $error;
    my $res = eval { $self->agent_request( $uri, 'put' ) } or do {
        $error = $@;
        warn "oozie server returned an error:\n$error";
    };

    $self->action($saved_action);
    return if $error;

    if ( $debug || !@{ $res->{actions} || [] } ) {
        local $Data::Dumper::Terse = 1;
        warn "JSON response: ", Data::Dumper::Dumper $res;
    }

    # return some of the response
    my $ret;
    for ( @{ $res->{actions} || [] } ) {
        push @$ret, [ $_->{id}, $_->{status} ];
    }
    return $ret;
}

sub kill {
    my $self = shift;
    my ( $id, $debug ) = @_;
    my $saved_action = $self->action();
    $self->action('kill');

    my $error;
    my $uri = $self->_make_full_uri( 'job/' . $id );
    my $res = eval { $self->agent_request( $uri, 'put' ) } or do {
        $error = $@;
        warn "oozie server returned an error:\n$error";
    };
    $self->action($saved_action);
    return if $error;
    return 1;
}

sub resume {
    my $self = shift;
    my ( $id, $debug ) = @_;
    my $saved_action = $self->action();
    $self->action('resume');

    my $error;
    my $uri = $self->_make_full_uri( 'job/' . $id );
    my $res = eval { $self->agent_request( $uri, 'put' ) } or do {
        $error = $@;
        warn "oozie server returned an error:\n$error";
    };
    $self->action($saved_action);
    return if $error;
    return 1;
}

#------------------------------------------------------------------------------#

sub _process_filters {
    my $filter = shift;
    return if ! is_hashref $filter;
    my @unknown = grep { $_ !~ /^(name|user|group|status)$/ } keys %$filter;
    local $" = ", ";
    confess "unknown filter name(s): @unknown" if @unknown;
    for my $name ( keys %$filter ) {
        confess "filter is not a string or an array of strings"
          if ( ref $filter->{$name} && ! is_arrayref $filter->{$name} );

        # lazy, so let's turn a single string to an array of one
        $filter->{$name} = [ $filter->{$name} ] if !ref $filter->{$name};

        for my $filter_value ( @{ $filter->{$name} } ) {

            confess "empty value specified for filter $name"
              if !length $filter_value;

            confess "'$filter_value' is not a valid status"
              if $name eq "status"
                  && $filter_value !~ $RE_VALID_STATUS;
        }
    }
    return $filter;
}

sub _make_full_uri {
    my $self = shift;
    my $endpoint= shift;

    if ( $endpoint !~ $RE_VALID_ENDPOINT->{$self->api_version} ) {
        confess "endpoint '$endpoint' is not supported";
    }

    my $uri    = URI->new( $self->oozie_uri );
    my %filter = %{ $self->filter };

    my ( @accepted_params, @base_params, $do_filter_string, $filter_string );

    # very few params accepted for 'job', more for other reqs
    # only 1 param for some job actions (the rest bypasses this old mechanism
    # by injecting in URI directly, urgh)
    if ( $endpoint =~ /^job\// && $self->action =~ /^(coord-rerun|kill|resume)$/ ) {
        @accepted_params = qw( action );
    }
    elsif ( $endpoint =~ /^job\// ) {
        @accepted_params = qw( len offset show doas order );
    }
    else {
        $do_filter_string++;
        @accepted_params = qw( len offset jobtype show action doas order );
    }

    @base_params = map {
        my $value = $self->$_;
        defined $value && length $value > 0 ? ( $_ => $value ) : ()
    } @accepted_params;

    # the filter parameter requires URL encoding, so we treat it differently.
    # It will be encoded by query_form once we have assembled it
    if ($do_filter_string) {
        my @filter_string;
        while ( my ( $name, $values ) = ( each %filter ) ) {
            push @filter_string, join ';', map {"$name=$_"} @$values;
        }
        $filter_string = join ';', @filter_string;
    }

    $uri->query_form( [ @base_params, ($filter_string ? (filter => $filter_string) : ()) ] );
    $uri->path( sprintf "%s/%s/%s", $uri->path,$self->api_version, $endpoint );

    printf STDERR "URI: %s\n", $uri if DEBUG;

    return $uri;
}

# [dmorel] Add *_epoch to all nested data structures appearing to contain (GMT) dates. I
# suspect someone will harm me for doing it this way.

sub _expand_meta_data {
    my $self = shift;
    my ($jobs) = @_;

    my $expand_xml_conf = $self->expand_xml_conf;
    my $uri = URI->new( $self->oozie_uri );

    # Jobs is supposed to be a 2-level JSON hash
    my $flat_jobs = flatten($jobs);
    for my $k (keys %$flat_jobs) {
        my $v = $flat_jobs->{$k};

        # add epochs
        if ( ( $v || '' ) =~ m/ GMT$/ ) {
            my $epoch = str2time($v);
            if ($epoch) {
                $flat_jobs->{"${k}_epoch"} = $epoch;
            }
        }
        # add consoleURL for coordinators
        if ($k =~ /(^.+)\.coordJobId$/ && $v) {
            $uri->query_form(job => $v);
            $flat_jobs->{"$1.consoleUrl"} = "$uri";
        }
    }

    %{ $jobs } = %{ unflatten $flat_jobs };

    if ( $expand_xml_conf ) {
        my $expand = sub {
            my $data = shift;
            eval {
                my $cs = $data->{conf_struct} = xml_in( $data->{conf}, KeepRoot => 1 );
                1;
            } or do {
                my $eval_error = $@ || 'Zombie error';
                warn "Failed to map the Oozie job configuration to a data structure: $eval_error";
            };
        };

        if ( my $conf = $jobs->{conf} ) {
            if ( ! ref $conf && $conf =~ m{ \A \Q<configuration>\E \s+ \Q<property>\E}xms ) {
                $expand->( $jobs );
            }
        }

        foreach my $action ( @{ $jobs->{actions} } ) {
            my $conf = $action->{conf} || next;
            if ( ! ref $conf && $conf =~ m{ \A [<] }xms ) {
                $expand->( $action );
            }
        }
    }

    return;
}

sub _jobs_iterator {
    my $self  = shift;
    my @param = @_;
    my $opt   = @param && ref $param[-1] eq 'HASH' ? pop @param : {};
    my $cb    = delete $opt->{callback};

    if ( ref $cb ne 'CODE' ) {
        die "callback either not specified or is not a CODE";
    }

    my($len, $offset, $total, $total_jobs);
    my $key = $opt->{is_coordinator} ? 'coordinatorjobs' : 'workflows';
    my $shortcircuit = $self->shortcircuit_via_callback;
    my $eof;

    do {
        my $jobs = $self->jobs(
                        @param,
                        ( $offset ? (
                        offset  => $offset,
                        len     => $len,
                        ) : ())
                    );
        ($len, $offset, $total) = @{ $jobs }{qw/ len offset total /};
        $total_jobs += $jobs->{ $key } ? @{$jobs->{ $key }} : 0; # len overflow
        $offset     += $len;

        my $ok = $cb->( $jobs );

        if ( $shortcircuit ) {
            # If the option above is enabled, then the callback always need to
            # return true to be able to continue.
            #
            if ( ! $ok ) {
                if ( DEBUG ) {
                    printf STDERR "_jobs_iterator(short-circuit): callback returned false.\n";
                }
                $eof = 1;
            }
        }

    } while ! $eof && $offset < $total;

    if ( !$shortcircuit && $total_jobs != $total ) {
        warn "Something is wrong, the collected total workflows and the computed total mismatch ($total_jobs != $total)";
    }

    return;
}

sub failed_last_n_hours{
    my ( $self, $workflow, $n_hours ) = @_;
    return (
                (
                    !$workflow->{endTime_epoch}
                    && $workflow->{startTime_epoch} >= time - $n_hours * 3600
                )
                ||
                (
                    $workflow->{endTime_epoch}
                    && $workflow->{endTime_epoch} >= time - $n_hours * 3600
                )
            );
}

sub failed_workflows_nr {
    my ( $self, $n_hours ) = @_;
    $self->filter( { status => [qw(FAILED SUSPENDED KILLED)] } );
    my $jobs = $self->jobs( jobtype => 'workflows', len => 1_000 );
    return scalar( grep { $self->failed_last_n_hours( $_, $n_hours ) } @{$jobs->{workflows}} );
}

sub failed_workflows_last_n_hours_paged {
    my $self    = shift;
    my $n_hours = shift || 1;
    my $pattern = shift;
    my $opt     = shift || { parent_info => 1 };

    my $want_parent_info   = $opt->{parent_info};
    my $page_size          = $opt->{page_size} // 50;
    my $page_nr            = $opt->{page_nr}   //  1;
    my $current_pos        = 1;
    my $failed_workflow_nr = $self->failed_workflows_nr( $n_hours );
    my $total_page_nr      = ceil( $failed_workflow_nr/$page_size );

    $page_nr = $total_page_nr if $page_nr>$total_page_nr;

    my(@failed, $console_url_base);
    my $cb = sub {
        my $jobs = shift;
        my $workflows = $jobs->{workflows};
        for my $workflow ( @$workflows ){
            next if ($pattern && $workflow->{appName} !~ /$pattern/);
            if ( $self->failed_last_n_hours($workflow,$n_hours) )
                {
                    if( $current_pos <= $page_size * ($page_nr-1) ){
                        $current_pos ++;
                        next;
                    }
                    if ( !$console_url_base ) {
                        ( $console_url_base = $workflow->{consoleUrl} ) =~ s/job=.*/job=/;
                    }
                    my $details =  $self->job( $workflow->{id} );
                    my ($error) = map { $_->{errorMessage} ? $_->{errorMessage} : () } @{$details->{actions}||[]};
                    my $conf = eval { xml_in($details->{conf}) } || {};
                    for (qw(timeoutSkipErrorMail errorEmailTo)) {
                        $workflow->{$_} = $conf->{property}{$_}{value};
                    }
                    my $parent_id = $workflow->{parentId} = $details->{parentId}
                                    // "";
                    if ($parent_id && $want_parent_info ) {
                        $parent_id =~ s/\@[0-9]+$//;
                        my $parent = $self->job($parent_id);
                        $workflow->{parentConsoleUrl}
                            = $parent->{coordJobId}
                            ? $console_url_base . $parent->{coordJobId}
                            : 'not found';
                        $workflow->{parentStatus}  = $parent->{status};
                        $workflow->{parentAppname} = $parent->{coordJobName};
                        $workflow->{parentId}      = $parent->{coordJobId};
                        $workflow->{scheduled}++;
                    }
                    $workflow->{errorMessage}  = $error || '-';
                    push @failed, $workflow;
                    if (
                        @failed >= $page_size
                        || @failed >= $failed_workflow_nr - $page_size*($page_nr-1)
                    ) {
                        return;
                    }
                }
        }
        return 1;
    };

    $self->_jobs_iterator({ is_coordinator => 0, callback => $cb });

    return ( $total_page_nr, $page_nr, \@failed );
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Net::Hadoop::Oozie - Interface to various Oozie REST endpoints and utility methods.

=head1 VERSION

version 0.116

=head1 DESCRIPTION

This module is a Perl interface to Oozie REST service endpoints and also include
some utility methods for some bulk requests and some admin functionality.

=head1 SYNOPSIS

    use Net::Hadoop::Oozie;
    my $oozie = Net::Hadoop::Oozie->new( %options );

=head1 ACCESSORS

=head2 action

=head2 api_version

=head2 doas

=head2 filter

The submission format is C<filter_key1=filter_value1;filter_key2=...;>, but
the filters are defined as a hash.

    filter => {
        status => ...,
    }

The valid filters are listed below.

=over 4

=item name

The application name from the workflow/coordinator/bundle definition

=item user

The user that submitted the job

=item group

The group for the job

=item status

The status of the job

=back

You need to consider a certain behavior when using filters:

=over 4

=item *

The query will do an AND among all the filter names.

=item *

The query will do an OR among all the filter values for the same name.

=item *

Multiple values must be specified as different name value pairs.

=back

=head2 jobtype

The doc says workflow, coordinator, bundle BUT in CDH 4.4, valid
values are '','coordinators' and 'bundles'. C<workflows> and
C<coordinator> methods are helper functions setting these
values behind the scenes.

=head2 len

Defaults to  C<50>.

=head2 offset

Defaults to  C<1>.

=head2 order

Default is C<asc>, can be C<asc> or C<desc>. For instance, when used on a
coordinator in a C<job> call, using desc will put the C<len> most recent
actions in the actions key, in most recent order first; the C<offset> is then
applied from the end of the list.

=head2 show

=head1 METHODS

=head2 END POINTS

=head3 admin

=head3 build_version

=head3 coord_rerun

=head3 coordinators

=head3 job

=head3 jobs

=head3 kill

=head3 resume

=head3 submit_job

For details about job submission through REST, see
L<https://oozie.apache.org/docs/4.2.0/WebServicesAPI.html#Job_Submission>.

Required parameters are listed below.

=over 4

=item * oozie.wf.application.path

Like F</oozie_workflows/myworkflow>, must be deployed there already.

=item * appName

How this specific instance will be called, can be anything you want.

=back

Optional parameters are listed below.

=over 4

=item Auto variables

If you want some variable interpolated in your script (like a date, an int,
or whatever), pass it in the options you call the method with. if you pass
C<< foo => 'bar', >> inside the workflow you will be able to use it as C<${foo}>.

=item Configuration properties

Useful parameters for oozie itself (like the queue name) need AFAICT an
extra level of handling. they can be set dynamically, but need a tweak in
the workflow definition itself, in the top config section; for instance, if
we need to specify C<mapreduce.job.queuename> to assign the tasks to a
specific fair scheduler queue, we need to declare it in the global configuration
section, like this:

    <property>
        <name>mapreduce.job.queuename</name>
        <value>${queueName}</value>
    </property>

And we will call L</submit_job> adding this to the options hash:

    queueName => "root.<queue name>"

=back

This method returns a job ID which you can use directly to query the job
status, with the L</job> method above, so you can launch a job from a
script, and have a loop query the job status at regular intervals (be nice,
please) to check when it's done (untested code :-).

    my $oozie = Net::Hadoop::Oozie->new;
    my $job_params = [
        { appName => 'job1', myParam => 'foo' },
        { appName => 'job2', myParam => 'bar' },
        ...
    ];
    for my $job (@$job_params) {
        my $jobid = $oozie->submit_job({
            myParam                     => $job->{myParam},
            debug                       => 0, # set to 1 to print the job config and response
            appName                     => $job->{appName},
            'oozie.wf.application.path' => "/wf_base_path/<workflow name>/",
        });
        push @ids, $jobid;
    }

    while (my $jobid = shift @ids) {
        my $status;
        if (($status = $oozie->job($jobid)->{status}) =~ /(WAITING|READY|SUBMITTED|RUNNING)/)) {
            push @ids, $jobid; # put back in the queue
            sleep 10; # or more, how about 60?
        }
        # what do you want to do if not succeeded?
        if ($status !~ /SUCCEEDED/) {
            die "job $jobid died";
        }
    }


=head3 workflows

=head2 UTILITY METHODS

=head3 active_coordinators

=head3 active_job_paths

=head3 coordinators_on_the_same_path

=head3 coordinators_with_the_same_appname_on_the_same_path

Returns a hash consisting of duplicated application names for multiple coordinators.
Having coordinators like this is usually an user error when submitting jobs.

    my %offenders = $oozie->coordinators_with_the_same_appname_on_the_same_path;

=head3 failed_workflows_last_n_hours

    my %options = ( # all keys are optional
        parent_info => Bool, # default: 1
    );

    my $failed_arrayref = $oozie->failed_workflows_last_n_hours( $hours, $pattern, \%options );

=head3 failed_workflows_last_n_hours_pretty

    my $string = $oozie->failed_workflows_last_n_hours_pretty( $hours );

=head3 failed_workflows_last_n_hours_paged

    my %options = ( # all keys are optional
        parent_info => Bool, # default: 1
        page_size   => Int,  # default: 50
        page_nr     => Int,  # default: 1
    );

    my(
        $total_page_nr,
        $page_nr,
        $failed_arrayref,
    ) = $oozie->failed_workflows_last_n_hours_paged(
            $hours,
            $pattern,
            \%options,
        );

=head3 job_exists

This is a sugar interface on top of the L</job> method. Normally the REST interface
just dies with an C<HTTP 400> message on missing jobs. This method won't die
and will return the data set if there is a proper response from the service.
It will return false otherwise.

    if ( my $job = $oozie->job_exists( $id ) ) {
        # do something
    }
    else {
        warn "No such job: $id";
    }

=head3 kerberos_enabled

Returns true if kerberos is enabled

=head3 max_node_name_len

Returns the value of the hardcoded (in Oozie Java code) C<MAX_NODE_NAME_LEN>
value by probing the Oozie server version. This is the maximum length of
an Oozie action name that can be in your workflow definitions. If longer action
names are deployed and scheduled, then the Oozie server will happily schedule a
coordinator but the individual workflow runs will throw exceptions and and no
part of the job will get executed. Also note that (if you didn't guess already)
oozie validation function will validate and pass such names (unless you have
a recent Oozie version which pushes the validation on the server side).

The relevant part in the Oozie source:

    core/src/main/java/org/apache/oozie/util/ParamChecker.java
    private static final int MAX_NODE_NAME_LEN = {Integer};

Currently there is no way to probe the value of this constant through the APIs,
but it is possible to map a limit to certain Oozie versions.

Oozie version C<4.3.0> and later sets the limit to C<128> while anything older
than that will have the value C<50> (for the time being).

This method, checks the Oozie server version and returns the relevant limit for
that version.

See these Oozie Jira tickets for more information:

=over 4

=item *

L<https://issues.apache.org/jira/browse/OOZIE-2025>.

=item *

L<https://issues.apache.org/jira/browse/OOZIE-2168>.

=back

Checking the limit is especially important if you are deploying the Oozie jobs
with custom code generators (instead of hand writing all of the XML) and this
helper method will give you the ability to display meaningful exceptions to the
users, instead of the obscure Oozie ones in the Oozie console.

=head3 oozie_version

Just a sugor interface on top of C<build_version> trying to return the actual
numerical C<Oozie> version without the build string.

    my $oozie_version = $oozie->oozie_version;
    # Something like "4.1.0"

=head3 standalone_active_workflows

Returns an arrayref of standalone workflows (as in jobs not attached to
a coordinator):

    my $wfs_without_a_coordinator = $oozie->standalone_active_workflows;
    foreach my $wf ( @{ $wfs_without_a_coordinator } ) {
        # do something
    }

=head3 suspended_coordinators

Returns an arrayref of suspended coordinators:

    my $suspended = $oozie->suspended_coordinators;
    foreach my $coord ( @{ $suspended } ) {
        # do something
    }

=head3 suspended_workflows

Returns an arrayref of suspended workflows:

    my $suspended = $oozie->suspended_workflows;
    foreach my $wf ( @{ $suspended } ) {
        # do something
    }

=cut
