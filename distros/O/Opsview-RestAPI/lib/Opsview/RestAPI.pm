use 5.12.1;
use strict;
use warnings;

package Opsview::RestAPI;
$Opsview::RestAPI::VERSION = '1.191660';
# ABSTRACT: Interact with the Opsview Rest API interface

use version;
use Data::Dump qw(pp);
use Carp qw(croak);
use REST::Client;
use JSON;
use URI::Encode::XS qw(uri_encode);

use Opsview::RestAPI::Exception;


sub new {
    my ( $class, %args ) = @_;
    my $self = bless {%args}, $class;

    $self->{url} ||= 'http://localhost';
    $self->{ssl_verify_hostname} //= 1;
    $self->{username} ||= 'admin';
    $self->{password} ||= 'initial';
    $self->{debug} //= 0;

    # Create the conenction here to info can be called before logging in
    $self->{json} = JSON->new->allow_nonref;

    $self->{client} = REST::Client->new();
    $self->_client->setHost( $self->{url} );
    $self->_client->addHeader( 'Content-Type', 'application/json' );

    # Set the SSL options for use with https connections
    $self->_client->getUseragent->ssl_opts(
        verify_hostname => $self->{ssl_verify_hostname} );

    # Make sure we follow any redirects if originally given
    # http but get redirected to https
    $self->_client->setFollow(1);

    # and make sure POST will also redirect correctly (doesn't by default)
    push @{ $self->_client->getUseragent->requests_redirectable }, 'POST';

    return $self;
}

# internal convenience functions
sub _client { return $_[0]->{client} }
sub _json   { return $_[0]->{json} }

sub _log {
    my ( $self, $level, @message ) = @_;
    say scalar(localtime), ': ', @message if ( $level <= $self->{debug} );
    return $self;
}

sub _dump {
    my ( $self, $level, $object ) = @_;
    say scalar(localtime), ': ', pp($object) if ( $level <= $self->{debug} );
    return $self;
}


sub url      { return $_[0]->{url} }
sub username { return $_[0]->{username} }
sub password { return $_[0]->{password} }

sub _parse_response_to_json {
    my($self, $code, $response) = @_;

    $self->_log( 3, "Raw response: ", $response );

    my $json_result = eval { $self->_json->decode($response); };

    if (my $error = $@) {
        my %exception = (
            type      => $self->{type},
            url       => $self->url,
            http_code => $code,
            eval_error => $error,
            response  => $response,
            message  => "Failed to read JSON in response from server ($response)",
        );

        croak( Opsview::RestAPI::Exception->new(%exception) );
    }

    $self->_log( 2, "result: ", pp($json_result) );

    return $json_result;
}

sub _query {
    my ( $self, %args ) = @_;
    croak "Unknown type '$args{type}'"
        if ( $args{type} !~ m/^(GET|POST|PUT|DELETE)$/ );

    croak( Opsview::RestAPI::Exception->new( message => "Not logged in" ) )
        unless ( $self->{token}
        || !defined( $args{api} )
        || !$args{api}
        || $args{api} =~ m/login/ );

    $self->{type} = $args{type};
    $args{api} =~ s!^/rest/!!;    # tidy any 'ref' URL we may have been given
    my $url = "/rest/" . ( $args{api} || '' );

    my @param_list;

    for my $param ( keys( %{ $args{params} } ) ) {
        if ( ! ref($args{params}{$param}) ) {
            push(@param_list, $param . '=' . uri_encode( $args{params}{$param} ) );
        } elsif (ref($args{params}{$param}) eq "ARRAY" ) {
            for my $arg ( @{ $args{params}{$param} }) {
                push(@param_list, $param . '=' . uri_encode( $arg ) );
            }
        } else {
            croak( Opsview::RestAPI::Exception->new( message => "Parameter '$param' is not an accepted type: " . ref( $args{params}{$param} ) ) );
        }
    }

    my $params = join( '&', @param_list);

    $url .= '?' . $params;
    my $data = $args{data} ? $self->_json->encode( $args{data} ) : undef;

    $self->_log( 2, "TYPE: $self->{type} URL: $url DATA: ",
        pp($data) );

    my $type = $self->{type};

    my $deadlock_attempts = 0;
    DEADLOCK: {
        $self->_client->$type( $url, $data );

        if ( $self->_client->responseCode ne 200 ) {
            $self->_log( 2, "Non-200 response - checking for deadlock" );
            if (   $self->_client->responseContent =~ m/deadlock/i
                && $deadlock_attempts < 5 )
            {
                $deadlock_attempts++;
                $self->_log( 1,  "Encountered deadlock: ",
                    $self->_client->responseContent());
                $self->_log( 1,  "Retrying (count: $deadlock_attempts)");
                sleep 1;
                redo DEADLOCK;
            }
        }
    }

    return $self->_parse_response_to_json( $self->_client->responseCode, $self->_client->responseContent() )
}


sub login {
    my ($self) = @_;

    # make sure we are communicating with at least Opsview v4.0
    my $api_version = $self->api_version;
    if ( $api_version->{api_version} < 4.0 ) {
        croak(
            Opsview::RestPI::Exception->new(
                message => $self->{url}
                    . " is running Opsview version "
                    . $api_version->{api_version}
                    . ".  Need at least version 4.0",
                http_code => 505,
            )
        );
    }

    $self->_log( 2, "About to login" );

    if ( $self->{token} ) {
        $self->_log( 1, "Already have token $self->{token}" );
        return $self;
    }

    my $result = eval {
        $self->post(
            api    => "login",
            params => {
                username => $self->{username},
                password => $self->{password},
            },
        );
    } or do {
        my $e = $@;
        $self->_log( 2, "Exception object:" );
        $self->_dump( 2, $e );
        die $e->message, $/;
    };

    $self->{token} = $result->{token};

    $self->_client->addHeader( 'X-Opsview-Username', $self->{username} );
    $self->_client->addHeader( 'X-Opsview-Token',    $result->{token} );

    $self->opsview_info();

    $self->_log( 1,
        "Successfully logged in to '$self->{url}' as '$self->{username}'" );

    return $self;
}


sub api_version {
    my ($self) = @_;
    if ( !$self->{api_version} ) {
        $self->_log( 2, "Fetching api_version information" );
        $self->{api_version} = $self->get( api => '' );
    }
    return $self->{api_version};
}


sub opsview_info {
    my ($self) = @_;
    if ( !$self->{opsview_info} ) {
        $self->_log( 2, "Fetching opsview_info information" );
        $self->{opsview_info} = $self->get( api => 'info' );
    }
    return $self->{opsview_info};
}


sub opsview_version {
    my ($self) = @_;

    return qv( $self->opsview_info->{opsview_version} );
}



sub opsview_build {
    my ($self) = @_;
    $self->opsview_info;
    return $self->{opsview_info}->{opsview_build};
}


sub interval {
    my ( $self, $interval ) = @_;

    # if this is a 4.6 system, adjust the interval to be minutes
    if ( $self->{api_version}->{api_version} < 5.0 ) {
        $interval = int( $interval / 60 );
        $interval += 1;
    }
    return $interval;
}


sub post {
    my ( $self, %args ) = @_;
    return $self->_query( %args, type => 'POST' );
}

sub get {
    my ( $self, %args ) = @_;

    if ( $args{batch_size} && $args{params}{rows} ) {
        croak(
            Opsview::RestAPI::Exception->new(
                message => "Cannot specify both 'batch_size' and 'rows'"
            )
        );
    }

    if ( $args{batch_size} ) {
        my @data;

        my %hash = (
            list    => \@data,
            summary => {
                allrows => 0,
                rows    => 0,
            }
        );

        # fetch just summary information for what we are after
        my %get_args = %args;
        $get_args{params}{rows} = 0;
        delete( $get_args{batch_size} );

        $self->_log( 1, "batch_size request: fetching summary data only" );
        my $summary = $self->_query( %get_args, type => 'GET' );

   # This is reassembled to make it look like everything was fetched in one go
        $hash{summary}{allrows} = $summary->{summary}->{allrows};
        $hash{summary}{rows}    = $summary->{summary}->{allrows};

        my $totalpages
            = int( $summary->{summary}->{allrows} / $args{batch_size} ) + 1;

        $self->_log( 2,
            "Fetching $hash{summary}{allrows} rows in batches of $args{batch_size}, $totalpages pages to fetch"
        );
        my $start_time = time();

        # now start fetching the data in batch_size increments
        my $page = 0;
        $get_args{params}{rows} = $args{batch_size};
        while ( $page++ < $totalpages ) {

            $get_args{params}{page} = $page;
            $self->_log( 3, "About to fetch page $page" );
            my $result = $self->_query( %get_args, type => 'GET' );

            push( @data, @{ $result->{list} } );
        }

        my $elapsed_time = time() - $start_time;
        $self->_log( 2, "Fetch completed in ${elapsed_time}s" );

        return \%hash;
    }
    return $self->_query( %args, type => 'GET' );
}

sub put {
    my ( $self, %args ) = @_;
    return $self->_query( %args, type => 'PUT' );
}

sub delete {
    my ( $self, %args ) = @_;
    return $self->_query( %args, type => 'DELETE' );
}


sub reload { return $_[0]->post( api => 'reload' ) }


sub reload_pending {
    my $result = $_[0]->get( api => 'reload' );
    if(! defined $result->{configuration_status}) {
        croak( Opsview::RestAPI::Exception->new(message => "'configuration_status' not found", result => $result ) );
    }
    return $result->{configuration_status} eq 'pending' ? 1 : 0;
}


# NOTE: use LWP::UserAgent directly to make use of its file upload functionality
# as REST::Client doesn't allow it to work as expected
sub file_upload {
    my ( $self, %args ) = @_;

    my $ua = $self->_client->getUseragent();
    $ua->default_header( 'Content-Type',       'application/json' );
    $ua->default_header( 'X-Opsview-Username', $self->{username} );
    $ua->default_header( 'X-Opsview-Token',    $self->{token} );

    my $url = $self->{url}."/rest/$args{api}";
    $url .= '/upload' unless $url =~ m!/upload$!;

    #warn "url=$url";

    my $response = $ua->post(
        $url,
        Accept       => "text/html",
        Content_Type => 'form-data',
        Content => [ filename => [ $args{local_file} => $args{remote_file} ] ]
    );

    return $self->_parse_response_to_json( $response->code, $response->content );
}


sub logout {
    my ($self) = @_;

    $self->_log( 2, "In logout" );

    return unless ( $self->{token} );
    $self->_log( 2, "found token, on to logout" );

    $self->post( api => 'logout' );
    $self->_log( 1, "Successfully logged out from $self->{url}" );

    # invalidate all the info held internally
    $self->{token}        = undef;
    $self->{api_version}  = undef;
    $self->{opsview_info} = undef;

    $self->_log( 2, "Token removed" );
    return $self;
}

# Copied from Opsview::Utils so that module does not need to be installed
#


sub remove_keys_from_hash {
    my ( $class, $hash, $allowed_keys, $do_not_die_on_non_hash ) = @_;

    if ( ref $hash ne "HASH" ) {

        # Double negative as default is to die
        unless ($do_not_die_on_non_hash) {
            die "Not a HASH: $hash";
        }
        return $hash;
    }

    # We cache the keys_list into
    if ( !defined $allowed_keys ) {
        die "Must specify $allowed_keys";
    }

    # OK
    elsif ( ref $allowed_keys eq "HASH" ) {

    }
    elsif ( ref $allowed_keys eq "ARRAY" ) {
        my @temp = @$allowed_keys;
        $allowed_keys = {};
        map { $allowed_keys->{$_} = 1 } @temp;
    }
    elsif ( ref $allowed_keys ) {
        $allowed_keys = { $allowed_keys => 1 };
    }
    else {
        die "allowed_keys incorrect";
    }

    foreach my $k ( keys %$hash ) {
        if ( exists $allowed_keys->{$k} ) {
            delete $hash->{$k};
        }
        elsif ( ref $hash->{$k} eq "ARRAY" ) {
            my @new_list;
            foreach my $item ( @{ $hash->{$k} } ) {
                push @new_list,
                    $class->remove_keys_from_hash( $item, $allowed_keys,
                    $do_not_die_on_non_hash );
            }
            $hash->{$k} = \@new_list;
        }
        elsif ( ref $hash->{$k} eq "HASH" ) {
            $hash->{$k}
                = $class->remove_keys_from_hash( $hash->{$k}, $allowed_keys,
                $do_not_die_on_non_hash );
        }
    }
    return $hash;
}

sub DESTROY {
    my ($self) = @_;
    $self->_log( 2, "In DESTROY" );
    $self->logout if ( $self->_client );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Opsview::RestAPI - Interact with the Opsview Rest API interface

=head1 VERSION

version 1.191660

=head1 SYNOPSIS

  use Opsview::RestAPI;

  my $rest=Opsview::RestAPI();
  # equivalent to
  my $rest=Opsview::RestAPI(
      url => 'http://localhost',
      username => 'admin',
      password => 'initial',
  );

  my %api_version=$rest->api_version;
  $rest->login;
  my %opsview_info=$rest->opsview_info;
  $rest->logout;

=head1 DESCRIPTION

Allow for easier access to the Opsview Monitor Rest API, version 4.x and newer.
See L<https://knowledge.opsview.com/reference> for more details.

=head1 BUILDING AND INSTALLING

This is a Perl module distribution. It should be installed with whichever
tool you use to manage your installation of Perl, e.g. any of

  cpanm .
  cpan  .
  cpanp -i .

Consult http://www.cpan.org/modules/INSTALL.html for further instruction.

Should you wish to install this module manually, the procedure is

  perl Makefile.PL
  make
  make test
  make install

You can amend where the module will be installed using

  perl Makefile.PL LIB=/path/to/perl/lib INSTALLSITEMAN3DIR=/path/to/perl/man/man3

=head1 EXAMPLES

Please see the files within the C<examples> and C<t/> test directory.

=head1 METHODS

=over 4

=item $rest = Opsview::RestAPI->new();

Create an object using default values for 'url', 'username' and 'password'.
Extra options are:

  ssl_verify_hostname => 1
  debug => 0

=item $url = $rest->url;

=item $username = $rest->username;

=item $password = $rest->password;

Return the settings the object was configured with

=item $rest->login

Authenticate with the Opsvsiew server using the credentials given in C<new()>.
This must be done before any other calls (except C<api_version>) are performed.

=item $api_version = $rest->api_version

Return a hash reference with details about the Rest API version in
the Opsview Monitor instance.  May be called without being logged in.

Example hashref:

  {
    api_min_version => "2.0",
    api_version     => 5.005005,
    easyxdm_version => "2.4.19",
  },

=item $version = $rest->opsview_info

Return a hash reference contianing some details about the Opsview
Monitor instance.

Example hashref:

  {
    hosts_limit            => "25",
    opsview_build          => "5.4.0.171741442",
    opsview_edition        => "commercial",
    opsview_version        => "5.4.0",
    server_timezone        => "Europe/London",
    server_timezone_offset => 0,
    uuid                   => "ABCDEF12-ABCD-ABCD-ABCD-ABCDEFABCDEF",
  }

=item $version = $rest->opsview_version

Return a Version Object for the version of Opsview.  Implicitly calls
C<opsview_info> if required.  See L<version> for more details

=item $build = $rest->opsview_build

Return the build number of the Opsview Monitor instance

=item $interval = $rest->interval($seconds);

Return the interval to use when setting check_interval or retry_interval.
Opsview 4.x used seconds whereas Opsview 5.x uses minutes.

  ....
  check_interval         => $rest->interval(300),
  ....

will set an interval time of 5 minutes (300 seconds) in both 4.xand 5.x

  ....
  retry_check_interval   => $rest->interval(20),
  ....

On Opsview 5.x this will set an interval time of 20 seconds
On Opsview 4.x this will set an interval time of 1 minute

=item $result = $rest->get( api => ..., data => { ... }, params => { ... } );

=item $result = $rest->post( api => ..., data => { ... }, params => { ... } );

=item $result = $rest->put( api => ..., data => { ... }, params => { ... } );

=item $result = $rest->delete( api => ..., data => { ... }, params => { ... } );

Method call on the Rest API to interact with Opsview.  See the online
documentation at L<https://knowledge.opsview.com/reference> for more
information.

The endpoint, data and parameters are all specified as a hash passed to the
method.  See L<examples/perldoc_examples> to see them in use.

To create a Host Template called 'AAA', for example:

  $rest->put(
    api  => 'config/servicegroup',
    data => { name => 'AAA' },
  );

To check if a plugin exists

  $result = $rest->get(
    api    => 'config/plugin/exists',
    params => { name => 'check_plugin_name', }
  );
  if ( $result->{exists} == 1 ) { .... }

To create a user:

  $rest->put(
    api  => 'config/contact',
    data => {
    name        => 'userid',
    fullname    => 'User Name',
    password    => $some_secure_password,
    role        => { name => 'View all, change none', },
    enable_tips => 0,
    variables =>
      [ { name => "EMAIL", value => 'email@example.com' }, ],
    },
  );

To search for a host called 'MyHost0' and print specific details.  Note, some
API endpoints will always return an array, no matter how many objects are
returned:

  $hosts = $rest->get(
    api => 'config/host',
    params => {
      'json_filter' => '{"name":"MyHost0"}',
    }
  );
  $myhost = $hosts->list->[0];
  print "Opsview Host ID: ", $myhost->{id}, $/;
  print "Hostgroup: ", $myhost->{hostgroup}->{name}, $/;
  print "IP Address: ", $myhost->{ip}, $/;

You can also search for a name like this:

  $hosts = $rest->get(
    api => 'config/host',
    params => {
        s.name => 'MyHost0',
    },
  );

To search for 'name1 OR name2' use:

  $hosts = $rest->get(
    api => 'config/host',
    params => {
        s.name => [ 'name1', 'name2' ],
    },
  );

For some objects it may be useful to print out the returned data structure
so you can see what can be modified. Using the ID of the above host:

  use Data::Dump qw( pp );
  $hosts = $rest->get(
    api => 'config/host/2'
  );
  $myhost = $hosts->list->[0];
  print pp($host); # prints the data structure to STDOUT

The data can then be modified and sent back using 'put' (put updates,
post creates):

  $myhost->{ip} = '127.10.10.10';
  $result = $rest->put(
    api => 'config/host/2',
    data => { %$myhost },
  );
  print pp($result); # contains full updated host info from Opsview

Be aware that fetching or sending too much data in one go may cause a timeout
via the proxy server used with Opsview (Apache2 by default) so processing the
data in batches in the client may be required.

C<get> (only) will handle this batching of data for you if you use the option
C<batch_size => <size>> (all other methods ignore this).

  $hosts = $rest->get(
    api => 'config/host/2'
    batch_size => 50,
  );

The data returned should appear the same as if the following were used:

  $hosts = $rest->get(
    api => 'config/host/2'
    params => { rows => 'all' },
  );

You canot specify both the 'rows' param and 'batch_size'.  All other parameters
should be accepted.

=item $result = $rests->reload();

Make a request to initiate a synchronous reload.  An alias to

  $rest->post( api => 'reload' );

=item $result = $rest->reload_pending();

Check to see if there are any pending configuration changes that require
a reload to be performed

=item $result = $rest->file_upload( api => ..., local_file => ..., remote_file => ... );

Upload the given file to the server.  For a plugin:

    $result = $rest->file_upload(
        api => 'config/plugin/upload',
        local_file => "$Bin/check_random",
        remote_file => "check_random",
    );

NOTE: This will only upload the plugin; it will not import it.  Use the following:

    $result = $rest->post(
        api => "config/plugin/import",
        params => {
            filename => 'check_random',
            overwrite  => 1
        },
    );

=item $result = $rest->logout();

Delete the login session held by Opsview Monitor and invalidate the
internally stored data structures.

=item $rest->remove_keys_from_hash($hashref, $arrayref);

=back

=head1 AUTHOR

Duncan Ferguson <duncan_j_ferguson@yahoo.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Duncan Ferguson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
