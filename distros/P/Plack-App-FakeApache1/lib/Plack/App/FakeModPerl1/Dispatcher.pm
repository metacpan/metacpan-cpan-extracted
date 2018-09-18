package Plack::App::FakeModPerl1::Dispatcher;

{
  $Plack::App::FakeModPerl1::Dispatcher::DIST = 'Plack-App-FakeApache1';
}
$Plack::App::FakeModPerl1::Dispatcher::VERSION = '0.0.6';
# ABSTRACT: Mimic Apache mod_perl1's dispatcher
use 5.10.1;
use Moose;

use Apache::ConfigParser;
use Carp;
use Data::Dump 'pp';
use TryCatch;
use Plack::App::FakeApache1::Constants qw/:common :2xx :4xx :5xx/;

has config_file_name => (
    is  => 'rw',
    isa => 'Str',
    default => sub {
        '/etc/myapp/apache_locations.conf'
    },
);

has parsed_apache_config => (
    is      => 'ro',
    isa     => 'Apache::ConfigParser',
    lazy    => 1,
    builder => '_build_parsed_apache_config',
);

has dispatches => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_dispatches',
);

has debug => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 0,
);

no Moose;

sub _build_parsed_apache_config {
    my $self = shift;
    my $config = Apache::ConfigParser->new;
    my $rc = $config->parse_file($self->config_file_name);
    if (not $rc) {
        die $config->errstr;
        exit;
    }

    return $config;
}



sub dispatch_for {
    my $self    = shift;
    my $plack   = shift;
    my $uri     = $plack->{env}{PATH_INFO};
    say $uri
        if $self->debug;
    my %location_config = %{ $self->_prepare_location_config_for( $uri ) };

    # if we have something in our config we can try to dispatch there
    if (keys %location_config) {
        my $action_blob = \%location_config;

        say "<$uri> matches " . join(',', @{ $location_config{location_regexps} })
            if $self->debug;

        # fake the order hadnlers are dealt with in mod_perl
        my @handler_order =
            qw(perlinithandler perlhandler perlloghandler perlcleanuphandler);

        HANDLER_TYPE:
        foreach my $handler_type (@handler_order) {
            next
                unless exists($location_config{$handler_type});

            my $ok_count = 0;

            my @handlers = @{ $location_config{$handler_type} };
            say "$handler_type: @handlers"
                if $self->debug;

            HANDLER_MODULE:
            foreach my $module (@handlers) {
                $self->_require_handler_module($module);
                my $handler_response = $self->_call_handler($plack, $module);
                if (not defined $handler_response) {
                    die "$module did not return a defined response";
                }

                # https://metacpan.org/module/GOZER/mod_perl-1.31/faq/mod_perl_api.pod#How-can-I-terminate-a-chain-of-handlers
                if (
                    $handler_type eq 'perlhandler'
                        and
                    !(
                        $handler_response == OK
                            or
                        $handler_response == DECLINED
                    )
                ) {
                    # set the HTTP response code
                    $plack->{response}{status} = $handler_response;
                    # stop processing PerlHandlers
                    next HANDLER_TYPE;
                }

                $ok_count++
                    if $handler_response == OK;
            }

            # if we just ran through *all* of the PerlHandlers and didn't have
            # problems (and didn't decline everything) we should 'convert' to
            # an HTTP_OK
            if($handler_type eq 'perlhandler') {
                if ($ok_count) {
                    $plack->{response}{status} = HTTP_OK;
                }
                else {
                    $plack->{response}{status} = HTTP_NOT_ACCEPTABLE;
                }
            }
        }
        return;
    }

    # essentially a 404, no?
    say "Failed to match <$uri> against anything";
    $plack->{response}->status(HTTP_NOT_FOUND);
}

sub _prepare_location_config_for {
    my $self = shift;
    my $uri  = shift;

    my %location_config = ();
    my $dispatches = $self->dispatches;

    foreach my $dispatch_blob (@$dispatches) {
        if ($uri =~ m{$dispatch_blob->{location_re}}) {
            # merge config, overwriting any existing settings with later
            # matches
            # NOTE: we don't deal with +My::Module settings here at all
            %location_config = (
                %location_config,
                %{ $dispatch_blob }
            );
            # keep the location(s) and location_re(s) we matched; just in case
            # we need it to debug later
            push @{ $location_config{locations} },          $dispatch_blob->{location};
            push @{ $location_config{location_regexps} },   $dispatch_blob->{location_re};
        }
    }
    # throwaway 'location' and 'location_re'; these only tell us the last one
    # we matched ans we can see that from 'locations' and 'location_regexps'
    foreach my $k (qw/location location_re/) {
        delete $location_config{$k};
    }
    say pp(%location_config) if $self->debug;

    return \%location_config;
}

sub _require_handler_module {
    my $self    = shift;
    my $module  = shift;

    say "require($module)"
        if $self->debug;
    eval "require $module";
    if (my $e=$@) {
        say "failed to require($module): $e";
        warn "failed to require($module): $e";
    }
}

sub _call_handler {
    my $self    = shift;
    my $plack   = shift;
    my $module  = shift;
    say "calling: $module"
        if $self->debug;

    my $res;
    try {
        if ($module->isa('Catalyst')) {
            say "$module is part of the Great Catalyst Hackup";
        }
        else {
            no strict 'refs';
            $res = &{"${module}::handler"}($plack)
                if $module->can('handler');
            say "no handler() in $module"
                unless $module->can('handler');
        }
    }
    catch ($e) {
        Carp::confess( "$module->handler(): $e" );
        # if we error we override the status of everything up to this point!
        return HTTP_INTERNAL_SERVER_ERROR;
    }

    return $res;
}

sub _build_dispatches {
    my $self = shift;
    my $config = $self->parsed_apache_config;
    my @locations = $config->find_down_directive_names('Location');
    my @dispatches;

    LOCATION: foreach my $location (@locations) {
        DAUGHTER: foreach my $daughter ($location->daughters) {
            next
                unless $daughter->name =~ /perl.*handler/;

            my @handlers = $daughter->get_value_array;

            push @dispatches, {
                location        => $location->value,
                location_re     => _location_to_regexp($location->value),
                $daughter->name => \@handlers,
            };
        }
    }

    return \@dispatches;
}

sub _location_to_regexp {
    my $location = shift;
    my $match_re;

    # ' ~ ' locations are a regexpy match
    if ($location =~ s{\A\s*~\s+}{}) {
        # they sometimes are wrapped in douuble-quotes, so we'd better remove
        # them
        $location =~ s{\A"(.+)"\z}{$1};
        $match_re = qr{$location};
    }
    else {
        $match_re = qr{\A\Q$location\E(/|$)};
    }

    return $match_re;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::FakeModPerl1::Dispatcher - Mimic Apache mod_perl1's dispatcher

=head1 VERSION

version 0.0.6

=begin explanation




=end explanation

We try to mimic the behaviour we're seeing in the apache/mod_perl world with
our matching&dispatching; our current best guess is to 'use the "best match"',
which we're saying is 'the one with the most path-parts (i.e. most /
characters)

Looking at:
http://ertw.com/blog/2007/08/23/apache-and-overlapping-location-directives/

So the general plan of action is to process each match in order, and store
any new settings, potentially overriding existing ones.
This appears to be how Apache does it, and hasn't broken in any obvious ways
yet.

=head2 dispatch_for

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
