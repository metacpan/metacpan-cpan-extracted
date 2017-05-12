package Plack::Middleware::ModuleInfo;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Plack::Util::Accessor qw/ path allow dumper /;
use Net::CIDR::Lite;
use Module::Info;

our $VERSION = '0.04';

sub prepare_app {
    my $self = shift;

    # this code of block was copied from Plack::Middleware::ServerStatus::Lite ;-P
    if ( $self->allow ) {
        my @ip = ref $self->allow ? @{$self->allow} : ($self->allow);
        my @ipv4;
        my @ipv6;
        for (@ip) {
            # hacky check, but actual checks are done in Net::CIDR::Lite.
            if (/:/) {
                push @ipv6, $_;
            } else {
                push @ipv4, $_;
            }
        }
        if ( @ipv4 ) {
            my $cidr4 = Net::CIDR::Lite->new();
            $cidr4->add_any($_) for @ipv4;
            $self->{__cidr4} = $cidr4;
        }
        if ( @ipv6 ) {
            my $cidr6 = Net::CIDR::Lite->new();
            $cidr6->add_any($_) for @ipv6;
            $self->{__cidr6} = $cidr6;
        }
    }

    if (!$self->allow || !$self->path) {
        warn "[Plack::Middleware::ModuleInfo] 'allow' is not provided."
                . "Any host will not be able to access the information.\n";
    }

    unless ($self->dumper) {
        require YAML;
        $self->dumper(sub{
            my ($info) = @_;
            return [
                200,
                ['Content-Type' => 'text/plain'],
                [YAML::Dump($info)]
            ];
        });
    }
}

sub call {
    my ($self, $env) = @_;

    my $path = $self->path;

    if( $path && $env->{PATH_INFO} =~ m!^$path! ) {
        my $res = $self->_handle_module_info($env);
        return $res;
    }

    my $res = $self->app->($env);

    return $res;
}

sub _handle_module_info {
    my ($self, $env) = @_;

    if ( ! $self->_allowed($env->{REMOTE_ADDR}) ) {
        return [403, ['Content-Type' => 'text/plain'], [ 'Forbidden' ]];
    }

    my $info = { PID => $$, lib => \@INC, };

    if ( my $input_module = $env->{QUERY_STRING} ) {
        $input_module =~ s/-/::/g;
        if ( my $mod = Module::Info->new_from_loaded($input_module) ) {
            $info->{module} = {
                name    => $mod->name,
                version => eval "\$$input_module\::VERSION" || $mod->version, ## no critic
                file    => $mod->file,
            };
        }
        else {
            $info->{module} = "'$input_module' not found";
        }
    }

    return $self->dumper->($info, $env);
}

sub _allowed {
    my ( $self , $address ) = @_;

    if ( $address =~ /:/) {
        return unless $self->{__cidr6};
        return $self->{__cidr6}->find( $address );
    }
    return unless $self->{__cidr4};
    return $self->{__cidr4}->find( $address );
}

1;

__END__

=head1 NAME

Plack::Middleware::ModuleInfo - show the perl module information


=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'ModuleInfo',
            allow => ['127.0.0.1'],
            path  => '/module_info';
        $app;
    };

then access to the server

    % curl http://server:port/module_info?Some-Module
    ---
    PID: 28268
    lib:
      - /home/user/perlbrew/perls/perl-5.18/lib/site_perl/5.18.4/x86_64-linux
      - /home/user/perlbrew/perls/perl-5.18/lib/site_perl/5.18.4
      - /home/user/perlbrew/perls/perl-5.18/lib/5.18.4/x86_64-linux
      - /home/user/perlbrew/perls/perl-5.18/lib/5.18.4
    mod:
      file: /home/user/perlbrew/perls/perl-5.18/lib/5.18.4/Some/Module.pm
      name: Some::Module
      version: 0.01


=head1 DESCRIPTION

Plack::Middleware::ModuleInfo is the Plack middleware for showing module information on the process.


=head1 METHODS

=over 4

=item prepare_app

=item call

=back


=head1 CONFIGURATIONS

=head2 path

    path => '/module_info',

location that displays module information

=head2 allow

    allow => '127.0.0.1'
    allow => ['192.168.0.0/16', '10.0.0.0/8']

host based access control of a page of module information. supports IPv6 address.

=head2 dumper

You can customize the result.

    use JSON qw/encode_json/;

    builder {
        enable 'ModuleInfo',
            allow  => '127.0.0.1',
            path   => '/module_info',
            dumper => sub {
                my ($info, $env) = @_;
                [200, ['Content-Type' => 'application/json'], [encode_json($info)]];
            };
        sub { [200,[],['OK']] };
    };


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/Plack-Middleware-ModuleInfo"><img src="https://secure.travis-ci.org/bayashi/Plack-Middleware-ModuleInfo.png?_t=1426254400"/></a> <a href="https://coveralls.io/r/bayashi/Plack-Middleware-ModuleInfo"><img src="https://coveralls.io/repos/bayashi/Plack-Middleware-ModuleInfo/badge.png?_t=1426254400&branch=master"/></a>

=end html

Plack::Middleware::ModuleInfo is hosted on github: L<http://github.com/bayashi/Plack-Middleware-ModuleInfo>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Plack::Middleware>

L<Module::Info>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
