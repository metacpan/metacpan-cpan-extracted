#!/usr/bin/perl -w

package Sakai::Nakamura::User;

use 5.008008;
use strict;
use warnings;
use Carp;
use Getopt::Long qw(:config bundling);
use base qw(Apache::Sling::User);
use Sakai::Nakamura;
use Sakai::Nakamura::Authn;
use Sakai::Nakamura::UserUtil;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.13';

#{{{sub check_exists
sub check_exists {
    my ( $user, $act_on_user ) = @_;
    my $res = Apache::Sling::Request::request(
        \$user,
        Sakai::Nakamura::UserUtil::exists_setup(
            $user->{'BaseURL'}, $act_on_user
        )
    );
    my $success = Sakai::Nakamura::UserUtil::exists_eval($res);
    my $message = "User \"$act_on_user\" ";
    $message .= ( $success ? 'exists!' : 'does not exist!' );
    $user->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{ sub command_line
sub command_line {
    my ( $class, @ARGV ) = @_;
    my $nakamura = Sakai::Nakamura->new;
    my $config   = $class->config( $nakamura, @ARGV );
    my $authn    = new Sakai::Nakamura::Authn( \$nakamura );
    return $class->run( $nakamura, $config );
}

#}}}

#{{{sub config

sub config {
    my ( $class, $nakamura, @ARGV ) = @_;
    my $user_config = $class->config_hash( $nakamura, @ARGV );

    GetOptions(
        $user_config,          'auth=s',
        'help|?',              'log|L=s',
        'man|M',               'pass|p=s',
        'threads|t=s',         'url|U=s',
        'user|u=s',            'verbose|v+',
        'add|a=s',             'additions|A=s',
        'change-password|c=s', 'delete|d=s',
        'email|E=s',           'first-name|f=s',
        'exists|e=s',          'last-name|l=s',
        'new-password|n=s',    'password|w=s',
        'property|P=s',        'update=s',
        'view|V=s'
    ) or $class->help();

    return $user_config;
}

#}}}

#{{{sub config_hash

sub config_hash {
    my ( $class, $nakamura, @ARGV ) = @_;
    my $me;
    my $profile_field;
    my $profile_section;
    my $profile_update;
    my $profile_value;
    my $user_config = $class->SUPER::config_hash( $nakamura, @ARGV );
    $user_config->{'me'}              = \$me;
    $user_config->{'profile-field'}   = \$profile_field;
    $user_config->{'profile-section'} = \$profile_section;
    $user_config->{'profile-update'}  = \$profile_update;
    $user_config->{'profile-value'}   = \$profile_value;

    return $user_config;
}

#}}}

#{{{sub me
sub me {
    my ($user) = @_;
    my $res =
      Apache::Sling::Request::request( \$user,
        Sakai::Nakamura::UserUtil::me_setup( $user->{'BaseURL'} ) );
    my $success = Sakai::Nakamura::UserUtil::me_eval($res);
    my $message = (
        $success
        ? ${$res}->content
        : 'Problem fetching details for current user'
    );
    $user->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub profile_update
sub profile_update {
    my ( $user, $field, $value, $act_on_user, $profile_section ) = @_;
    my $res = Apache::Sling::Request::request(
        \$user,
        Sakai::Nakamura::UserUtil::profile_update_setup(
            $user->{'BaseURL'}, $field, $value,
            $act_on_user,       $profile_section
        )
    );
    my $success = Sakai::Nakamura::UserUtil::profile_update_eval($res);
    my $message = (
        $success
        ? 'Profile successfully updated'
        : 'Problem fetching details for current user'
    );
    $user->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub run
sub run {
    my ( $user, $nakamura, $config ) = @_;
    if ( !defined $config ) {
        croak 'No user config supplied!';
    }
    my $authn =
      defined $nakamura->{'Authn'}
      ? ${ $nakamura->{'Authn'} }
      : new Sakai::Nakamura::Authn( \$nakamura );

    my $success = 1;

    if    ( $nakamura->{'Help'} ) { $user->help(); }
    elsif ( $nakamura->{'Man'} )  { $user->man(); }
    elsif ( defined ${ $config->{'exists'} } ) {
        $authn->login_user();
        my $user = new Sakai::Nakamura::User( \$authn, $nakamura->{'Verbose'},
            $nakamura->{'Log'} );
        $success = $user->check_exists( ${ $config->{'exists'} } );
        Apache::Sling::Print::print_result($user);
    }
    elsif ( defined ${ $config->{'me'} } ) {
        $authn->login_user();
        my $user = new Sakai::Nakamura::User( \$authn, $nakamura->{'Verbose'},
            $nakamura->{'Log'} );
        $success = $user->me();
        Apache::Sling::Print::print_result($user);
    }
    elsif ( defined ${ $config->{'profile-update'} } ) {
        $authn->login_user();
        my $user = new Sakai::Nakamura::User( \$authn, $nakamura->{'Verbose'},
            $nakamura->{'Log'} );
        $success = $user->profile_update(
            ${ $config->{'profile-field'} },
            ${ $config->{'profile-value'} },
            ${ $config->{'profile-update'} },
            ${ $config->{'profile-section'} }
        );
        Apache::Sling::Print::print_result($user);
    }
    else {
        $success = $user->SUPER::run( $nakamura, $config );
    }
    return $success;
}

#}}}

1;

__END__

=head1 NAME

Sakai::Nakamura::User - Methods for manipulating users in a Sakai Nakamura system.

=head1 ABSTRACT

user related functionality for Sling implemented over rest APIs.

=head1 METHODS

=head2 check_exists

Check whether the user exists

=head2 me

Fetch output from the sakai me service for the logged in user

=head2 profile_update

Update a value in the user profile

=head1 USAGE

use Sakai::Nakamura::User;

=head1 DESCRIPTION

Perl library providing a layer of abstraction to the REST user methods

=head1 REQUIRED ARGUMENTS

None required.

=head1 OPTIONS

n/a

=head1 DIAGNOSTICS

n/a

=head1 EXIT STATUS

0 on success.

=head1 CONFIGURATION

None required.

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Daniel David Parry <perl@ddp.me.uk>

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: (c) 2012 Daniel David Parry <perl@ddp.me.uk>
