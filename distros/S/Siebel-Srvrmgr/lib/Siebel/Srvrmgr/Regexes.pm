package Siebel::Srvrmgr::Regexes;

use warnings;
use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK =
  qw(SRVRMGR_PROMPT LOAD_PREF_RESP LOAD_PREF_CMD CONN_GREET SIEBEL_ERROR ROWS_RETURNED SIEBEL_SERVER prompt_slices);
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );
our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::Regexes - common regular expressions to match things in srvrmgr output

=head1 SYNOPSIS

    use Siebel::Srvrmgr::Regexes qw(SRVRMGR_PROMPT);

    if($line =~ /SRVRMGR_PROMPT/) {
        #do something
    }

=head1 DESCRIPTION

This modules exports several pre-compiled regular expressions by demand.

To get all regular expressions, you can use the tag C<:all>;

=head1 EXPORTS

=head2 SRVRMGR_PROMPT

Regular expression to match the C<srvrmgr> prompt, with or without the Siebel server name and/or command.

=cut

# this will be reused by more than one sub
my $server_regex = '[[:alpha:]][\w\_]{1,11}';

# :WARNING:09/22/2016 10:11:10 PM:: be very careful to change SRVRMGR_PROMPT, Siebel::Srvrmgr::ListParser::FSA depends a lot on it!
sub SRVRMGR_PROMPT {
    return qr/^srvrmgr(\:$server_regex)?>(\s.*)?$/;
}

=head2 prompt_slices

This sub will use the SRVRMGR_PROMPT regular expression to try and match all the pieces of information that can be included into the C<srvrmgr> prompt:

=over

=item *

the Siebel Server name

=item *

the executed command

=back

It expects as parameter the corresponding string of a C<srvrmgr> prompt. It will then return a list of two values: Siebel Server Name and the executed command.
Those files can be undefined depending on the string given as parameter, so they should be tested before use.

This helper function was created because it is a common case to search for both string in the prompt, it should help avoiding impacts to other parts of the
API given changes made to the SRVRMGR_PROMPT regular expression, but you can always fetch the values from it directly.

Additionally, this sub will also remove any character that is not part of the slices (colon and spaces).

When using this function, be sure to do it like:
    my ($server,$command) = prompt_slices($my_prompt);

=cut

sub prompt_slices {
    my $prompt = shift;
    my ( $server, $cmd );
    $prompt =~ SRVRMGR_PROMPT;

    if ( defined($1) ) {
        $server = $1;
        $server =~ tr/://d;
    }

    if ( defined($2) ) {

        if ( $2 eq ' ' ) {
            $cmd = undef;
        }
        else {
            $cmd = $2;
            $cmd =~ s/^\s+//;
            $cmd =~ s/\s+$//;
        }
    }

    return $server, $cmd;
}

=head2 SIEBEL_SERVER

Regular expression to match a valid Siebel Server name. See L<https://docs.oracle.com/cd/E14004_01/books/SiebInstUNIX/SiebInstCOM_Requirements21.html#wp1333940>.

=cut

sub SIEBEL_SERVER {
    return qr/^$server_regex$/;
}

=pod

=head2 LOAD_PREF_RESP

Regular expression to match the C<load preferences> response once the command is submitted.

=cut

sub LOAD_PREF_RESP {
    return qr/^(srvrmgr(\:$server_regex)?>)?\s?File\:\s.*\.pref$/;
}

=pod

=head2 LOAD_PREF_CMD

Regular expression to match the C<load preferences> command when submitted.

=cut

sub LOAD_PREF_CMD {
    return qr/^(srvrmgr(\:$server_regex)?>)?\s?load preferences$/;
}

=pod

=head2 CONN_GREET

Regular expression to match the first line submitted by a Siebel enterprise when the C<srvrmgr> connects to it. It will look like something like this:

    Siebel Enterprise Applications Siebel Server Manager, Version 8.0.0.7 [20426] LANG_INDEPENDENT

It is a known issue that UTF-8 data with BOM character will cause this regular expression to B<not> match.

=cut

sub CONN_GREET {
    return
qr/^Siebel\sEnterprise\sApplications\sSiebel\sServer\sManager\,\sVersion.*/;
}

=pod

=head2 ROWS_RETURNED

This regular expression should match the last but one line returned by a command, for example:

    136 rows returned.

This line indicated how many rows were returned by a command.

=cut

sub ROWS_RETURNED {
    return qr/^\d+\srows?\sreturned\./;
}

=pod

=head2 SIEBEL_ERROR

This regular expression should match errors from Siebel like, for example:

    SBL-SSM-00003: Error opening SISNAPI connection.
    SBL-NET-01218: The connection was refused by server foobar. No component is listening on port 49170.

The regular expression matches the default error code.

=cut

sub SIEBEL_ERROR {
    return qr/^SBL\-\w{3}\-\d+/;
}

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
