package POE::Component::CPAN::SQLite::Info;

use strict;
use warnings;

our $VERSION = '0.11';

use LWP::UserAgent;
use File::Spec;
use CPAN::SQLite::Info;
use POE (qw( Wheel::Run  Filter::Reference  Filter::Line));
use Carp;

sub spawn {
    my $package = shift;
    
    croak "Even number of arguments must be passed to $package"
        if @_ & 1;

    my %params = @_;
    
    $params{ lc $_ } = delete $params{ $_ } for keys %params;

    delete $params{options}
        unless ref $params{options} eq 'HASH';

    unless ( exists $params{path} ) {
        $params{path} = 'cpan_sqlite_info/';
        warn "Warning: No `path` parameter was specified\n"
            if $params{debug};
    }
    
    unless ( exists $params{mirror} ) {
        $params{mirror} = 'http://cpan.perl.org';
    }

    my $self = bless \%params, $package;

    $self->{session_id} = POE::Session->create(
        object_states => [
            $self => {
                freshen    => '_freshen',
                fetch_info => '_fetch_info',
                shutdown   => '_shutdown',
            },
            $self => [
                qw(
                    _child_error
                    _child_close
                    _child_stderr
                    _child_stdout
                    _sig_chld
                    _start
                )
            ],
        ],
        ( exists $params{options} ? ( options => $params{options} ) : () ),
    )->ID;
    
    return $self;
}

sub _start {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    $self->{session_id} = $_[SESSION]->ID();
    
    if  ( $self->{alias} ) {
        $kernel->alias_set( $self->{alias} );
    }
    else {
        $kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
    }
    
    $self->{wheel} = POE::Wheel::Run->new(
        Program => \&_wheel,
        ErrorEvent => '_child_error',
        CloseEvent => '_child_close',
        StderrEvent => '_child_stderr',
        StdoutEvent => '_child_stdout',
        StdioFilter => POE::Filter::Reference->new,
        StderrFilter => POE::Filter::Line->new,
        ( $^O eq 'MSWin32' ? ( CloseOnCall => 0 ) : ( CloseOnCall => 1 ) ),
    );
    
    $kernel->call('shutdown')
        unless $self->{wheel};
    
    $kernel->sig_child( $self->{wheel}->PID, '_sig_chld' );
}

sub _sig_chld {
    $poe_kernel->sig_handled;
}

sub _child_close {
    my ( $kernel, $self, $wheel_id ) = @_[ KERNEL, OBJECT, ARG0 ];

    warn "_child_close called (@_[ARG0..$#_])\n"
        if $self->{debug};

    delete $self->{wheel};
    $kernel->yield('shutdown')
        unless $self->{shutdown};

    undef;
}

sub _child_error {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    warn "_child_error called (@_[ARG0..$#_])\n"
        if $self->{debug};

    delete $self->{wheel};
    $kernel->yield('shutdown')
        unless $self->{shutdown};

    undef;
}

sub _child_stderr {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    warn "_child_stderr: $_[ARG0]\n"
        if $self->{debug};

    undef;
}

sub _child_stdout {
    my ( $kernel, $self, $input ) = @_[ KERNEL, OBJECT, ARG0 ];
    
    my $session = delete $input->{sender};
    my $event   = delete $input->{event};

    $kernel->post( $session, $event, $input );
    $kernel->refcount_decrement( $session => __PACKAGE__ );

    undef;
}

sub shutdown {
    my $self = shift;
    $poe_kernel->post( $self->{session_id} => 'shutdown' );
}

sub _shutdown {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    $kernel->alarm_remove_all;
    $kernel->alias_remove( $_ ) for $kernel->alias_list;
    $kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ )
        unless $self->{alias};

    $self->{shutdown} = 1;
    $self->{wheel}->shutdown_stdin
        if $self->{wheel};
}

sub session_id {
    return $_[0]->{session_id};
}

sub freshen {
    my $self = shift;
    $poe_kernel->post( $self->{session_id} => 'freshen' => @_ );
}

sub fetch_info {
    my $self = shift;
    $poe_kernel->post( $self->{session_id} => 'fetch_info' => @_ );
}

sub _fetch_info {
    my ( $kernel, $self, $args )= @_[ KERNEL, OBJECT, ARG0 ];

    my $sender = $_[SENDER]->ID;

    return
        if $self->{shutdown};

    $args->{ lc $_ } = delete $args->{ $_ }
        for grep { !/^_/ } keys %{ $args };

    
    if ( $args->{session} ) {
        if ( my $ref = $kernel->alias_resolve( $args->{session} ) ) {
            $args->{sender} = $ref->ID;
        }
        else {
            warn "Could not resolve `session` parameter to a "
                    . "valid POE session. Aborting...";
            return;
        }
    }
    else {
        $args->{sender} = $sender;
    }
    
    unless ( exists $args->{path} ) {
        $args->{path} = $self->{path};
    }

    delete $args->{freshen}; # to make sure wheel doesn't freshen by mistake
    $kernel->refcount_increment( $args->{sender} => __PACKAGE__ );
    $self->{wheel}->put( $args );

    undef;
}


# yes, yes, the almost identical sub{} to the above one....
# fighting POE's "magik" in here is beyond me...
# .. note to self: figure out wtf is going on.

sub _freshen {
    my ( $kernel, $self, $args )= @_[ KERNEL, OBJECT, ARG0 ];

    my $sender = $_[SENDER]->ID;

    return
        if $self->{shutdown};

    $args->{ lc $_ } = delete $args->{ $_ }
        for grep { !/^_/ } keys %{ $args };

    
    if ( $args->{session} ) {
        if ( my $ref = $kernel->alias_resolve( $args->{session} ) ) {
            $args->{sender} = $ref->ID;
        }
        else {
            warn "Could not resolve `session` parameter to a "
                    . "valid POE session. Aborting...";
            return;
        }
    }
    else {
        $args->{sender} = $sender;
    }
    
    unless ( exists $args->{path} ) {
        $args->{path} = $self->{path};
    }
    
    unless ( exists $args->{mirror} ) {
        $args->{mirror} = $self->{mirror};
    }

    unless ( exists $args->{ua_args}{timeout} ) {
        $args->{ua_args}{timeout} = 30;
    }

    $args->{freshen} = 1; # for the wheel to know what to do.
    $kernel->refcount_increment( $args->{sender} => __PACKAGE__ );
    $self->{wheel}->put( $args );

    undef;
}

sub _wheel {
    if ( $^O eq 'MSWin32' ) {
        binmode STDIN;
        binmode STDOUT;
    }
    
    my $raw;
    my $size = 4096;
    my $filter = POE::Filter::Reference->new;

    while ( sysread STDIN, $raw, $size ) {
        my $requests = $filter->get( [ $raw ] );
        foreach my $req_ref ( @$requests ) {

            if ( exists $req_ref->{freshen} ) {
                eval { _fetch_data_files( $req_ref ); };
                $req_ref->{freshen_error} = $@
                    if $@;
            }
            else {
                _populate_info( $req_ref );
            }

            my $response = $filter->put( [ $req_ref ] );
            print STDOUT @$response;
        }
    }
}

sub _populate_info {
    my $req_ref = shift;

    my $info = CPAN::SQLite::Info->new( CPAN => $req_ref->{path} );
    
    # stupid ->fetch_info prints crap to STDOUT effectively
    # breaking Wheel ~_~
    {
        local *STDOUT;
        open STDOUT, '>', File::Spec->devnull;
        $info->fetch_info;
    }

    @$req_ref{ qw( dists mods auths ) }
    =  @$info{ qw( dists mods auths ) };

    undef;
}

sub _fetch_data_files {
    my $req_ref = shift;
    
    my $path     = $req_ref->{path};
    my $mod_dir  = File::Spec->catdir( $path, 'modules/' );
    my $auth_dir = File::Spec->catdir( $path, 'authors/' );

    foreach my $dir ( $path, $mod_dir, $auth_dir ) {
        unless ( -e $dir ) {
            mkdir $dir
                or die "Failed to create directory `$dir` ($!)\n";
        }
    }

    my $ua = LWP::UserAgent->new( %{ $req_ref->{ua_args} || {} } );

    my $mirror = $req_ref->{mirror};
    
    @{ $req_ref->{uris} }{ qw(modlist packages authors) } = (
        URI->new( $mirror ),
        URI->new( $mirror ),
        URI->new( $mirror ),
    );
    
    my $uris_ref = $req_ref->{uris};
    $uris_ref->{modlist }->path('/modules/03modlist.data.gz');
    $uris_ref->{packages}->path('/modules/02packages.details.txt.gz');
    $uris_ref->{authors }->path('/authors/01mailrc.txt.gz');

    $req_ref->{files}{ modlist  } = File::Spec->catfile(
        $mod_dir,
        '03modlist.data.gz',
    );
    $req_ref->{files}{ packages } = File::Spec->catfile(
        $mod_dir,
        '02packages.details.txt.gz',
    );
    $req_ref->{files}{ authors  } = File::Spec->catfile(
        $auth_dir,
        '01mailrc.txt.gz',
    );
    
    keys %{ $req_ref->{uris} };
    while ( my ( $name, $uri ) = each %{ $req_ref->{uris} } ) {

        $req_ref->{requests}{ $name } = $ua->mirror(
            $uri,
            $req_ref->{files}{ $name },
        );

        my $requests_ref = $req_ref->{requests};
        # check for fetch errors, but do not consider 304 an error,
        # we are fine with that since it indicates that file is good
        # enough for that we need it.
        if (
                !$requests_ref->{ $name }->is_success
            and $requests_ref->{ $name }->status_line ne '304 Not Modified'
        ) {
            $req_ref->{freshen_errors}{ $name }
            = $req_ref->{requests}{ $name }->status_line;

            $req_ref->{freshen_error} = 'fetch';
        }
    }

    undef;
}

1;

__END__

=encoding utf8

=head1 NAME

POE::Component::CPAN::SQLite::Info - non-blocking wrapper around L<CPAN::SQLite::Info> with file fetching abilities.

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::CPAN::SQLite::Info);
    
    my $poco = POE::Component::CPAN::SQLite::Info->spawn;
    
    POE::Session->create(
        package_states => [
            main => [
                qw(
                    _start
                    fetched
                    info
                ),
            ],
        ],
    );
    
    $poe_kernel->run;
    
    sub _start {
        $poco->freshen( {
                mirror => 'http://cpan.org/',
                event  => 'fetched',
            }
        );
    }
    
    sub fetched {
        my ( $kernel, $input ) = @_[ KERNEL, ARG0 ];
        
        # whoops. Something whent wrong. Print the error(s)
        # and kill the component
        if ( $input->{freshen_error} ) {
            
            # if {freshen_error} says 'fetch' we got an error
            # on the network side.
            # otherwise, it's something with creating dirs for our files.
            if ( $input->{freshen_error} eq 'fetch' ) {
                # since we are fetching 3 files, we gonna have 1-3 errors here.
                print "Could not fetch file(s)\n";
                foreach my $file ( keys %{ $input->{freshen_errors} } ) {
                    print "\t$file  => $input->{freshen_errors}{ $file }\n";
                }
            }
            else {
                print "Failed to create storage dir: $input->{freshen_error}\n";
            }
        }
        else {
            # we got our files, let's parse them now.
            $poco->fetch_info( { event => 'info' } );
        }
    }
    
    sub info {
        my ( $kernel, $results ) = @_[ KERNEL, ARG0 ];
        
        # $results got plenty of juicy data. Let's pick something and dump it
        use Data::Dumper;
        print Dumper ( $results->{mods}{'WWW::Search::Mininova'} );
        
        # shut the PoCo down
        $poco->shutdown;
    }

Using event based interface is also possible, of course.

=head1 CONSTRUCTOR

    my $poco = POE::Component::CPAN::SQLite::Info->spawn;
    
    POE::Component::CPAN::SQLite::Info->spawn( alias => 'info' );
    
    POE::Component::CPAN::SQLite::Info->spawn(
        alias  => 'info2',
        path   => '/tmp',
        mirror =>
        debug  => 1,
    );

Returns a PoCo object. Takes five I<optional> arguments:

=head2 alias

    POE::Component::CPAN::SQLite::Info->spawn( alias => 'tube' );

Specifies a POE Kernel alias for the component.

=head2 mirror

    POE::Component::CPAN::SQLite::Info->spawn( mirror => 'http://cpan.org' );

The component can prefetch the needed files for L<CPAN::SQLite::Info>.
The C<mirror> argument specifies what CPAN mirror to get those files
from. Defaults to: C<http://cpan.perl.org>

=head2 path

    POE::Component::CPAN::SQLite::Info->spawn( path => '/tmp' );

When component fetches the files needed for L<CPAN::SQLite::Info> it 
will mirror them locally. By specifying the C<path> argument you can
tell the component where to store those. The component will create
two directories inside the one you've specified, namely 'authors' and
'modules'. This argument defaults to C<'cpan_sqlite_info'> directory
inside the current directory.

=head2 options

    POE::Component::CPAN::SQLite::Info->spawn(
        options => {
            trace => 1,
            default => 1,
        },
    );

A hashref of POE Session options to pass to the component's session.

=head2 debug

    POE::Component::CPAN::SQLite::Info->spawn( debug => 1 );

When set to a true value turns on output of debug messages.

=head1 METHODS

These are the object-oriented methods of the component.

=head2 freshen

    $poco->freshen( { event => 'now_files_are_fresh_event' } );
    
    $poco->freshen( {
            event   => 'event_for_results',
            path    => '/tmp',
            mirror  => 'http://cpan.org',
            session => 'some_other_session',
            _user   => 'test',
            _foos   => 'bars',
        }
    );

Takes one argument which is a hashref. See C<freshen> event for details.

=head2 fetch_info

    $poco->fetch_info( { event => 'event_for_results' } );
    
    $poco->fetch_info( {
            event   => 'event_for_results',
            session => 'some_other_session',
            path    => '/tmp',
            _user   => 'lal',
            _moar   => 'more lal',
        }
    );

Takes one argument which is a hashref. See C<fetch_info> event for details.

=head2 session_id

    my $tube_id = $poco->session_id;

Takes no arguments. Returns POE Session ID of the component.

=head2 shutdown

    $poco->shutdown;

Takes no arguments. Shuts the component down.

=head1 ACCEPTED EVENTS

=head2 freshen

    $poe_kernel->post( info => freshen => { event => 'event_for_results' } );
    
    $poe_kernel->post( info => freshen => {
            event   => 'event_for_results',
            path    => '/tmp',
            mirror  => 'http://cpan.org',
            session => 'some_other_session',
            _user_defined => 'foos',
            ua_args => { timeout => 10 },
        }
    );

Instructs the component to fetch the files needed by L<CPAN::SQLite::Info>.
Takes one argument which is a hashref. The argument's keys may be as 
follows:

=head3 event

    { event   => 'event_for_results' }

B<Mandatory>. The name of the event to where to send the results.

=head3 mirror

    { mirror  => 'http://cpan.org' }

B<Optional>. The C<mirror> parameter will override the C<mirror> parameter
in the contructor. See CONSTRUCTOR section for details. Defaults to: 
C<mirror> argument of the constructor.

=head3 path

    { path    => '/tmp' }

B<Optional>. The C<path> parameter will override the C<path> parameter
in the constructor. See CONSTRUCTOR section for description. Note: don't
forget to set the same C<path> parameter for the C<fetch_info>, otherwise
it will cry. Defaults to: C<path> argument of the constructor.

=head3 session

    { session => 'other_session_alias' }

    { session => $other_session_ID }
    
    { session => $other_session_ref }

B<Optional>. Specifies an alternative POE Session to send the output to.
Accepts either session alias, session ID or session reference. Defaults
to the current session.

=head3 user defined arguments

    {
        _user_var    => 'foos',
        _another_one => 'bars',
        _some_other  => 'beers',
    }

B<Optional>. Any keys beginning with the C<_> (underscore) will be present
in the output intact. 

=head2 fetch_info

    $poe_kernel->post( info => fetch_info => { event => 'event_for_results' } );
    
    $poe_kernel->post( info => fetch_info => {
            event   => 'event_for_results', # mandatory
            path    => '/tmp',
            session => 'some_other_session', 
            _user   => 'lal',
            _moar   => 'more lal',
        }
    );

Instructs the component to parse the CPAN files and get the information
about dists, modules and authors. Takes one argument which is a hashref
with the following keys:

=head3 event

    { event   => 'event_for_results' }

B<Mandatory>. The name of the event to send the results to.

=head3 path

    { path    => '/tmp' }

B<Optional>. The C<path> parameter will override the C<path> parameter
in the constructor. See CONSTRUCTOR section for description. Note: don't
forget to set the same C<path> parameter for the C<freshen> unless
you have files in different locations, otherwise
the poco will cry. Defaults to: C<path> argument of the constructor.

=head3 session

    { session => 'other_session_alias' }

    { session => $other_session_ID }
    
    { session => $other_session_ref }

B<Optional>. Specifies an alternative POE Session to send the output to.
Accepts either session alias, session ID or session reference. Defaults
to the current session.

=head3 user defined arguments

    {
        _user_var    => 'foos',
        _another_one => 'bars',
        _some_other  => 'beers',
    }

B<Optional>. Any keys beginning with the C<_> (underscore) will be present
in the output intact.

=head3 ua_args

    {
        ua_args => {
            timeout => 10,
            agent   => 'CPAN Info',
        }
    }

Takes a hashref as a value. Here you can specify the arguments for
L<LWP::UserAgent> constructor. If you don't specify the C<timeout>
it will default to C<30> seconds. The rest of the options will default
to whatever L<LWP::UserAgent> C<new()> method wants.

=head1 OUTPUT

The output from the component is recieved via events for both the OO and
event based interface.

=head2 ouput from freshen

    $VAR1 = {
        'mirror' => 'http://cpan.perl.org/',
        'files' => {
            'packages' => 'cpan_sqlite_info/modules/02packages.details.txt.gz',
            'authors' => 'cpan_sqlite_info/authors/01mailrc.txt.gz',
            'modlist' => 'cpan_sqlite_info/modules/03modlist.data.gz'
        },
        'requests' => {
            'authors' => bless( { blah }, 'HTTP::Response' ),
            'packages' => bless( { blah }, 'HTTP::Response' ),
            'modlist' => bless( { blah }, 'HTTP::Response' )
        },
        'freshen' => 1,
        'path' => 'cpan_sqlite_info/',
        'uris' => {
            'packages' => bless( do{\(my $o = 'http://cpan.perl.org/modules/02packages.details.txt.gz')}, 'URI::http' ),
            'authors' => bless( do{\(my $o = 'http://cpan.perl.org/authors/01mailrc.txt.gz')}, 'URI::http' ),
            'modlist' => bless( do{\(my $o = 'http://cpan.perl.org/modules/03modlist.data.gz')}, 'URI::http' )
        },
        ua_args => {
            'timeout' => 30,
        },
    };

The event handler for the event specified in the C<event> argument of the
C<freshen> event/method will recieve the results in C<ARG0> in a form
of a hashref with the following keys:

=head3 mirror

    { 'mirror' => 'http://cpan.perl.org/' }

The C<mirror> key will contain the value of the C<mirror> argument that
you provided to C<freshen> event/method or component's constructor.

=head3 path

    { 'path' => 'cpan_sqlite_info/' }

The C<path> key will contain the value of the C<path> argument that
you provided to C<freshen> event/method or component's constructor.

=head3 freshen

    { 'freshen' => 1 }

The C<freshen> key will be present, you could use it to differentiate
between C<freshen> and C<fetch_info> results if you are getting results
with the same event handler.

=head3 files

    'files' => {
        'packages' => 'cpan_sqlite_info/modules/02packages.details.txt.gz',
        'authors' => 'cpan_sqlite_info/authors/01mailrc.txt.gz',
        'modlist' => 'cpan_sqlite_info/modules/03modlist.data.gz'
    },

The C<files> key will contain a hashref with the locations of three 
files used by L<CPAN::SQLite::Info>. Note: locations will include the
C<path> argument (see CONSTRUCTOR).

=head3 requests

    'requests' => {
        'authors' => bless( { blah }, 'HTTP::Response' ),
        'packages' => bless( { blah }, 'HTTP::Response' ),
        'modlist' => bless( { blah }, 'HTTP::Response' )
    },

The <requests> key will contain a hashref with 
L<HTTP::Response> objects from requests
sent to fetch each of the three files used by L<CPAN::SQLite::Info>. 
The names of the keys are the same as in C<files> key (see above).

=head3 uris

    'uris' => {
        'packages' => bless( do{\(my $o = 'http://cpan.perl.org/modules/02packages.details.txt.gz')}, 'URI::http' ),
        'authors' => bless( do{\(my $o = 'http://cpan.perl.org/authors/01mailrc.txt.gz')}, 'URI::http' ),
        'modlist' => bless( do{\(my $o = 'http://cpan.perl.org/modules/03modlist.data.gz')}, 'URI::http' )
    }

The C<uris> key will contain a hashref with L<URI> objects which represent
URIs used to fetch the three files used by L<CPAN::SQLite::Info>. The
names of the keys are the same as in C<files> and C<requests> keys
(see above).

=head3 freshen_error

    { freshen_error => 'fetch' }
    
    { freshen_error => 'Could not make directory /root (Permission Denied)' }

The C<freshen_error> key will exist only if an error occured. The value
may be of two I<types>. If the value contains word C<fetch>, it means
that an error occured during the download of the files and you should
inspect C<freshen_errors> (note the plural form, see description below). 
If the value does not contain word C<fetch> it means the error occured
during the creation of directories (including the C<path>, see CONSTRUCTOR
section). In this case, the error text will be the value of the
C<freshen_error> (note singular form) key.

=head3 freshen_errors

    {
        'freshen_error' => 'fetch',
        'freshen_errors' => {
            'authors' => '500 Can\'t connect to fake.fake:80 (Bad hostname \'fake.fake\')',
            'packages' => '500 Can\'t connect to fake.fake:80 (Bad hostname \'fake.fake\')',
            'modlist' => '500 Can\'t connect to fake.fake:80 (Bad hostname \'fake.fake\')'
        },
    }

When the C<freshen_error> (note singular form) key is set to C<fetch>
the C<freshen_errors> (note plural form) key will be present and will
contain a hashref with three keys, which are the same as C<files>, 
C<uris> and C<requests> keys (see above) and values of those keys will
contain the error messages for each of the three files we were trying to
fetch.

=head3 user defined arguments

    {
        _user_var    => 'foos',
        _another_one => 'bars',
        _some_other  => 'beers',
    }

Any keys beginning with the C<_> (underscore) which we passed to the 
C<freshen> event/method will be present
in the output intact.

=head3 ua_args

    ua_args => {
        'timeout' => 30,
    },

This key will contain whatever you've specified in the C<ua_args> hashref
passed to the C<freshen()> event/method. If you didn't specify anything,
it will contain one key C<timeout> with it's default, 30 second, value.

=head2 output from fetch_info

  $VAR1 = {
    'auths' => {
        'JAYBONCI' => {
            'email' => 'jay@bonci.com',
            'fullname' => 'Jay Bonci'
        },
        # lots and losts of these
    }
    'mods' => {
        'MyLibrary::DB' => {
            'dist_name' => 'MyLibrary',
            'mod_vers' => undef
        },
        # lots and losts of these
    },
    'dists' => {
        'Gtk2-Ex-VolumeButton' => {
            'dist_vers' => '0.07',
            'modules' => {
                'Gtk2::Ex::VolumeButton' => 1
                # could be more here
            },
            'cpanid' => 'FLORA',
            'dist_file' => 'Gtk2-Ex-VolumeButton-0.07.tar.gz'
        },
        # lots and losts of these
    },
    'path' => 'cpan_sqlite_info/',

The event handler set for the event you've provided to the C<fetch_info>
method/event will recieve the results in C<ARG0> in the form of a hashref
with the followin keys:

=head3 auths

    'auths' => {
        'JAYBONCI' => {
            'email' => 'jay@bonci.com',
            'fullname' => 'Jay Bonci'
        },
        # lots and losts of these
    }

The C<auths> key will contain a hashref keys of which will be CPAN
authors' IDs and values will be hashrefs with two keys:

=over 10

=item email

Contains author's email address

=item fullname

Contains author's full name

=back

=head3 mods

    'mods' => {
        'MyLibrary::DB' => {
            'dist_name' => 'MyLibrary',
            'mod_vers' => undef,
            # and perhaps more here
        },
        # lots and losts of these
    },

The C<mods> key will contain a hashref, keys of which will be module
names and values will be hashrefs with the following keys:

=over 10

=item dist_name

The distribution name containing the module

=item mod_vers

The version of the module

=item mod_abs

A description, if available

=item chapterid

The chapter ID of the module, if present

=item dslip

A 5 character string specifying the DSLIP
(development, support, language, interface, public licence) information.

=back

=head3 dists

    'dists' => {
        'Gtk2-Ex-VolumeButton' => {
            'dist_vers' => '0.07',
            'modules' => {
                'Gtk2::Ex::VolumeButton' => 1
                # could be more here
            },
            'cpanid' => 'FLORA',
            'dist_file' => 'Gtk2-Ex-VolumeButton-0.07.tar.gz'
        },
        # lots and losts of these
    },

The C<dists> key will contain a hashref, keys of which will be distribution
names and values will be hashrefs with the following keys

=over 11

=item dist_vers

The version of the CPAN file

=item dist_file

The CPAN filename

=item cpanid

The CPAN author id

=item dist_abs

A description, if available

=item modules

Will contain a hashref which specifies the modules present in
the distribution:

  for my $module ( keys %{ $results->{dists}{ $distname }{modules} } ) {
    print "Module: $module\n";
  }

=item chapterid

Specifies the chapterid and the subchapter for the distribution:

    my $dist_ref = $results->{dists}{ $distname };
    for my $id ( keys %{ $dist_ref->{chapterid} } ) {
        print "For chapterid $id\n";
        for my $sc ( keys %{ $dist_ref->{chapterid}{ $id } } ) {
            print "   Subchapter: $sc\n";
        }
    }

=back

=head3 path

    { 'path' => 'cpan_sqlite_info/' }

The C<path> key will contain the C<path> argument that you've passed
to the C<fetch_results> method/event or component's contructor.

=head3 user defined arguments

    {
        _user_var    => 'foos',
        _another_one => 'bars',
        _some_other  => 'beers',
    }

B<Optional>. Any keys beginning with the C<_> (underscore) will be present
in the output intact.

=head1 SEE ALSO

L<CPAN::SQLite::Info>, L<POE>, L<LWP::UserAgent>

=head1 PREREQUISITES

This module requires the following modules/versions

    LWP::UserAgent           => 2.036,
    File::Spec               => 3.2501,
    Carp                     => 1.04,
    POE                      => 0.9999,
    POE::Wheel::Run          => 1.2179,
    POE::Filter::Reference   => 1.2187,
    POE::Filter::Line        => 1.1920,
    CPAN::SQLite::Info       => 0.18

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
( L<http://zoffix.com>, L<http://haslayout.net> )

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-cpan-sqlite-info at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-CPAN-SQLite-Info>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::CPAN::SQLite::Info

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-CPAN-SQLite-Info>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-CPAN-SQLite-Info>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-CPAN-SQLite-Info>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-CPAN-SQLite-Info>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

