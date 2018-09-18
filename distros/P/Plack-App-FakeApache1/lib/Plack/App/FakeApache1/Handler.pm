package Plack::App::FakeApache1::Handler;

{
  $Plack::App::FakeApache1::Handler::DIST = 'Plack-App-FakeApache1';
}
$Plack::App::FakeApache1::Handler::VERSION = '0.0.6';
# ABSTRACT: Mimic Apache's handler
use strict;
use warnings;

use Carp;

# borrowed heavily from
#  http://cpansearch.perl.org/src/MIYAGAWA/Plack-0.9946/lib/Plack/Handler/Apache2.pm

use Plack::Util;
use Scalar::Util;

use Plack::App::FakeApache1::Constants;

my %apps; # psgi file to $app mapping

sub new { bless{}, shift };

sub handler {
    my $class = __PACKAGE__;
    my $r     = shift;
    my $psgi  = $r->dir_config('psgi_app');
    $class->call_app($r, $class->load_app($psgi));
}

sub load_app {
    my($class, $app) = @_;
    return $apps{$app} ||= do {
        local $ENV{MOD_PERL}; # trick Catalyst/CGI.pm etc.
        Plack::Util::load_psgi $app;
    };
}

sub call_app {
    my ($class, $r, $app) = @_;

    Carp::croak('$app is undefined')
        unless defined $app;

    $r->subprocess_env; # let Apache create %ENV for us :)

    my $env = {
        %ENV,
        'psgi.version'        => [ 1, 1 ],
        'psgi.url_scheme'     => ($ENV{HTTPS}||'off') =~ /^(?:on|1)$/i ? 'https' : 'http',
        'psgi.input'          => $r,
        'psgi.errors'         => *STDERR,
        'psgi.multithread'    => Plack::Util::FALSE,
        'psgi.multiprocess'   => Plack::Util::TRUE,
        'psgi.run_once'       => Plack::Util::FALSE,
        'psgi.streaming'      => Plack::Util::TRUE,
        'psgi.nonblocking'    => Plack::Util::FALSE,
    };

    $class->fixup_path($r, $env);

    my $res = $app->($env);

    if (ref $res eq 'ARRAY') {
        _handle_response($r, $res);
    }
    elsif (ref $res eq 'CODE') {
        $res->(sub {
            _handle_response($r, $_[0]);
        });
    }
    else {
        die "Bad response $res";
    }

    return OK;
}

# Plack methods
sub finalize {
    my $self     = shift;
    my $response = $self->plack_response;

    $self->headers_out->do( sub { $response->header( @_ ); 1 } ) if is_success( $self->status() );
    $self->err_headers_out->do( sub { $response->header( @_ ); 1 } );

    return $response->finalize;
};



# The method for PH::Apache2::Regitsry to override.
sub fixup_path {
    my ($class, $r, $env) = @_;
    my $vpath    = ($env->{SCRIPT_NAME} || '') . ($env->{PATH_INFO} || '');
    my $location = $r->location || "/";
       $location =~ s{/$}{};
    (my $path_info = $vpath) =~ s/^\Q$location\E//;

    $env->{SCRIPT_NAME} = $location;
    $env->{PATH_INFO}   = $path_info;
}


sub _handle_response {
    my ($r, $res) = @_;

    my ($status, $headers, $body) = @{ $res };

    my $hdrs = ($status >= 200 && $status < 300)
        ? $r->headers_out : $r->err_headers_out;

    Plack::Util::header_iter($headers, sub {
        my($h, $v) = @_;
        if (lc $h eq 'content-type') {
            $r->content_type($v);
        } elsif (lc $h eq 'content-length') {
            $r->set_content_length($v);
        } else {
            $hdrs->add($h => $v);
        }
    });

    $r->status($status);

    if (Scalar::Util::blessed($body) and $body->can('path') and my $path = $body->path) {
        $r->sendfile($path);
    } elsif (defined $body) {
        Plack::Util::foreach($body, sub { $r->print(@_) });
        $r->rflush;
    }
    else {
        return Plack::Util::inline_object
            write => sub { $r->print(@_); $r->rflush },
            close => sub { $r->rflush };
    }

    return OK;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::FakeApache1::Handler - Mimic Apache's handler

=head1 VERSION

version 0.0.6

=head2 new

=head2 handler

=head2 load_app

=head2 call_app

=head2 finalize

=head2 fixup_path

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
