#!/usr/bin/perl -w

package Sakai::Nakamura::GroupMember;

use 5.008008;
use strict;
use warnings;
use Carp;
use Getopt::Long qw(:config bundling);
use Sakai::Nakamura;
use Sakai::Nakamura::Authn;
use Sakai::Nakamura::GroupMemberUtil;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.13';

#{{{sub new

sub new {
    my ( $class, $authn, $verbose, $log ) = @_;
    if ( !defined $authn ) { croak 'no authn provided!'; }
    my $response;
    $verbose = ( defined $verbose ? $verbose : 0 );
    my $group_member = {
        BaseURL  => ${$authn}->{'BaseURL'},
        Authn    => $authn,
        Message  => q{},
        Response => \$response,
        Verbose  => $verbose,
        Log      => $log
    };
    bless $group_member, $class;
    return $group_member;
}

#}}}

#{{{sub set_results
sub set_results {
    my ( $group, $message, $response ) = @_;
    $group->{'Message'}  = $message;
    $group->{'Response'} = $response;
    return 1;
}

#}}}

#{{{sub add
sub add {
    my ( $group, $act_on_group, $act_on_role, $add_member ) = @_;
    my $res = Apache::Sling::Request::request(
        \$group,
        Sakai::Nakamura::GroupMemberUtil::add_setup(
            $group->{'BaseURL'}, $act_on_group, $act_on_role, $add_member
        )
    );
    my $success = Sakai::Nakamura::GroupMemberUtil::add_eval($res);
    my $message = "Member: \"$add_member\" ";
    $message .= ( $success ? 'added' : 'was not added' );
    $message .= " to role \"$act_on_role\" in group \"$act_on_group\"!";
    $group->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub add_from_file
sub add_from_file {

    # TODO implement
    return 1;
}

#}}}

#{{{sub check_exists
sub check_exists {

    # TODO implement
    return 1;
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
# TODO add config options:

sub config {
    my ( $class, $nakamura, @ARGV ) = @_;
    my $group_member_config = $class->config_hash( $nakamura, @ARGV );

    GetOptions( $group_member_config ) or $class->help();

    return $group_member_config;
}

#}}}

#{{{sub config_hash
# TODO add config options:

sub config_hash {
    my ( $class, $nakamura, @ARGV ) = @_;
    my %group_member_config = ();

    return \%group_member_config;
}

#}}}

#{{{sub del
sub del {

    # TODO implement
    return 1;
}

#}}}

#{{{ sub help
sub help {

    # TODO: implement

    print <<"EOF";
Usage: perl $0 [-OPTIONS [-MORE_OPTIONS]] [--] [PROGRAM_ARG1 ...]
The following options are accepted:

Options may be merged together. -- stops processing of options.
Space is not required between options and their arguments.
For full details run: perl $0 --man
EOF

    return 1;
}

#}}}

#{{{ sub man
sub man {

    # TODO: implement
    my ($group_member) = @_;

    print <<'EOF';
group membership perl script. Provides a means of managing role members in nakamura from the command
line. The script also acts as a reference implementation for the Group Member perl
library.

EOF

    $group_member->help();

    print <<"EOF";
Example Usage

* TODO: add examples

 perl $0 -U http://localhost:8080 -u admin -p admin
EOF

    return 1;
}

#}}}

#{{{sub run
sub run {
    my ( $group_member, $nakamura, $config ) = @_;
    if ( !defined $config ) {
        croak 'No group member config supplied!';
    }
    $nakamura->check_forks;
    my $authn =
      defined $nakamura->{'Authn'}
      ? ${ $nakamura->{'Authn'} }
      : new Sakai::Nakamura::Authn( \$nakamura );

    my $success = 1;

    if    ( $nakamura->{'Help'} ) { $group_member->help(); }
    elsif ( $nakamura->{'Man'} )  { $group_member->man(); }

    # TODO: implement

    return $success;
}

#}}}

#{{{sub view
sub view {

    # TODO implement
    return 1;
}

#}}}

1;

__END__

=head1 NAME

Sakai::Nakamura::GroupMember - Manipulate Group Members in a Sakai Nakamura instance.

=head1 ABSTRACT

group related functionality for Sling implemented over rest APIs.

=head1 METHODS

=head2 new

Create, set up, and return a GroupMember Object.

=head2 add

Add a member to a role in a group.

=head2 add_from_file

Add members to roles in groups as specified in a file.

=head2 del

Delete a member from a role in a group.

=head2 check_exists

Check whether a member exists in a role in a group.

=head2 view

View the members in a given role in a group.

=head1 USAGE

use Sakai::Nakamura::GroupMember;

=head1 DESCRIPTION

Perl library providing a layer of abstraction to the REST group methods

Sakai Nakamura adds another layer to the traditional
Apache::Sling view of Groups. Rather than just:
Groups -> Members, there now exists:
Groups -> Roles -> Members

Roles are the top level group members, they define what members of
those roles are able to do in the group.

Role members are the actual system users - they get added to a role and
that defines what they are able to do in a group:

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
