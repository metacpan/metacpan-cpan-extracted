#!/usr/bin/perl -w

package Sakai::Nakamura::GroupRole;

use 5.008008;
use strict;
use warnings;
use Carp;
use base qw(Apache::Sling::GroupMember);
use Sakai::Nakamura;
use Sakai::Nakamura::Authn;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.13';

#{{{ sub help
sub help {

    print <<"EOF";
Usage: perl $0 [-OPTIONS [-MORE_OPTIONS]] [--] [PROGRAM_ARG1 ...]
The following options are accepted:

 --additions or -A (file)       - file containing list of roles to be added to groups.
 --add or -a (role)             - add specified role.
 --auth (type)                  - Specify auth type. If ommitted, default is used.
 --delete or -d (role)          - delete specified group role.
 --exists or -e (role)          - check whether specified role exists in group.
 --group or -g (actOnGroup)     - group to perform role actions on.
 --help or -?                   - view the script synopsis and options.
 --log or -L (log)              - Log script output to specified log file.
 --man or -M                    - view the full script documentation.
 --pass or -p (password)        - Password of user performing actions.
 --threads or -t (threads)      - Used with -A, defines number of parallel
                                  processes to have running through file.
 --url or -U (URL)              - URL for system being tested against.
 --user or -u (username)        - Name of user to perform any actions as.
 --verbose or -v or -vv or -vvv - Increase verbosity of output.
 --view or -V                   - view roles of specified group.

Options may be merged together. -- stops processing of options.
Space is not required between options and their arguments.
For full details run: perl $0 --man
EOF

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

1;

__END__

=head1 NAME

Sakai::Nakamura::GroupRole - Manipulate Group Roles in a Sakai Nakamura instance.

=head1 ABSTRACT

group related functionality for Nakamura implemented over rest APIs.

=head1 METHODS

=head2 new

Create, set up, and return a GroupRole Object.

=head1 USAGE

use Sakai::Nakamura::GroupRole;

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
