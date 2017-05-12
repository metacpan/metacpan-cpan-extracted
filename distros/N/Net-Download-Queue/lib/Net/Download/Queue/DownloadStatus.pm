=head1 NAME

Net::Download::Queue::DownloadStatus

=head1 SYNOPSIS


=cut





package Net::Download::Queue::DownloadStatus;
use base 'Net::Download::Queue::DBI';



our $VERSION = Net::Download::Queue::DBI::VERSION;



use strict;
use Data::Dumper;





__PACKAGE__->set_up_table('download_status');





1;





__END__

=head1 AUTHOR

Johan Lindstrom, C<< <johanl@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-download-queue@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Download-Queue>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
