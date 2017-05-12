package NcFTPd::Log::Parse;

use strict;
use warnings;
use vars qw{$VERSION};

use File::Basename;
use Carp;
use NcFTPd::Log::Parse::Misc;
use NcFTPd::Log::Parse::Session;
use NcFTPd::Log::Parse::Xfer;

$VERSION = '0.001';

my %PARSERS = (
    xfer => 'NcFTPd::Log::Parse::Xfer',
    sess => 'NcFTPd::Log::Parse::Session',
    misc => 'NcFTPd::Log::Parse::Misc'
);

$PARSERS{session} = $PARSERS{sess};

sub new
{
    my $class = shift;
    croak 'usage: NcFTP::Log::Parse->new($file [, %options ] | %options)' unless @_;

    my $file    = shift if @_ % 2;
    my %options = @_;
    my $parser;

    if(defined $file) {
	my $basename      = basename($file);
	my $known_parsers = join '|', keys %PARSERS;
	if($basename =~ /^($known_parsers)/i) {
	    $parser = $PARSERS{lc $1};
	}
    }
    else {
	for my $format (keys %PARSERS) {
	    if(defined $options{$format}) {
		$file   = $options{$format};
		$parser = $PARSERS{$format};
		last;		    
	    }
	}
    }

    croak 'Cannot determine what parser to use, try setting it explicitly' unless $parser;

    $parser->new($file, %options);
}

1;

__END__

=head1 NAME

NcFTPd::Log::Parse - parse NcFTPd xfer, session, and misc logs

=head1 SYNOPSIS

  use NcFTPd::Log::Parse;
  $parser = NcFTPd::Log::Parse->new(xfer => 'xfer.20100101'); # Parse a xfer log
  $parser = NcFTPd::Log::Parse::Xfer->new('xfer.20100101');   # Same as above

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

  $parser = NcFTPd::Log::Parse->new(xfer   => 'xfer.20100101', 
				    expand => 1,  	    
				    filter => sub { $_->{user} eq 'sshaw' });
  $line = $parser->next;
  $line->{operation}   # Expanded 'S' to 'store'
  $line->{notes}       # Expanded 'SfPs' to ['Used sendfile', 'PASV connection']

  # Load parser based on the log's name (using NcFTPd's default log names)
  $parser = NcFTPd::Log::Parse->new('xfer.20100101');  
  $parser = NcFTPd::Log::Parse->new('session.20100101'); 
  
=head1 DESCRIPTION
 
The C<NcFTPd::Log::Parse> package is composed of 3 parsers:

=over 2

=item L<NcFTPd::Log::Parse::Xfer>

=item L<NcFTPd::Log::Parse::Misc>

=item L<NcFTPd::Log::Parse::Session>

=back

A parser can be created via the factory class C<NcFTPd::Log::Parse>:

    $parser = NcFTPd::Log::Parse->new(xfer => 'ftp.log')

Or it can be created directly:

    $parser = NcFTPd::Log::Parse::Xfer->new('ftp.log')

Options can be provided to both calls to L<< C<new>|/new >> via a hash:

    $parser = NcFTPd::Log::Parse->new(xfer   => 'ftp.log', 
				      expand => 1, 
				      filter => sub { ... })

Lines are parsed on demand by calling the L<< C<next>|/next >> method:

    $entry = $parser->next

Each call to C<next> returns a hash reference. 

On error and EOF C<undef> is returned. In order to discern between the two you must 
check the L<< C<error>|/error >> method:

    if($parser->error) {
       # it wasn't EOF
    } 
 
=head1 METHODS

=head2 new

Create a parser capable of parsing the specified file. The file must be a path to 
a NcFTPd misc, session, or xfer file:

    $parser = NcFTPd::Log::Parse->new($file, %options)
    $parser = NcFTPd::Log::Parse->new(xfer => $file, %options)

=head3 Returns

A parser capable of parsing the specified file. 

=head3 Arguments

C<$file>

The file to parse can be given as a single argument:

    $parser = NcFTPd::Log::Parse->new('session.log', %options)

Or as a part of the options hash, where the key is the log type and the value is the path to a log:

    $parser = NcFTPd::Log::Parse->new(xfer => 'ftp.log', %options);    

When C<$file> is given as a single argument an attempt is made to create the correct 
parser based on the filename's prefix. These prefixes are based on NcFTPd defaults.

C<%options>

=over 4

=item * C<< xfer => $file >>

Create a L<xfer log parser|NcFTPd::Log::Parse::Xfer> for the given file

=item * C<< sess => $file >>

=item * C<< session => $file >> 

Create a L<session log parser|NcFTPd::Log::Parse::Session> for the given file

=item * C<< misc => $file >> 

Create a L<misc log parser|NcFTPd::Log::Parse::Misc> for the given file

=item * C<< filter => sub { ... } >>

Only return entries that match the filter. By default all entries are returned. 

If the sub reference returns true the entry will be kept, otherwise it's skipped and
the next line in the file is parsed. The current entry is provided to the sub as a hash reference (its parsed form) via the C<$_> variable:

    filter => sub { 
	# Uploads by a_user
        $_->{user} eq 'a_user' &&
	$_->{operation} eq 'S'
    }

=item * C<< expand => 1|0 >> 

=item * C<< expand => [ 'field1', 'field2', ... ] >> 

Expand all "expandable" entries, or just the "expandable" entries named in the array reference. 
Defaults to C<0>, no entries are expanded.

A few types of log entries have cryptic fields. This option will expand these to something you can understand without having
to refer to the NcFTPd docs. A value of C<1> will expand all "expandable" fields, C<0> will not expand any.  
You can also provide an C<ARRAY> ref containing fields to expand. 

Check the parser specific documentation to see what's expanded.

=back

=head3 Errors

If a parser cannot be created an error will be raised. 

=head2 next

Parse and return the next entry in the log or, if a C<filter> been provided, the next entry matching the filter. 

=head3 Returns

On success a hash reference is returned. The keys are dependent upon the type of log being parsed, see the 
L<log specific parser documentation|/NcFTPd::Log::Parse::Xfer> for details. 

On error C<undef> is returned. Call L<< C<error>|/error >> retrieve the reason for the failure.

=head3 Arguments

None

=head2 error
  
Enquire why the last call to  L<< C<next>|/next >> failed. 

=head3 Returns

A string containing the error or an empty string if there wasn't an error.

=head3 Arguments

None

=head1 SEE ALSO

L<NcFTPd::Log::Parse::Xfer>, L<NcFTPd::Log::Parse::Session>, L<NcFTPd::Log::Parse::Misc> and 
the NcFTPd documentation L<http://ncftpd.com/ncftpd/doc/misc>

=head1 AUTHOR

Skye Shaw <sshaw AT lucas.cis.temple.edu>

=head1 COPYRIGHT

Copyright (C) 2011 Skye Shaw

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
