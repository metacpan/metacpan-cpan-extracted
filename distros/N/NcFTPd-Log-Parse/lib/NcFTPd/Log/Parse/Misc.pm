package NcFTPd::Log::Parse::Misc;

use strict;
use warnings;
use base 'NcFTPd::Log::Parse::Base';

# Misc logs entries do not need further parsing
sub _parse_entry { { message => $_[1] } }

1;

__END__

=head1 NAME

NcFTPd::Log::Parse::Misc - parse NcFTPd misc logs

=head1 SYNOPSIS

  use NcFTPd::Log::Parse::Misc;
  $parser = NcFTPd::Log::Parse::Misc->new('misc.20100101'); 


  while($line = $parser->next) {
      $line->{time};
      $line->{message};
      # ... 
    }
  }

  # Check for an error, otherwise it was EOF
  if($parser->error) {
    die 'Parsing failed: ' . $parser->error;
  }

=head1 DESCRIPTION

This class is part of the L<NcFTPd::Log::Parse> package. Refer to its documentation for a detailed overview of how this and the other parsers work.

Only C<NcFTPd::Log::Parse::Misc> specific features are described here.

=head1 MISC LOG ENTRIES

=over 4

=item * C<time>

Date & time the connection was closed

=item * C<process>

NcFTPd process ID

=item * C<message>

A message output by NcFTPd

=back 

=head1 METHODS

See L<NcFTPd::Log::Parse> for the full documentation. 

=head1 SEE ALSO

L<NcFTPd::Log::Parse>, L<NcFTPd::Log::Parse::Xfer>, L<NcFTPd::Log::Parse::Session> and the NcFTPd log file documentation L<http://ncftpd.com/ncftpd/doc/misc>

=head1 AUTHOR

Skye Shaw <sshaw AT lucas.cis.temple.edu>

=head1 COPYRIGHT

Copyright (C) 2011 Skye Shaw

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
