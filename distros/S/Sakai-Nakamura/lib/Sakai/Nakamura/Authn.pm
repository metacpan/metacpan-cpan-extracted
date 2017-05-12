#!/usr/bin/perl -w

package Sakai::Nakamura::Authn;

use 5.008008;
use strict;
use warnings;
use Carp;
use base qw(Apache::Sling::Authn);
use Sakai::Nakamura::AuthnUtil;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.13';

#{{{sub new
sub new {
    my ( $class, $nakamura ) = @_;

    my $authn = $class->SUPER::new($nakamura);
    ${$nakamura}->{'Authn'} = \$authn;
    bless $authn, $class;
    return $authn;
}

#}}}

#{{{sub form_login
sub form_login {
    my ($authn)  = @_;
    my $username = $authn->{'Username'};
    my $password = $authn->{'Password'};
    my $res      = Apache::Sling::Request::request(
        \$authn,
        Sakai::Nakamura::AuthnUtil::form_login_setup(
            $authn->{'BaseURL'}, $username, $password
        )
    );
    my $success = Sakai::Nakamura::AuthnUtil::form_login_eval($res);
    my $message = "Form log in as user \"$username\" ";
    $message .= ( $success ? 'succeeded!' : 'failed!' );
    $authn->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub form_logout
sub form_logout {
    my ($authn) = @_;
    my $res =
      Apache::Sling::Request::request( \$authn,
        Sakai::Nakamura::AuthnUtil::form_logout_setup( $authn->{'BaseURL'} ) );
    my $success = Sakai::Nakamura::AuthnUtil::form_logout_eval($res);
    my $message = 'Form log out ';
    $message .= ( $success ? 'succeeded!' : 'failed!' );
    $authn->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub switch_user
sub switch_user {
    my ( $authn, $new_username, $new_password ) = @_;
    if ( !defined $new_username ) {
        croak 'New username to switch to not defined';
    }
    if ( !defined $new_password ) {
        croak 'New password to use in switch not defined';
    }
    if (   ( $authn->{'Username'} !~ /^$new_username$/msx )
        || ( $authn->{'Password'} !~ /^$new_password$/msx ) )
    {
        $authn->{'Username'} = $new_username;
        $authn->{'Password'} = $new_password;

        my $success = $authn->form_logout();
        if ( !$success ) {
            croak 'Form Auth log out for user "'
              . $authn->{'Username'}
              . '" at URL "'
              . $authn->{'BaseURL'}
              . "\" was unsuccessful\n";
        }
        $success = $authn->form_login();
        if ( !$success ) {
            croak "Form Auth log in for user \"$new_username\" at URL \""
              . $authn->{'BaseURL'}
              . "\" was unsuccessful\n";
        }
    }
    else {
        $authn->{'Message'} = 'User already active, no need to switch!';
    }
    if ( $authn->{'Verbose'} >= 1 ) {
        Apache::Sling::Print::print_result($authn);
    }
    return 1;
}

#}}}

#{{{sub login_user
sub login_user {
    my ($authn) = @_;
    my $success = 1;

    # Log in if url, username and
    # password are supplied:
    if (   defined $authn->{'BaseURL'}
        && defined $authn->{'Username'}
        && defined $authn->{'Password'} )
    {
        $success = $authn->form_login();
        if ( !$success ) {
            if ( $authn->{'Verbose'} >= 1 ) {
                Apache::Sling::Print::print_result($authn);
            }
            croak 'Form Auth log in for user "'
              . $authn->{'Username'}
              . '" at URL "'
              . $authn->{'BaseURL'}
              . "\" was unsuccessful\n";
        }
        if ( $authn->{'Verbose'} >= 1 ) {
            Apache::Sling::Print::print_result($authn);
        }
    }
    return $success;
}

#}}}

1;

__END__

=head1 NAME

Sakai::Nakamura::Authn - Authenticate to a Sakai::Nakamura instance.

=head1 ABSTRACT

Useful utility functions for general Authn functionality.

=head1 METHODS

=head2 new

Instantiate a new Authn object.

=head2 form_login

Log in to Sakai Nakamura with a form based approach.

=head2 form_logout

Log out from Sakai Nakamura with a form based approach.

=head2 switch_user

Switch from one authenticated user to another.

=head2 login_user

Log a user into the Sakai Nakamura system.

=head1 USAGE

use Sakai::Nakamura::Authn;

=head1 DESCRIPTION

Library providing useful utility functions for general Authn functionality.

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

LWP::UserAgent

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Daniel David Parry <perl@ddp.me.uk>

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: (c) 2012 Daniel David Parry <perl@ddp.me.uk>
