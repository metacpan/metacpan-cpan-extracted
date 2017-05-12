## no critic (RequireUseStrict)
package Plack::Middleware::Recorder;
$Plack::Middleware::Recorder::VERSION = '0.06';
## use critic (RequireUseStrict)
use strict;
use warnings;
use parent 'Plack::Middleware';

use Carp qw(croak);
use HTTP::Request;
use IO::File;
use IO::String;
use Sereal qw(encode_sereal);
use Fcntl qw(:flock);
use Scope::Guard;
use namespace::clean;

use Plack::Util::Accessor qw/active start_url stop_url/;

sub prepare_app {
    my ( $self ) = @_;

    $self->active(1)                    unless defined $self->active;
    $self->start_url('/recorder/start') unless defined $self->start_url;
    $self->stop_url('/recorder/stop')   unless defined $self->stop_url;

    my $output = delete $self->{'output'};
    croak "output parameter required" unless defined $output;

    if (ref $output) {
        $self->{'output_fh'} = $output;
        $output->autoflush(1);
    } else {
        unless(-w $output) {
            croak "$output is not writable";
        }
        $self->{'output_filename'} = $output;
    }
}

sub _output_fh {
    my ( $self, $env ) = @_;
    unless ($self->{'output_fh'}) {
        my $mode = $env->{'psgi.run_once'} ? 'a' : 'w';
        $self->{'output_fh'} = IO::File->new($self->{'output_filename'}, $mode);
        $self->{'output_fh'}->autoflush(1);
    }
    return $self->{'output_fh'};
}

sub env_to_http_request {
    my ( $self, $env ) = @_;

    my $request = HTTP::Request->new;
    $request->method($env->{'REQUEST_METHOD'});
    $request->uri($env->{'REQUEST_URI'});
    $request->header(Content_Length => $env->{'CONTENT_LENGTH'});
    $request->header(Content_Type   => $env->{'CONTENT_TYPE'});
    foreach my $header (grep { /^HTTP_/ } keys %$env) {
        my $value = $env->{$header};
        $header   =~ s/^HTTP_//;
        $header   = uc($header);
        $header   =~ s/\b([a-z])/uc $!/ge;

        $request->header($header, $value);
    }

    my $input  = $env->{'psgi.input'};
    my $body   = IO::String->new;
    my $buffer = '';
    while($input->read($buffer, 1024) > 0) {
        print $body $buffer;
    }

    $body->setpos(0);
    $env->{'psgi.input'} = $body;
    $request->content(${ $body->string_ref });

    return $request;
}

sub call {
    my ( $self, $env ) = @_;

    my $app       = $self->app;
    my $start_url = $self->start_url;
    my $stop_url  = $self->stop_url;
    my $path      = $env->{'PATH_INFO'};

    $env->{__PACKAGE__ . '.start_url'} = $start_url;
    $env->{__PACKAGE__ . '.stop_url'}  = $stop_url;

    if($path =~ m!\Q$start_url\E!) {
        $self->active(1);
        $env->{__PACKAGE__ . '.active'} = $self->active;
        return [
            200,
            ['Content-Type' => 'text/plain'],
            [ 'Request recording is ON' ],
        ];
    } elsif($path =~ m!\Q$stop_url\E!) {
        $self->active(0);
        $env->{__PACKAGE__ . '.active'} = $self->active;
        return [
            200,
            ['Content-Type' => 'text/plain'],
            [ 'Request recording is OFF' ],
        ];
    } elsif($self->active) {
        my $req    = $self->env_to_http_request($env);
        my $frozen = encode_sereal($req);

        my $fh = $self->_output_fh($env);
        # $guard looks unused, but it's unlocking the file upon its
        # destruction
        my $guard = $self->_create_concurrency_lock($fh, $env);
        if($guard) {
            $fh->write(pack('Na*', length($frozen), $frozen));
            $fh->flush;
        }
    }

    $env->{__PACKAGE__ . '.active'} = $self->active;

    return $app->($env);
}

sub _create_concurrency_lock {
    my ( $self, $fh, $env ) = @_;

    return 1 if !$env->{'psgi.multithread'} && !$env->{'psgi.multiprocess'};

    my $locked = eval { flock($fh, LOCK_EX) || die "$!\n" };

    if(!$locked) {
        if(my $log = $env->{'psgix.logger'}) {
            my $error = $@ || 'Unknown error';
            chomp $error;

            $log->({
                level   => 'warn',
                message => "Unable to lock filehandle in multiprocess environment ($error); skipping recording",
            });
        }
        return;
    }

    return Scope::Guard->new( sub { flock($fh, LOCK_UN) });
}

1;

# ABSTRACT: Plack middleware that records your client-server interactions

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Recorder - Plack middleware that records your client-server interactions

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
    enable 'Recorder',
        output    => 'requests.out',    # required
        active    => 1,                 # optional
        start_url => '/recorder/start', # optional
        stop_url  => '/recorder/stop';  # optional
    $app;
  };

=head1 DESCRIPTION

This middleware records the stream of requests and responses that your
application goes through to a file.  The middleware records all requests while
active; the active state can be altered via L</start_url> and L</stop_url">.

=head1 OPTIONS

=head2 output

Either a filename, a glob reference, or an IO::Handle where the serialized
requests will be written to.  To read these requests, use L<Plack::VCR>.

=head2 active

Whether or not to start recording once the application starts.  Defaults to 1.

=head2 start_url

A relative URL that will tell the recorder middleware to record subsequent
requests if requested.  Defaults to '/recorder/start'.

=head2 stop_url

A relative URL that will tell the recorder middleware to stop recording requests.
Defaults to '/recorder/stop'.

=head1 RATIONALE

This module was written to scratch a fairly specific itch of mine, but one I
encounter often.  I work on a lot of Javascript-heavy web applications for my
job, and I often have to fix bugs that only rear their ugly heads a dozen
clicks or so into the application.  Obviously, if the bug is in the
Javascript, there's not much I can do about it, but often the problem comes
from the output I receive from the server.  This middleware allows me to set
up debugging statements in the server and replay the requests the frontend
is submitting to get me on the right track.

=head1 FURTHER IMPROVEMENTS

The first release of this distribution was fairly simple; it only records and
retrieves requests.  In the future, I'd like a bunch of features to be added:

=over 4

=item *

Recording responses could be useful for generating test scripts and the like.

=item *

On that note, a script/convenience module for generating test scripts would be nice.

=item *

Currently, authorization works by just copying headers blindly.  This logic could be improved with application-specific hooks.

=item *

Request bodies are recorded directly in the output stream, and an in-memory representation is used for psgi.input.  This could be better.

=back

=head2 Others

=head1 SEE ALSO

L<CatalystX::Test::Recorder>, L<https://github.com/miyagawa/Plack-Middleware-Test-Recorder>, L<Plack::VCR>

=begin comment

=over

=item env_to_http_request

=back

=end comment

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/hoelzro/plack-middleware-recorder/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
