package PerlIO::via::chop;

# Set the version info
# Make sure we do things by the book from now on

$VERSION = '0.01';

use strict;

# Make sure the encoding/decoding stuff is available

1;

sub PUSHED { bless \*PUSHED,$_[0] }
sub FILL { readline( $_[1] ) }

my %buffer;
sub WRITE {
    my $buffer = $buffer{$_[2]};
    if (defined $buffer) {
	print {$_[2]} $buffer;
	print {$_[2]} substr($_[1], 0, -1);
	$buffer{$_[2]} = substr($_[1], -1);
	return length($_[1]);
    }
    else {
	print {$_[2]} substr($_[1], 0, -1);
	$buffer{$_[2]} = substr($_[1], -1);
	return length($_[1]) - 1;
    }
} #WRITE


1;
__END__

=head1 NAME

PerlIO::via::chop - PerlIO layer to chop the last byte outputted

=head1 SYNOPSIS

 use PerlIO::via::chop;

 open( my $in,'<:via(chop)','file.txt' );	# no effect
 open( my $out,'>:via(chop)','file.txt' );	# last byte is chopped

=head1 DESCRIPTION

This module implements a PerlIO layer that chops the last
byte written to the file.

=head1 SEE ALSO

L<PerlIO::via>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2002 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
