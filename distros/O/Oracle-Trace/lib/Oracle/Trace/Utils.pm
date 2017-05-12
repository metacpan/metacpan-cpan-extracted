#
# $Id: Utils.pm,v 1.3 2003/12/24 20:38:54 oratrc Exp $
#
package Oracle::Trace::Utils;

use 5.008001;
use strict;
use warnings;
use Data::Dumper;

our $VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

my $DEBUG = $ENV{Oracle_Trace_DEBUG} || 0;

=item fatal

Die with a message

	$o_util->fatal($msg);

=cut

sub fatal {
	shift;
	die(@_);
};

=item error

Warn with a message

	$o_util->warn($msg);

=cut

sub error {
	shift;
	warn(@_);
};

=item debug 

Exude a debugging message.

	$o_util->debug($msg) if $DEBUG >= 2;

=cut


sub debug {
	my $self = shift;
	print(ref($self).": @_\n");
};

1;
__END__

=head1 NAME

Oracle::Trace::Utils - Perl Module for Oracle Trace Utilities 

=head1 SYNOPSIS

	use Oracle::Trace::Utils;

	@ISA = qw(Oracle::Trace::Utils);

	$o_obj->debug($message);	

=head1 DESCRIPTION

Module for Oracle Trace Utils.

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
