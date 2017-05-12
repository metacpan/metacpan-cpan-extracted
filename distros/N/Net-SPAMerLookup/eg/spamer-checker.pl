#!/usr/bin/perl -W
#
# Masatoshi Mizuno E<lt>lusheE(<64>)cpan.orgE<gt>
#
use strict;
use warnings;
use lib qw(./lib ../lib);
use Pod::Usage;

BEGIN {
  $ENV{TLD_MOZILLA_TEMP}= '.';
  };

use Net::SPAMerLookup qw/
 all.rbl.jp
 url.rbl.jp
 dyndns.rbl.jp
 notop.rbl.jp
 bl.spamcop.net
 list.dsbl.org
 sbl-xbl.spamhaus.org
 bsb.empty.us
 bsb.spamlookup.net
 niku.2ch.net
 /;

our $VERSION= '0.01';

print <<END_INFO;
Net::SPAMerLookup Ver@{[ Net::SPAMerLookup->VERSION ]}

END_INFO

if (my $args= shift @ARGV) {
	my $spam= Net::SPAMerLookup->new;
	my $method= @ARGV ? 'is_spamer' : 'check_rbl';
	if (my $result= $spam->$method($args, @ARGV)) {
		print <<END_INFO;
It is judged SPAMer.

RBL-Server: $result->{RBL}

@{[ $result->{name} ? qq{Name: $result->{name}}: qq{Address: $result->{address}} ]}

@{[ join "\n", @{$result->{result}} ]}

END_INFO
	} else {
		print "There is no problem.\n\n";
	}

} else {
	print pod2usage(2);
}

1;

__END__

=head1 NAME

Net::SPAMerLookup - Perl module to judge SPAMer.

=head1 SYNOPSIS

  % perl spamer-cheker.pl http://wwww.hogehoge.spamer/
  % perl spamer-cheker.pl boooo@hogehoge.spamer
  % perl spamer-cheker.pl hogehoge.spamer
  % perl spamer-cheker.pl 1XX.22.33.44

=head1 SEE ALSO

L<Net::SPAMerLookup>;

=head1 AUTHOR

Masatoshi Mizuno E<lt>lushe(E<64>)cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Bee Flag, Corp. E<lt>http://egg.bomcity.com/E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

