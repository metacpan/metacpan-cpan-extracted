package NcFTPd::Log::Parse::Xfer;

use strict;
use warnings;
use base 'NcFTPd::Log::Parse::Base';

# Field names
use constant {
    DESTINATION	      => 'destination',
    DURATION	      => 'duration',
    EMAIL	      => 'email',
    HOST	      => 'host',
    MODE	      => 'mode',
    NOTES             => 'notes',
    OPERATION	      => 'operation',
    PATHNAME	      => 'pathname',
    PATTERN	      => 'pattern',
    RATE              => 'rate',
    RECURSION         => 'recursion',
    RESERVED1	      => 'reserved1',
    RESERVED2	      => 'reserved2',
    RESERVED3	      => 'reserved3',
    SESSION_ID	      => 'session_id',
    SIZE              => 'size',
    SOURCE	      => 'source',
    START_OF_TRANSFER => 'start_of_transfer',
    STARTING_OFFSET   => 'starting_offset',
    STARTING_SIZE     => 'starting_size',
    STATUS	      => 'status',
    SUFFIX            => 'suffix',
    # Transfer type, binary or ascii
    TYPE              => 'type',
    USER              => 'user'
};

my %TRANSFER_NOTES = (
    Df => 'FTP default data connection was used', 
    Po => 'PORT connection',
    Ps => 'PASV connection',
    Mm => 'Used memory mapped I/O',
    Bl => 'Used block transfer mode',
    Sf => 'Used sendfile',
    # These are not documented but they show up in store/retrieve entries
    Ap => 'Unknown',
    Rz => 'Unknown'
);

my @TRANSFER_STATUSES = __PACKAGE__->_transfer_statuses;
my %COMMON_REGEX = __PACKAGE__->_common_regex;

$COMMON_REGEX{optdigit} = '-1|\d+';
$COMMON_REGEX{notes} = join '|', keys %TRANSFER_NOTES;

# Log entry definitions
my $CHMOD = {
    name   => 'chmod',
    fields => [ PATHNAME, MODE, RESERVED1, RESERVED2, USER, EMAIL, HOST, SESSION_ID ],
    regex  => qr{
	(.+),
	(\d{3}),   # Permissions
	(.*?),     # Reserved
	(.*?),     # Reserved
	(.+),      # User
	(.*?),     # "Email" (anonymous login password)
	(.+),      # "Host"
	($COMMON_REGEX{session}),
    }x
};

my $DELETE = {
    name   => 'delete',
    fields => [ PATHNAME, RESERVED1, RESERVED2, RESERVED3, USER, EMAIL, HOST, SESSION_ID ],
    regex  => qr{
	(.+),     # Path of target
	(.*?),    # Reserved
	(.*?),    # Reserved
	(.*?),    # Reserved
	(.+),     # User
	(.*?),    # "Email" (anonymous login password)
	(.+),     # Host
	($COMMON_REGEX{session}), # Session
    }x
};

my $LINK = {
    name   => 'link',
    fields => [ SOURCE, RESERVED1, DESTINATION, RESERVED2, USER, EMAIL, HOST, SESSION_ID ],
    regex  => qr{
	(.+),     # Path of existing file
	(to),     # Reserved, hardcoded to "to"
	(.+),     # Path of linked file
	(.*?),    # Reserved
	(.+),     # User
	(.*?),    # "Email" (anonymous login password)
	(.+),     # Host
	($COMMON_REGEX{session}),
    }x
};

my $LIST = {
    name   => 'listing',
    fields => [ PATHNAME, STATUS, PATTERN, RECURSION, USER, EMAIL, HOST, SESSION_ID ],
    regex  => qr{
	(.+),			  # Path
	($COMMON_REGEX{status}),  # Transfer status
	(.*?),			  # Filter pattern
	((?:RECURSIVE)?),	  # Recursive directory transversial
	(.+),			  # User
	(.*?),			  # "Email" (anonymous login password)
	(.+),			  # Host
	($COMMON_REGEX{session}),
    }x
};

my $STORE = {
    name   => 'store',
    fields => [ PATHNAME, SIZE, DURATION, RATE, USER, EMAIL, HOST, SUFFIX, STATUS,
		TYPE, NOTES, START_OF_TRANSFER, SESSION_ID, STARTING_SIZE, STARTING_OFFSET ],
    regex => qr{
	(.+),		   	   # Path
	(\d+),		   	   # Size
	($COMMON_REGEX{decimal}),  # Durtaion
	($COMMON_REGEX{decimal}),  # Transfer rate
	(.+),		   	   # User
	(.*?),		   	   # Email
	(.+),		   	   # Peer
	((?:\.\w+)?),		   # Content "translation" (file extention)
	($COMMON_REGEX{status}),   # Transfer status
	(A|I),			   # FTP transfer mode
	((?:$COMMON_REGEX{notes})*?), # Notes about the transfer
	(\d+)			      # Start of transfer
	#optional, added in later version
	(?:,
	  ($COMMON_REGEX{session}),
	  ($COMMON_REGEX{optdigit}), # File size at start of the transfer
	  ($COMMON_REGEX{optdigit}), # Position of file start of the transfer
	)?
    }x
};

my $MKDIR = {
    name   => 'mkdir',
    fields => $DELETE->{fields},
    regex  => $DELETE->{regex}
};

my $RENAME = {
    name   => 'rename',
    fields => $LINK->{fields},
    regex  => $LINK->{regex}
};

my $RETRIEVE = {
    name   => 'retrieve',
    fields => $STORE->{fields},
    regex  => $STORE->{regex}
};

my %LOG_ENTRIES = (
    C => $CHMOD,
    D => $DELETE,
    L => $LINK,
    M => $MKDIR,
    N => $RENAME,
    R => $RETRIEVE,
    S => $STORE,
    T => $LIST
);

sub _expand_field
{
    my ($self, $name, $value) = @_;

    if($name eq OPERATION) {
	$value = $LOG_ENTRIES{$value}->{name};
    }
    elsif($name eq NOTES) {
	my @notes = grep length, split /($COMMON_REGEX{notes})/, $value;
	$value = [ map $TRANSFER_NOTES{$_}, @notes ];
    }

    $value;
}

sub _parse_entry
{
    my ($self, $fields) = @_;

    return unless $fields and $fields =~ /^(\w),(.+)/;

    my $op = $1;
    my $details = $2;
    my $entry;

    #TODO: Provide line number on error
    if(!defined $LOG_ENTRIES{$op}) {
	$self->{error} = "Unknown operation '$op'";
    }
    else {
	my @keys = @{$LOG_ENTRIES{$op}->{fields}};
	my @values = $details =~ $LOG_ENTRIES{$op}->{regex};

	#print "R: $LOG_ENTRIES{$op}->{regex}\n $details\n";

	if(@values) {
	  $entry->{&OPERATION} = $op;
	  @$entry{@keys} = @values;
	}
	else {
	  $self->{error} = "Unrecognized format for line: $fields";
	}
    }

    $entry;
}

1;


__END__

=head1 NAME

NcFTPd::Log::Parse::Xfer - parse NcFTPd xfer logs

=head1 SYNOPSIS

  use NcFTPd::Log::Parse::Xfer;
  $parser = NcFTPd::Log::Parse::Xfer->new('xfer.20100101');


  while($line = $parser->next) {
    if($line->{operation} eq 'S') {
      print 'Upload';
      $line->{pathname};
      $line->{size};
      # ...
    }
  }

  # Check for an error, otherwise it was EOF
  if($parser->error) {
    die 'Parsing failed: ' . $parser->error;
  }

=head1 DESCRIPTION

This class is part of the L<NcFTPd::Log::Parse> package. Refer to its documentation for a detailed
overview of how this and the other parsers work.

Only C<NcFTPd::Log::Parse::Xfer> specific features are described here.

=head1 XFER LOG ENTRIES

Parsed Xfer log entries are returned as hash references whose keys are dependent on the entry's C<operation>.
Operations are described below.

Logs created by older versions of NcFTPd may contain less fields than listed here. In these cases the
missing field(s) will have a value of C<undef>.

Only the non-obvious fields are described.

=head2 chmod

chmod entries have an C<operation> code of C<C>

=over 4

=item * C<time>

Date & time the entry occured

=item * C<process>

NcFTPd process ID

=item * C<operation>

Operation code for the type of activity this entry represents, set to C<C>

=item * C<pathname>

=item * C<mode>

Unix style permissions set on C<pathname> by this operation

=item * C<reserved1>

NcFTPd reserved field (empty string)

=item * C<reserved2>

NcFTPd reserved field (empty string)

=item * C<user>

=item * C<email>

Anonymous user's password, NcFTPd refers to this as email

=item * C<host>

=item * C<session_id>

=back

=head2 delete

delete entries have an C<operation> code of C<D>

=over 4

=item * C<time>

Date & time the entry occured

=item * C<process>

NcFTPd process ID

=item * C<operation>

Operation code for the type of activity this entry represents, set to C<D>

=item * C<pathname>

=item * C<reserved1>

NcFTPd reserved field (empty string)

=item * C<reserved2>

NcFTPd reserved field (empty string)

=item * C<reserved3>

NcFTPd reserved field (empty string)

=item * C<user>

=item * C<email>

Anonymous user's password, NcFTPd refers to this as email

=item * C<host>

=item * C<session_id>

=back

=head2 link

link entries have an C<operation> code of C<L>

=over 4

=item * C<time>

Date & time the entry occured

=item * C<process>

NcFTPd process ID

=item * C<operation>

Operation code for the type of activity this entry represents, set to C<L>

=item * C<source>

Path of the file used to create the link

=item * C<reserved1>

NcFTPd reserved field, always set to C<to>

=item * C<destination>

Path of the link

=item * C<reserved2>

=item * C<user>

=item * C<email>

Anonymous user's password, NcFTPd refers to this as email

=item * C<host>

=item * C<session_id>

=back

=head2 listing

Directory listing entries have an C<operation> code of C<T>

=over 4

=item * C<time>

Date & time the entry occured

=item * C<process>

NcFTPd process ID

=item * C<operation>

Operation code for the type of activity this entry represents, set to C<T>

=item * C<pathname>

=item * C<status>

Set to one of the following:

C<OK ABOR INCOMPLETE PERM NOENT ERROR>

=item * C<pattern>

=item * C<recursion>

Set to C<RECURSIVE> if this was a recursive listing, an empty string otherwise

=item * C<user>

=item * C<email>

Anonymous user's password, NcFTPd refers to this as email

=item * C<host>

=item * C<session_id>

=back

=head2 mkdir

Mkdir entries have an C<operation> code of C<M>. The fields are the same as the L<delete operation's|/delete>.

=head2 rename

Rename entries have an C<operation> code of C<N>. The fields are the same as the L<link operation's|/link>.

=head2 retrieve

Retrieve entries (downloads) have an C<operation> code of C<R>. The fields are the same as the L<store operation's|/store>.

=head2 store

Store entries (uploads) have an C<operation> code of C<S>

=over 4

=item * C<time>

Date & time the entry occured

=item * C<process>

NcFTPd process ID

=item * C<operation>

Operation code for the type of activity this entry represents, set to C<S>

=item * C<pathname>

=item * C<size>

The number of bytes transfered

=item * C<durtaion>

Length of the operation in seconds

=item * C<rate>

Kbps transfer rate

=item * C<user>

=item * C<email>

Anonymous user's password, NcFTPd refers to this as email

=item * C<host>

=item * C<suffix>

NcFTPd can create archives on the fly. If one was created, this field contains the archive's extention.

=item * C<status>

Set to one of the following:

C<OK ABOR INCOMPLETE PERM NOENT ERROR>

See the NcFTPd docs for more info: L<http://ncftpd.com/ncftpd/doc/xferlog.html#status>

=item * C<type>

Binary or ASCII transfer, C<A> or C<I>

=item * C<notes>

A string of codes providing additional details about the operation. The field can be
L<expanded|/Arguments> into something descriptive.

=item * C<start_of_transfer>

Unix timestamp denoting the start of the transfer

=item * C<session_id>

=item * C<starting_size>

Size of the file when the transfer started, C<-1> if unknown

=item * C<starting_offset>

File offset where the transfer began, C<-1> if unknown

=back



=head1 METHODS

See L<NcFTPd::Log::Parse> for the full documentation.

=head2 new

Create a parser capable of parsing the specified xfer log:

    $parser = NcFTPd::Log::Parse::Xfer->new($file, %options)

=head3 Returns

A parser capable of parsing the specified xfer log.

=head3 Arguments

C<%options>

=over 4

=item * C<< expand => 1|0 >>

=item * C<< expand => [ 'field1', 'field2', ... ] >>

Currently only the C<operation> and C<notes> fields can be expanded. C<1> will expand all fields C<0>, the default, will not expand any.

An entry's C<operation> field is a single character denoting type of log entry (see L</XFER LOG ENTRIES>). Use C<expand> to replace
this with a meaningful one word description:

    # Without expand
    print "Op: $entry->{operation}"
    Op: T

    # With expand
    print "Op: $entry->{operation}"
    Op: listing

An entry's C<notes> field can contain a string of multiple character codes. These codes can provide additional details about
the operation. Use C<expand> to replace this string of codes with an array reference of meaningfull descriptions:

    # Without expand
    print "Notes: $entry->{notes}"
    Notes: SfPs

    # With expand
    print 'Notes: ', join(', ', @{$entry->{notes}})
    Notes: Used sendfile, PASV connection

=item * C<< filter => sub { ... } >>

See C<filter>'s documentation under L<NcFTPd::Log::Parse/new>

=back

=head3 Errors

If a parser cannot be created an error will be raised.

=head1 SEE ALSO

L<NcFTPd::Log::Parse>, L<NcFTPd::Log::Parse::Session>, L<NcFTPd::Log::Parse::Misc> and the NcFTPd log file documentation L<http://ncftpd.com/ncftpd/doc/misc>

=head1 AUTHOR

Skye Shaw <sshaw AT lucas.cis.temple.edu>

=head1 COPYRIGHT

Copyright (C) 2011 Skye Shaw

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
