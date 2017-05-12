#!/usr/bin/perl -w

package Sakai::Nakamura::UserUtil;

use 5.008008;
use strict;
use warnings;
use Carp;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.13';

#{{{sub exists_setup

sub exists_setup {
    my ( $base_url, $act_on_user ) = @_;
    if ( !defined $base_url ) {
        croak 'No base url to check existence against!';
    }
    if ( !defined $act_on_user ) {
        croak 'No user to check existence of defined!';
    }
    return
      "get $base_url/system/userManager/user.exists.html?userid=$act_on_user";
}

#}}}

#{{{sub exists_eval

sub exists_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '204' );
}

#}}}

#{{{sub me_setup

sub me_setup {
    my ($base_url) = @_;
    if ( !defined $base_url ) {
        croak 'No base url to run me against!';
    }
    return "get $base_url/system/me";
}

#}}}

#{{{sub me_eval

sub me_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

#{{{sub profile_update_setup

sub profile_update_setup {
    my ( $base_url, $field, $value, $act_on_user, $profile_section ) = @_;
    if ( !defined $base_url ) {
        croak 'No base url to run profile update against!';
    }
    if ( !defined $field ) {
        croak 'No profile field to update specified!';
    }
    if ( !defined $value ) {
        croak 'No value specified to set profile field to!';
    }
    if ( !defined $act_on_user ) {
        croak 'No user specified to update profile for!';
    }
    if ( !defined $profile_section ) {
        $profile_section = 'basic';
    }
    my $profile_update_json =
      "{\"elements\":{\"$field\":{\"value\":\"$value\"}}}";
    my $post_variables =
"\$post_variables = [':content','$profile_update_json',':contentType','json',':operation','import',':removeTree','true',':replace','true',':replaceProperties','true']";
    return
"post $base_url/~$act_on_user/public/authprofile/$profile_section.profile.json $post_variables";
}

#}}}

#{{{sub profile_update_eval

sub profile_update_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

1;

__END__

=head1 NAME

Sakai::Nakamura::UserUtil - Methods to generate and check HTTP requests required for manipulating users.

=head1 ABSTRACT

Utility library returning strings representing Rest queries that perform
user related actions in the system.

=head1 METHODS

=head2 exists_setup

Returns a textual representation of the request needed to test whether a given
username exists in the system.

=head2 exists_eval

Inspects the result returned from issuing the request generated in exists_setup
returning true if the result indicates the username does exist in the system,
else false.

=head2 me_setup

Returns a textual representation of the request needed to return information
about the current user.

=head2 me_eval

Inspects the result returned from issuing the request generated in me_setup
returning true if the result indicates information was returned successfully,
else false.

=head2 profile_update_setup

Returns a textual representation of the request needed to update the profile
for a specified user.

=head2 profile_update_eval

Inspects the result returned from issuing the request generated in
profile_setup returning true if the result indicates profile information was
updated successfully, else false.

=head1 USAGE

use Sakai::Nakamura::UserUtil;

=head1 DESCRIPTION

UserUtil perl library essentially provides the request strings needed to
interact with user functionality exposed over the system rest interfaces.

Each interaction has a setup and eval method. setup provides the request,
whilst eval interprets the response to give further information about the
result of performing the request.

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

