package Nagios::Plugin::POP3;
BEGIN {
  $Nagios::Plugin::POP3::VERSION = '1.001';
}

# ABSTRACT: Nagios plugin for checking POP3 Servers

use warnings;
use strict;
use Nagios::Plugin;
use Mail::POP3Client;




sub run {

    my $p = Nagios::Plugin->new(
        usage => <<END_USAGE,
Usage: %s [ -v|--verbose ] [-h|--host=<host>] [-u|--user=<user>] [-p|--password=<password>] [--count] [--delete]
[ -c|--critical=<critical threshold> ]
[ -w|--warning=<warning threshold> ]
END_USAGE
        version => $Nagios::Plugin::POP3VERSION,
        blurb   => q{Nagios plugin for POP3 mailboxes},
        extra   => <<END_EXTRA,
Currently only two POP3 mailbox actions are supported: count and delete

Count - Counts the number of messages on the server. The messages are not modified.
Delete - Deletes all messages on the server (and returns then number deleted)

THRESHOLDs for -w and -c are specified 'min:max' or 'min:' or ':max'
(or 'max'). If specified '\@min:max', a warning status will be generated
if the count *is* inside the specified range.
END_EXTRA
    );

    $p->add_arg(
        spec => 'warning|w=s',
        help => <<END_HELP,
-w, --warning=INTEGER:INTEGER
Minimum and maximum number of allowable result, outside of which a
warning will be generated.  If omitted, no warning is generated.
END_HELP
    );

    $p->add_arg(
        spec => 'critical|c=s',
        help => <<END_HELP,
-c, --critical=INTEGER:INTEGER
Minimum and maximum number of the generated result, outside of
which a critical will be generated.
END_HELP
    );

    $p->add_arg(
        spec    => 'host|h=s',
        default => 'localhost.localdomain',
        help    => <<END_HELP,
-h, --host
POP3 Host (defaults to localhost.localdomain)
END_HELP
    );

    $p->add_arg(
        spec => 'username|u=s',
        help => <<END_HELP,
-u, --username
POP3 Username
END_HELP
    );

    $p->add_arg(
        spec => 'password|p=s',
        help => <<END_HELP,
-p, --password
POP3 password
END_HELP
    );

    $p->add_arg(
        spec => 'count',
        help => <<END_HELP,
--count
Count the number of messages on the server. The messages on the server are not modified.
This is the default action.
END_HELP
    );

    $p->add_arg(
        spec => 'delete',
        help => <<END_HELP,
--delete
Delete all messages on the server. Counts how many messages were deleted.
END_HELP
    );

    # Parse arguments and process standard ones (e.g. usage, help, version)
    $p->getopts;

    if ( !defined $p->opts->warning && !defined $p->opts->critical ) {
        $p->nagios_die("You need to specify a threshold argument");
    }

    my $pop = new Mail::POP3Client(
        USER     => $p->opts->username,
        PASSWORD => $p->opts->password,
        HOST     => $p->opts->host,
    );
    my $count = $pop->Count;
    $p->nagios_die( "Error connecting to server: " . $p->opts->host ) if $count < 0;

    for my $i ( 1 .. $count ) {
        $pop->Delete($i) if $p->opts->delete,;
    }
    $pop->Close();

    $p->nagios_exit(
        return_code => $p->check_threshold($count),
        message => ( $p->opts->delete ? 'Deleted ' : 'Counted ' ) . "$count message" . ( $count == 1 ? "\n" : "s\n" ),
    );
}


1;

__END__
=pod

=head1 NAME

Nagios::Plugin::POP3 - Nagios plugin for checking POP3 Servers

=head1 VERSION

version 1.001

=head1 SYNOPSIS

Installs the C<nagios_plugin_pop3> command that can be used as:

    > nagios_plugin_pop3 --help
    nagios_plugin_pop3 0.01

    This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY.
    It may be used, redistributed and/or modified under the terms of the GNU
    General Public Licence (see http://www.fsf.org/licensing/licenses/gpl.txt).

    Nagios plugin for POP3 mailboxes

    Usage: nagios_plugin_pop3 [ -v|--verbose ] [-h|--host=<host>] [-u|--user=<user>] [-p|--password=<password>] [--count] [--delete]
    [ -c|--critical=<critical threshold> ]
    [ -w|--warning=<warning threshold> ]

     -?, --usage
       Print usage information
     -h, --help
       Print detailed help screen
     -V, --version
       Print version information
     --extra-opts=[<section>[@<config_file>]]
       Section and/or config_file from which to load extra options (may repeat)
     -w, --warning=INTEGER:INTEGER
    Minimum and maximum number of allowable result, outside of which a
    warning will be generated.  If omitted, no warning is generated.

     -c, --critical=INTEGER:INTEGER
    Minimum and maximum number of the generated result, outside of
    which a critical will be generated.

     -h, --host
    POP3 Host (defaults to localhost.localdomain)

     -u, --username
    POP3 Username

     -p, --password
    POP3 password

     --count
    Count the number of messages on the server. The messages on the server are not modified.
    This is the default action.

     --delete
    Delete all messages on the server. Counts how many messages were deleted.

     -t, --timeout=INTEGER
       Seconds before plugin times out (default: 15)
     -v, --verbose
       Show details for command-line debugging (can repeat up to 3 times)
    Currently only two POP3 mailbox actions are supported: count and delete

    Count - Counts the number of messages on the server. The messages are not modified.
    Delete - Deletes all messages on the server (and returns then number deleted)

    THRESHOLDs for -w and -c are specified 'min:max' or 'min:' or ':max'
    (or 'max'). If specified '@min:max', a warning status will be generated
    if the count *is* inside the specified range.

For example, if you have a process that sends an email to a pop3 mailbox once per day, you can
get nagios to check the mailbox for a single message (and delete all messages) every day via:

    nagios_plugin_pop3 -h myhost -u myname -p mypass -c 1:1 --delete

=head1 DESCRIPTION

Currently only two POP3 mailbox actions are supported: C<count> and C<delete>

=over 4

=item * count

Counts the number of messages on the server. The messages are not modified.

=item * delete

Deletes all messages on the server (and returns then number deleted)

=back

=head1 METHODS

=head2 run

Run the plugin

=head1 SEE ALSO

L<Nagios::Plugin>

=head1 AUTHOR

Patrick Donelan <pdonelan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Patrick Donelan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

