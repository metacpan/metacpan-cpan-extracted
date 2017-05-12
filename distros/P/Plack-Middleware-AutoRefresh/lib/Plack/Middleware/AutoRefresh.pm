package Plack::Middleware::AutoRefresh;

# ABSTRACT: Reload pages in browsers when files are modified

use strict;
use warnings;
use parent qw( Plack::Middleware );

our $VERSION = '0.09';

use Plack::Util;
use Plack::Util::Accessor qw( dirs filter wait );

use AnyEvent;
use AnyEvent::Filesys::Notify;
use JSON::Any;
use File::Slurp;
use File::ShareDir qw(dist_file);
use File::Basename;
use Carp;
use Readonly;

Readonly my $URL    => '/_plackAutoRefresh';
Readonly my $JS     => 'js/plackAutoRefresh.min.js';
Readonly my $JS_DEV => 'js/plackAutoRefresh.js';

sub prepare_app {
    my $self = shift;

    # Setup config params: filter, wait, dirs

    $self->{filter} ||= sub { $_[0] !~ qr/\.(swp|bak)$/ };
    $self->{filter} = sub { $_[0] !~ $self->filter }
      if ref( $self->filter ) eq 'Regexp';
    croak "AutoRefresh: filter must be a regex or code ref"
      unless ref( $self->filter ) eq 'CODE';

    $self->{wait} ||= 5;

    $self->{dirs} ||= ['.'];
    -d $_ or carp "AutoRefresh: can't find directory $_" for @{ $self->dirs };

    # Create the filesystem watcher
    $self->{watcher} = AnyEvent::Filesys::Notify->new(
        dirs     => $self->dirs,
        interval => 0.5,
        cb       => sub {
            my @events = grep { $self->filter->( $_->path ) } @_;
            return unless @events;

            warn "detected change: ", substr( $_->path, -60 ), "\n" for @events;
            $self->_change_handler(@events);
        },
    );

    # Setup an hash to hold the condition vars, record the load time as
    # the last change to deal with restarts, and get the raw js script
    $self->{condvars}    = {};
    $self->{last_change} = time;
    $self->{_script}     = $self->_get_script;

    return;
}

sub call {
    my ( $self, $env ) = @_;

    carp "AutoRefresh middleware doesn't work if psgi.nonblocking is false.\n",
      "Servers that are known to work: AnyEvent and Coro\n"
      unless $env->{'psgi.nonblocking'};

    # Client is looking for changed files
    if ( $env->{PATH_INFO} =~ m{^/_plackAutoRefresh(?:/(\d+)/(\d+))?} ) {
        my ( $uid, $timestamp ) = ( $1, $2 );

        # If a change has already happened return immediately,
        # otherwise make the browser block while we wait for change events
        if ( defined $timestamp && $timestamp < $self->{last_change} ) {
            return $self->_respond( { changed => $self->{last_change} } );
        } else {

            # Unblock any connections with the same uid.
            # This should close the tcp session to avoid using up
            # all the tcp ports. RT#56119
            if ( my $old_connection = $self->{condvars}->{$uid} ) {
                # The connection has already been dropped by the
                # client, so it doesn't matter what we return.
                $old_connection->send( [ 500, [], [] ] );
            }

            # Add this connection to the list
            my $cv = AE::cv;
            $self->{condvars}->{$uid} = $cv;

            # Finish up
            return sub {
                my $respond = shift;
                $cv->cb( sub { $respond->( $_[0]->recv ) } );
            };
        }
    }

    # Client wants something from the real app.
    # Insert our script if it is an html file
    my $response = $self->app->($env);
    return $self->response_cb(
        $response,
        sub {
            my $res = shift;
            my $ct = Plack::Util::header_get( $res->[1], 'Content-Type' );

            if ( $ct =~ m!^(?:text/html|application/xhtml\+xml)! ) {
                return sub {
                    my $chunk = shift;
                    return unless defined $chunk;
                    $chunk =~ s{<head>}{'<head>' . $self->_insert}ei;
                    $chunk;
                  }
            }
        } );
}

# Return the js script updating the time and adding config params
sub _insert {
    my ($self) = @_;

    my %var = (
        wait => $self->wait * 1000,
        url  => $URL,
        uid  => $self->_uid,
        now  => time,
    );

    ( my $script = $self->{_script} ) =~ s/\{\{([^}]*)}}/$var{$1}/eg;
    return $script;
}

sub _uid {
    my $self = shift;
    return ++$self->{_uid};
}

# AFN saw a change, respond to each blocked client
sub _change_handler {
    my $self = shift;

    my $now = $self->{last_change} = time;
    for my $uid ( keys %{ $self->{condvars} } ) {
        my $condvar = delete $self->{condvars}->{$uid};
        $condvar->send( $self->_respond( { changed => $now } ) );
    }

    return 1;
}

# Generate the plack response and encode any arguments as json
sub _respond {
    my ( $self, $resp ) = @_;
    ## TODO: check that resp is a hash ref

    return [
        200,
        [ 'Content-Type' => 'application/json' ],
        [ JSON::Any->new->encode($resp) ] ];
}

# Return the js script from ShareDir unless we are developing/testing PMA.
# This is a bit hack-ish
sub _get_script {
    my $self = shift;

    my $script =
      File::Spec->catfile( dirname( $INC{'Plack/Middleware/AutoRefresh.pm'} ),
        qw( .. .. .. share ), $JS_DEV );

    $script = dist_file( 'Plack-Middleware-AutoRefresh', $JS )
      unless -r $script;

    return '<script>' . read_file($script) . '</script>';
}

1;

__END__

=pod

=head1 NAME

Plack::Middleware::AutoRefresh - Reload pages in browsers when files are modified

=head1 VERSION

version 0.09

=head1 STATUS

=for html <a href="https://travis-ci.org/mvgrimes/Plack-Middleware-AutoRefresh"><img src="https://travis-ci.org/mvgrimes/Plack-Middleware-AutoRefresh.svg?branch=master" alt="Build Status"></a>
<a href="https://metacpan.org/pod/Plack::Middleware::AutoRefresh"><img alt="CPAN version" src="https://badge.fury.io/pl/Plack-Middleware-AutoRefresh.svg" /></a>

=head1 SYNOPSIS

    # in app.psgi
    use Plack::Builder;

    builder {
        enable 'Plack::Middleware::AutoRefresh',
               dirs => [ qw/html/ ], filter => qr/\.(swp|bak)/;
        $app;
    }

=head1 DESCRIPTION

Plack::Middleware::AutoRefresh is a middleware component that will
reload you web pages in your browser when changes are detected in the
source files. It should work with any modern browser that supports
JavaScript and multiple browsers simultaneously.

At this time, this middleware will only work with backend servers that
set psgi.nonblocking to true. Servers that are known to work include
L<Plack::Server::AnyEvent> and L<Plack::Server::Coro>.  You can force
a server with the C<-s> or C<--server> flag to C<plackup>.

=head1 CONFIGURATION

    dirs => [ '.' ]                     # default
    dirs => [ qw/root share html/ ]

Specifies the directories to watch for changes. Will watch all files 
and subdirectories of the specified directories for file modifications,
new files, deleted files, new directories and deleted directories.

    filter => qr/\.(swp|bak)$/           # default
    filter => qr/\.(svn|git)$/
    filter => sub { shift =~ /\.html$/ }

Will apply the specified filter to the changed path name. This can be
a regular expression or a code ref. Any paths that match the regular
expression will be ignored. A code ref will be passed the path as the
only argument. Any false return values will be filtered out.

    wait => 5                           # default 

Wait indicated the maximum number of seconds that the client should
block for while waiting for notifications of changes. Setting this to
a lower value will I<not> improve response times. 

=head1 ACKNOWLEDGMENTS

This component was inspired by NodeJuice (L<http://nodeJuice.com/>).
NodeJuice provides very similar browser refresh functionality by
running a standalone proxy between your client and the web
application. It is a bit more robust than
Plack::Middleware::AutoRefresh as it can handle critical errors in
your app (ie, compile errors).  Plack::Middleware::AutoRefresh is
simpler to setup and is limited to L<Plack> based applications. Some
of the original JavaScript was taken from nodeJuice project as well,
although it was mostly rewritten prior to release. Thank you to
Stephen Blum the author of nodeJuice.

A huge thank you to the man behind L<Plack>, Tatsuhiko Miyagawa, who
help me brainstorm the implementation, explained the inners of the
Plack servers, and re-wrote my broken code. 

=head1 IMPLEMENTATION

Plack::Middleware::AutoRefresh accomplishes the browser refresh by
inserting a bit (1.2K to be precise) of JavaScript into the (x)html
pages your Plack application on the fly. The JavaScript tries to have
minimal impact: only one anonymous function and one global flag
(window['-plackAutoRefresh-']) are added. The JavaScript will open an
Ajax connection back to your Plack server which will block waiting to
be notified of changes. When a change notification arrives, the
JavaScript will trigger a page reload.

=head1 SEE ALSO

NodeJuice at L<http://www.nodejuice.com/>.

Modules used to implement this module L<AnyEvent::Filesys::Notify>. 

And of course, L<Plack>.

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 SOURCE

Source repository is at L<https://github.com/mvgrimes/Plack-Middleware-AutoRefresh>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<http://github.com/mvgrimes/Plack-Middleware-AutoRefresh/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
