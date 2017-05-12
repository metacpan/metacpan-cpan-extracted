#!/usr/bin/perl

use 5.008001;
use strict;
use warnings;
use version; our $VERSION = qv('0.13');
use Carp;
use Pod::Usage;
use Sakai::Nakamura::Authz;
use Sakai::Nakamura::Content;
use Sakai::Nakamura::GroupMember;
use Sakai::Nakamura::GroupRole;
use Sakai::Nakamura::Group;
use Sakai::Nakamura::JsonQueryServlet;
use Sakai::Nakamura::LDAPSynch;
use Sakai::Nakamura::User;
use Sakai::Nakamura::World;

# Fail if args are empty or undefined:
if ( !defined $ARGV[0] || $ARGV[0] eq q{} ) {
    croak "Type '$0 help' for usage.";
}

# Give usage info if help or man are requested:
if ( $ARGV[0] =~ /(--){0,1}help/msx ) {
    pod2usage( -exitstatus => 0, -verbose => 1 );
}
elsif ( $ARGV[0] =~ /(--){0,1}man/msx ) {
    pod2usage( -exitstatus => 0, -verbose => 2 );
}

# Run command line programs:
local $0 = "$0 " . $ARGV[0];

my %module_lookup = (
    'authz',              'Sakai::Nakamura::Authz',
    'content',            'Sakai::Nakamura::Content',
    'group_member',       'Sakai::Nakamura::GroupMember',
    'group_role',         'Sakai::Nakamura::GroupRole',
    'group',              'Sakai::Nakamura::Group',
    'json_query_servlet', 'Sakai::Nakamura::JsonQueryServlet',
    'ldap_synch',         'Sakai::Nakamura::LDAPSynch',
    'user',               'Sakai::Nakamura::User',
    'world',              'Sakai::Nakamura::World'
);

my $module = $module_lookup{ $ARGV[0] };

if ( !defined $module ) {
    croak "Unknown command: '" . $ARGV[0] . "'\n" . "Type '$0 help' for usage.";
}

$module->command_line(@ARGV);

1;

__END__

#{{{Documentation

=head1 NAME

nakamura.pl

=head1 SYNOPSIS

nakamura perl script. Provides a means of manipulating a running nakamura system
from the command line.

=head1 OPTIONS

Usage: perl nakamura.pl [-OPTIONS [-MORE_OPTIONS]] [--] [PROGRAM_ARG1 ...]
The following options are accepted:

 --help or help     - view the script synopsis and options
 --man or man       - view the full script documentation
 authz              - run authz related actions
 content            - run content related actions
 group_member       - run group membership related actions
 group_role         - run group role related actions
 group              - run group related actions
 json_query_servlet - run json query servlet related actions
 ldap_synch         - run ldap synchronization related actions
 user               - run user related actions
 world              - run world related actions

Options may be merged together. -- stops processing of options.
Space is not required between options and their arguments.
For full details run: perl nakamura.pl --man

=head1 USAGE

=over

=item Output help for this script:

 perl nakamura.pl help

=item Output fuller help for this script:

 perl nakamura.pl man

=item Output help for specific functions:

 perl nakamura.pl [authz|content|group_member|group_role|group|json_query_servlet|ldap_synch|user|world] help

=back

=head1 DESCRIPTION

nakamura perl script. Provides a means of manipulating a running nakamura system
from the command line.

=head1 REQUIRED ARGUMENTS

None.

=head1 DIAGNOSTICS

None.

=head1 EXIT STATUS

1 on success, otherwise failure.

=head1 CONFIGURATION

None needed.

=head1 DEPENDENCIES

Carp; Pod::Usage;

=head1 INCOMPATIBILITIES

None known (^_-)

=head1 BUGS AND LIMITATIONS

None known (^_-)

=head1 AUTHOR

Daniel Parry -- daniel@caret.cam.ac.uk

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: (c) 2011 Daniel David Parry <perl@ddp.me.uk>

=cut

#}}}
