package Net::Dynect::REST::LOCRecord;
# $Id: LOCRecord.pm 149 2010-09-26 01:33:15Z james $
use strict;
use warnings;
use Net::Dynect::REST::ResourceRecord;
our @ISA = ("Net::Dynect::REST::ResourceRecord");
our $VERSION = do { my @r = (q$Revision: 149 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub _service_base_uri {
  return "LOCRecord";
}

=head1 NAME

Net::Dynect::REST::LOCRecord - Location Record

=head1 AUTHOR

James Bromberger, james@rcpt.to

=head1 SEE ALSO

L<Net::Dynect::REST>, L<Net::Dynect::REST::Request>, L<Net::Dynect::REST::Response>, L<Net::Dynect::REST::ResourceRecord>, L<Net::Dynect::REST::info>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by James Bromberger

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.10.1 or, at your option, any later version of Perl 5 you may have available.

=cut


1;
