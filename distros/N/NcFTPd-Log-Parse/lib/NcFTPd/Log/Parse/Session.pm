package NcFTPd::Log::Parse::Session;

use strict;
use warnings;
use base 'NcFTPd::Log::Parse::Base';

# From http://www.ncftp.com/ncftpd/doc/sesslog.html#CloseCodes
my %CLOSE_CODE_DESCRIPTIONS = (
    0  => 'Normal disconnect.',
    1  => 'End-of-file on control connection; the client closed the connection but did not issue a QUIT primitive.',
    2  => 'Miscellaneous error.',
    3  => 'Client exceeded idle timeout limit.',
    4  => 'Client exceeded login timeout.',
    5  => 'Timed-out while sending to client.',
    6  => 'Lost connection (broken pipe).',
    7  => 'Control connection reset by peer.',
    8  => 'Network I/O error.',
    9  => 'TCP Wrappers denied the user.',
    10 => 'Too many users already logged on.',
    11 => 'Too many users already logged on to domain.',
    12 => 'Too many users already logged on by the same username.',
    13 => 'Too many users already logged on by the same IP address.',
    14 => 'Bad startup directory.',
    15 => 'Passive data socket failed.',
    16 => 'Passive data connection accept failed.',
    17 => 'Passive data connection accept timed-out.',
    18 => 'Passive data connection accept succeeded, but remote port was under 1024.',
    19 => 'Passive data connection accept succeeded, but remote address was different from that of the control connection and proxy connections are disabled.',
    20 => 'Port data connection attempt to client timed-out.',
    21 => 'Port data connection attempt to client failed.',
    22 => 'Port data connection specified a different remote address than that of the control connection and proxy connections are disabled.',
    23 => 'Port data connection specified an internal network address.',
    24 => 'Port data connection specified a remote port number under 1024.',
    25 => 'Control connection\'s port number was under 1024.',
    26 => 'Socket failed.',
    27 => 'ncftpd_authd exchange state failed.',
    28 => 'ncftpd_authd denied the user.',
    29 => 'ncftpd_authd miscellaneous error.',
    30 => 'Too many failed username/password attempts.',
    31 => 'No logins are allowed during system maintenance.',
    32 => 'Anonymous logins not allowed here.',
    33 => 'Non-anonymous logins not allowed here.',
    34 => 'Buffer overflow attempted by client.',
    35 => 'Could not restore user privileges.',
    36 => 'Domain is marked as disabled.',
    37 => 'Timed out during data transfer.',
    38 => 'Wrong protocol used by client.',
    39 => 'Syntax error in passwd database user record.',
    40 => 'Malformed User Permssions String in passwd database user record or from Authd.',
    41 => 'Malformed Umask in passwd database user record or from Authd.'
);

my $CLOSE_CODES = join '|', keys %CLOSE_CODE_DESCRIPTIONS;
my $DIGITS6  = '(\d*?),' x 6;
my $DIGITS16 = '(\d*?),' x 16;
my %COMMON_REGEX = __PACKAGE__->_common_regex;
my @FIELD_NAMES = qw{
    user
    email
    host
    session_time
    time_between_commands
    bytes_retrieved
    bytes_stored
    number_of_commands
    retrieves
    stores
    chdirs
    nlists
    lists
    types
    port_pasv
    pwd
    size
    mdtm
    site
    logins
    failed_data_connections
    last_transfer_result
    successful_downloads
    failed_downloads
    successful_uploads
    failed_uploads
    successful_listings
    failed_listings
    close_code
    session_id
};

sub _expand_field
{
    my ($self, $name, $value) = @_;

    if($name eq 'close_code') {
      $value = $CLOSE_CODE_DESCRIPTIONS{$value};
    }

    $value
}

sub _parse_entry
{
    my ($self, $fields) = @_;
    my $entry;

    if($fields) {
      my @values = $fields =~ m{
	    ((?:REFUSED|DENIED|.*?)),       # Username, sometimes blank, why? Also REFUSED entries have no session id
	    (.*?),		            # "Email" (anonymous login password)
	    (.*?),		            # Host
	    (\d*?),		            # Session time
	    ((?:$COMMON_REGEX{decimal})?),  # Time between commands
	    $DIGITS16		            # 16 comma separated digits
	    ((?:NONE|$COMMON_REGEX{status})?),   # Status of last transfer
	    $DIGITS6		           # 6 comma separated digits
	    ($CLOSE_CODES)	           # Close code i.e. why the conection was closed
	    (?:,($COMMON_REGEX{session})?,)?
	}x;

	if(@values) {
	  @$entry{@FIELD_NAMES} = @values;
	}
    }

    $entry;
}

1;

__END__


=head1 NAME

NcFTPd::Log::Parse::Session - parse NcFTPd session logs

=head1 SYNOPSIS

  use NcFTPd::Log::Parse::Session;
  $parser = NcFTPd::Log::Parse::Session->new('sess.20100101');

  while($line = $parser->next) {
      $line->{user};
      $line->{successful_downloads};
      $line->{failed_uploads};
      # ...
    }
  }

  # Check for an error, otherwise it was EOF
  if($parser->error) {
    die 'Parsing failed: ' . $parser->error;
  }

=head1 DESCRIPTION

This class is part of the L<NcFTPd::Log::Parse> package. Refer to its documentation for a detailed overview of how this and the other parsers work.

Only C<NcFTPd::Log::Parse::Session> specific features are described here.

=head1 SESSION LOG ENTRIES

Unless noted, fields in a session log contain summaries of a user's activity (or lack of activity). Only the non-obvious fields are described here.

Logs created by older versions of NcFTPd may contain less fields than listed here. In these
cases the missing field(s) will have a value of C<undef>.

=over 4

=item * C<time>

Date & time the connection was closed

=item * C<process>

NcFTPd process ID

=item * C<user>

Username provided for this session. Could contain the value C<REFUSED> or C<DENIED>. See the
NcFTPd docs for more details.

=item * C<email>

=item * C<host>

=item * C<session_time>

The total amount of time the user was logged in, given in seconds

=item * C<time_between_commands>

Given in seconds

=item * C<bytes_retrieved>

=item * C<bytes_stored>

=item * C<number_of_commands>

Number of commands the user sent

=item * C<retrieves>

=item * C<stores>

=item * C<chdirs>

=item * C<nlists>

=item * C<lists>

=item * C<types>

Number of times the user changed the transfer type (i.e binary or ASCII)

=item * C<port_pasv>

Number of C<PORT> and C<PASV> commands

=item * C<pwd>

=item * C<size>

=item * C<mdtm>

Number of file modification time requests

=item * C<site>

=item * C<logins>

Successful logins

=item * C<failed_data_connections>

=item * C<last_transfer_result>

The result of the last transfer for this session, set to one of the following:

C<OK ABOR INCOMPLETE PERM NOENT ERROR>

See the NcFTPd docs for more info: L<http://ncftpd.com/ncftpd/doc/xferlog.html#status>

=item * C<successful_downloads>

=item * C<failed_downloads>

=item * C<successful_uploads>

=item * C<failed_uploads>

=item * C<successful_listings>

=item * C<failed_listings>

=item * C<close_code>

The reason the connection was closed, See L</CLOSE CODES>.

This field can be expand to something more descriptive. See L<< C<expand>|/Arguments >>.

=item * C<session_id>

=back

=head1 CLOSE CODES

Integers describing why the connection was closed. Refer to the NcFTPd documentation: L<http://ncftpd.com/ncftpd/doc/sesslog.html#CloseCodes>

=head1 METHODS

See L<NcFTPd::Log::Parse> for the full documentation.

=head2 new

Create a parser capable of parsing the specified session log:

    $parser = NcFTPd::Log::Parse::Session->new($file, %options)

=head3 Returns

A parser capable of parsing the specified session log.

=head3 Arguments

C<%options>

=over 4

=item * C<< expand => 1|0 >>

=item * C<< expand => [ 'field1', 'field2', ... ] >>

=back

Currently only the C<close_code> field can be expanded. C<1> will expand all fields C<0>, the default, will not expand any.

By default C<close_code> contains an integer value denoting the reason the connection was closed.
Use C<expand> to replace these integers with a meaningful description:

    # Without expand
    print "Closed because: $entry->{close_code}"
    # Closed because: 2

    # With expand
    print "Closed because: $entry->{close_code}"
    # Closed because: Miscellaneous error

=head3 Errors

If a parser cannot be created an error will be raised.

=head1 SEE ALSO

L<NcFTPd::Log::Parse>, L<NcFTPd::Log::Parse::Xfer>, L<NcFTPd::Log::Parse::Misc> and the NcFTPd log file documentation L<http://ncftpd.com/ncftpd/doc/misc>


=head1 AUTHOR

Skye Shaw <sshaw AT lucas.cis.temple.edu>

=head1 COPYRIGHT

Copyright (C) 2011 Skye Shaw

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
