package TV::Humax::Foxsat;

use 5.10.0;
use strict;
use warnings;

=head1 NAME

TV::Humax::Foxsat - Parse metadata files from your Humax satellite TV receiver.

=head1 VERSION

version 0.06

=cut

our $VERSION = '0.06'; # VERSION

=head1 SYNOPSIS

  use TV::Humax::Foxsat::hmt_data;

  my $hmt_data = new TV::Humax::Foxsat::hmt_data();
  $hmt_data->raw_from_file('/path/to/TV Show_20121007_2159.hmt');

  printf "Recording %s ran from %s till %s on %s (channel %d).\n",
    $hmt_data->progName,
    $hmt_data->startTime,
    $hmt_data->endTime,
    $hmt_data->ChanNameEPG,
    $hmt_data->ChanNum;

  my @epg_records = @{ $hmt_data->EPG_blocks() };
  my $epg_block = pop @epg_records;

  printf "The last show in the recording was of %s starting at %s for %d minutes.\n",
    $epg_block->progName,
    $epg_block->startTime,
    ( $epg_block1->duration / 60 );

  printf "The show description is %s\n", $epg_block->guideInfo;

Hmt files are meta data files used by Humax

NB: There is no support for modifying and saving hmt data files.
You should treat the fields as read only.

=head1 FIELDS

The following fields are available in hmt_data

Numbers/strings: lastPlay ChanNum progName ChanNameEPG AudioType VideoPID
                 AudioPID TeletextPID VideoType EPG_Block_count fileName

Datetime: startTime endTime

Boolean: Freesat Viewed Locked HiDef Encrypted CopyProtect Locked Subtitles

The field EPG_blocks contains the list of electronic program guide data
blocks that are instances of TV::Humax::Foxsat::epg_data

The following fields are avalable in epg_data

startTime duration progName guideInfo guideFlag guideBlockLen

guideInfo is the Long program guide text. Up to 255 bytes

=head1 SUPPORTED DEVICES

This module designed to work with metadata files from Humax's Foxsat receiver,
it is known not to work with files from the HDR-FOX T2 receiver. Other devices
are untested, and may or may not work. Please report any success or otherwise
with other devices.

=head1 AUTHOR

"spudsoup", C<< <"spudsoup at cpan.org"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tv-humax-foxsat at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TV-Humax-Foxsat>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

I would also be interested in any suggestions for improvement you might have.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TV::Humax::Foxsat

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TV-Humax-Foxsat>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TV-Humax-Foxsat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TV-Humax-Foxsat>

=item * Search CPAN

L<http://search.cpan.org/dist/TV-Humax-Foxsat/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 "spudsoup".

This program is released under the following license: gpl --verbose

=cut

1; # End of TV::Humax::Foxsat
