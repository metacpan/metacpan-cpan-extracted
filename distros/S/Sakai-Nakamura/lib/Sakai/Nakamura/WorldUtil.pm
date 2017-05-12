#!/usr/bin/perl -w

package Sakai::Nakamura::WorldUtil;

use 5.008001;
use strict;
use warnings;
use Carp;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.13';

#{{{sub add_setup
# TODO: Have first and last name passed in for email
# TODO: Support multiple tags properly

sub add_setup {
    my (
        $base_url,   $id,          $username,
        $title,      $description, $tags,
        $visibility, $joinability, $worldTemplate
    ) = @_;
    if ( !defined $base_url ) { croak 'No base url defined to add against!'; }
    if ( !defined $id )       { croak 'No id defined to add!'; }
    if ( !defined $title )    { $title = $id; }
    if ( !defined $description ) { $description = $id; }
    if ( !defined $tags )        { $tags        = $id; }
    if ( !defined $visibility )  { $visibility  = 'public'; }
    if ( !defined $joinability ) { $joinability = 'yes'; }

    if ( !defined $worldTemplate ) {
        $worldTemplate = '/var/templates/worlds/group/simple-group';
    }
    if ( !defined $username ) { croak 'No user id defined to add!'; }
    my $post_variables =
        "\$post_variables = ['data','{\"id\":\"" 
      . $id
      . "\",\"title\":\""
      . $title
      . "\",\"tags\":[\""
      . $tags
      . "\"],\"description\":\""
      . $description
      . "\",\"visibility\":\""
      . $visibility
      . "\",\"joinability\":\""
      . $joinability
      . "\",\"worldTemplate\":\""
      . $worldTemplate
      . "\",\"message\":{\"body\":\"Hi \${firstName}\\n\\n \${creatorName} has added you as a \${role} to the group \\\"\${groupName}\\\"\\n\\n You can find it here \${link}\",\"subject\":\"\${creatorName} has added you as a \${role} to the group \\\"\${groupName}\\\"\",\"creatorName\":\"\",\"groupName\":\""
      . $title
      . "\",\"system\":\"Sakai\",\"link\":\""
      . $base_url . "/~"
      . $id
      . "\",\"toSend\":[]},\"usersToAdd\":[{\"userid\":\""
      . $username
      . "\",\"role\":\"manager\"}]}']";
    return "post $base_url/system/world/create $post_variables";
}

#}}}

#{{{sub add_eval
# TODO: check JSON that is returned for success, as a 200 status code is
# returned even if the world is not successfully added!

sub add_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

1;

__END__

=head1 NAME

Sakai::Nakamura::WorldUtil Methods to generate and check HTTP requests required for manipulating groups.

=head1 ABSTRACT

Utility library returning strings representing Rest queries that perform
group related actions in the system.

=head1 METHODS

=head2 add_setup

Returns a textual representation of the request needed to add the world to the
system.

=head2 add_eval

Check result of adding a world to the system.

=head1 USAGE

use Sakai::Nakamura::WorldUtil;

=head1 DESCRIPTION

WorldUtil perl library essentially provides the request strings needed to
interact with world functionality exposed over the system rest interfaces.

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
