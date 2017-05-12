#
# $Id: Footer.pm,v 1.8 2003/12/24 20:38:54 oratrc Exp $
#
package Oracle::Trace::Footer;

use 5.008001;
use strict;
use warnings;
use Data::Dumper;
use Oracle::Trace::Entry;

our @ISA = qw(Oracle::Trace::Entry);

our $VERSION = do { my @r = (q$Revision: 1.8 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

my $DEBUG = $ENV{Oracle_Trace_DEBUG} || 0;

# Chunk

sub parse {
	my $self = shift;
	my $data = shift;
	$self->debug("incoming: ".Dumper($data)) if $DEBUG >= 3;
	my $i_line = 0;
	if ($data) {
		LINE:
		foreach my $line (split("\n", $data)) {
			$self->debug("line[".$i_line."] $line") if $DEBUG >= 2;
			$i_line++;
			next LINE if $line =~ /^\*\*\*\s+\d+/;
			push @{$self->{_data}{other}}, $line;
		}
	}
	$self->debug("lines read: $i_line") if $DEBUG;
	return $self;
}

1;
__END__

=head1 NAME

Oracle::Trace::Footer - Perl Module for parsing Oracle Trace Footers

=head1 SYNOPSIS

  use Oracle::Trace::Footer;

  my $o_ftr = Oracle::Trace::Footer->new($string)->parse;

  print "Footer info: ".join("\n", $o_ftr->statement;

=head1 DESCRIPTION

Module to parse Oracle Trace Footers.

=head2 EXPORT

None by default.


=head1 SEE ALSO

	http://www.rfi.net/oracle/trace/

=head1 AUTHOR

Richard Foley, E<lt>oracle.trace@rfi.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 by Richard Foley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
