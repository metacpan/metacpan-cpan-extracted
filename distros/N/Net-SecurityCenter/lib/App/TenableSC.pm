package App::TenableSC;

use strict;
use warnings;

use Getopt::Long qw( :config gnu_compat );
use Pod::Usage;
use Term::ReadKey;
use Carp;
use File::Basename;

use App::TenableSC::Utils qw(:all);
use App::TenableSC::Logger;

use Net::SecurityCenter;

our $VERSION = '0.311';

my @global_options = (
    'help|h',
    'man',
    'version|v',
    'verbose',

    'hostname=s',

    'username=s',
    'password=s',

    'ssl_cert_file=s',
    'ssl_key_file=s',
    'ssl_password=s',

    'access_key=s',
    'secret_key=s',

    'config=s'
);

$SIG{'__DIE__'} = sub {
    cli_error(@_);
};

our @command_options = ();

sub run {

    my ( $class, %args ) = @_;

    my $options       = {};
    my $config        = {};
    my $logger        = App::TenableSC::Logger->new;
    my @config_params = qw(hostname username password access_key secret_key
        verbose scheme timeout ssl_cert_file ssl_key_file ssl_password);

    GetOptions( $options, ( @global_options, @command_options ) ) or pod2usage( -verbose => 0 );

    pod2usage(1) if ( $options->{'help'} );
    cli_version  if ( $options->{'version'} );

    if ( $options->{'config'} ) {

        $config = config_parser( file_slurp( $options->{'config'} ) );

        if ( $config && defined( $config->{'SecurityCenter'} ) ) {

            foreach my $param (@config_params) {
                if ( defined( $config->{'SecurityCenter'}->{$param} ) ) {
                    $options->{$param} = $config->{'SecurityCenter'}->{$param};
                }
            }

        } else {
            cli_error('Failed to parse config file');
        }

    }

    pod2usage( -exitstatus => 0, -verbose => 2 ) if ( $options->{'man'} );
    pod2usage( -exitstatus => 0, -verbose => 0 ) if ( !$options->{'hostname'} || !$options->{'username'} );

    if ( $options->{'username'} && !$options->{'password'} ) {
        $options->{'password'} = cli_readkey("Enter $options->{username} password: ");
    }

    my $self = {
        config  => $config,
        options => $options,
        logger  => $logger,
        sc      => undef,
    };

    bless $self, $class;

    $self->startup;

    return $self;

}

sub startup {
    my ($self) = @_;
}

sub logger {
    return shift->{'logger'};
}

sub options {
    return shift->{'options'};
}

sub config {
    return shift->{'config'};
}

sub sc {
    return shift->{'sc'};
}

sub connect {

    my ($self) = @_;

    my $sc_options = {};

    $sc_options->{'logger'} = $self->logger              if ( $self->options->{'verbose'} );
    $sc_options->{'scheme'} = $self->options->{'scheme'} if ( $self->options->{'scheme'} );

    # Set SSL options for IO::Socket::SSL
    if ( defined $self->options->{'ssl_cert_file'} ) {

        $sc_options->{'ssl_options'}->{'SSL_cert_file'} = $self->options->{'ssl_cert_file'};

        if ( defined $self->options->{'ssl_key_file'} ) {
            $sc_options->{'ssl_options'}->{'SSL_key_file'} = $self->options->{'ssl_key_file'};
        }

        if ( defined $self->options->{'ssl_password'} ) {
            $sc_options->{'ssl_options'}->{'SSL_passwd_cb'} = sub {
                $self->options->{'ssl_password'};
            }
        }

    }

    my $sc = Net::SecurityCenter->new( $self->options->{'hostname'}, $sc_options );

    my %auth = ();

    # Username and password authentication
    if ( $self->options->{'username'} && $self->options->{'password'} ) {
        %auth = (
            username => $self->options->{'username'},
            password => $self->options->{'password'},
        );
    }

    # API Key authentication
    if ( $self->options->{'secret_key'} && $self->options->{'access_key'} ) {
        %auth = (
            secret_key => $self->options->{'secret_key'},
            access_key => $self->options->{'access_key'},
        );
    }

    $sc->login(%auth) or cli_error $sc->error;

    $self->{'sc'} = $sc;
    return $sc;

}

1;

=pod

=encoding UTF-8


=head1 NAME

App::TenableSC - Base class for Tenable.sc (SecurityCenter) applications


=head1 SYNOPSIS

    use App::TenableSC;

    # Add additional command line options
    @App::TenableSC::command_options = ( 'opt1=s', 'opt2=s', 'flag' );

    App::TenableSC->run;


=head1 DESCRIPTION

This module provides Perl scripts easy way to write Tenable.sc (SecurityCenter)
application using L<Net::SecurityCenter>.


=head1 METHODS

=head2 run

Run the application.

    use App::TenableSC::MyApp;

    # Add additional command line options
    @App::TenableSC::command_options = ( 'opt1=s', 'opt2=s', 'flag' );

    App::TenableSC::MyApp->run;


=head1 HELPER METHODS

=head2 config

Return config object

=head2 connect

Connect to Tenable.sc instance with provided credentials and return L<Net::SecurityCenter> object.

=head2 logger

Return L<App::TenableSC::Logger> object.

=head2 options

Return command line argument options.

=head2 sc

Return L<Net::SecurityCenter> object.

=head2 startup

This is your main hook into the application, it will be called at application startup.
Meant to be overloaded in a subclass.

    sub startup {
        my ($self) = @_;

        my $sc = $self->connect;

        $sc->plugin->download(id => $self->option->{'id'}, file => $self->option->{'file'});

        exit 0;
    }


=head1 DEFAULT COMMAND LINE ARGUMENTS

=over 4

=item * C<hostname> : Tenable.sc host/IP address

=item * C<username> : Username

=item * C<password> : Password

=item * C<access_key> : Access Key

=item * C<secret_key> : Secret Key

=item * C<config> : Configuration file

=item * C<help> : Brief help message

=item * C<man> : Full documentation

=item * C<version> : Command version

=item * C<verbose> : Full documentation

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-SecurityCenter/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-SecurityCenter>

    git clone https://github.com/giterlizzi/perl-Net-SecurityCenter.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2018-2023 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
