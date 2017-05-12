package PerlIO::tee;
use strict;
require PerlIO::Util;
1;
__END__

=encoding utf-8

=head1 NAME

PerlIO::tee - Multiplex output layer

=for test_synopsis my($file, @sources, $scalar);

=head1 SYNOPSIS

	open my $out, '>>:tee', $file, @sources;

	$out->push_layer(tee => $file);
	$out->push_layer(tee => ">> $file");
	$out->push_layer(tee => \$scalar);
	$out->push_layer(tee => \*FILEHANDLE);

=head1 DESCRIPTION

C<PerlIO::tee> provides a multiplex output stream like C<tee(1)>.
It makes a filehandle write to one or more files (or
scalars via the C<:scalar> layer) at the same time.

You can use C<push_layer()> (defined in C<PerlIO::Util>) to add a I<source>
to a filehandle. The I<source> may be a file name, a scalar reference, or a
filehandle. For example:

	$fh->push_layer(tee => $file);    # meaning "> $file"
	$fh->push_layer(tee => ">>$file");# append mode
	$fh->push_layer(tee => \$scalar); # via :scalar
	$fh->push_layer(tee => \*OUT);    # shallow copy, not duplication

You can also use C<open()> with multiple arguments.
However, it is just a syntax sugar to call C<push_layer()>: One C<:tee>
layer has a single extra output stream, so arguments C<$x, $y, $z> of C<open()>,
for example, prepares a filehandle with one default layer and two C<:tee>
layers with a internal output stream.

	open my $tee, '>:tee', $x, $y, $z;
	# the code above means:
	#   open my $tee, '>', $x;
	#   $tee->push_layer(tee => $y);
	#   $tee->push_layer(tee => $z);

	$tee->get_layers(); # => "perlio", "tee($y)", "tee($z)"

	$tee->pop_layer();  # "tee($z)" is popped
	$tee->pop_layer();  # "tee($y)" is popped
	# now $tee is a filehandle only to $x


=head1 EXAMPLE

Here is a minimal implementation of C<tee(1)>.

	#!/usr/bin/perl -w
	# Usage: $0 files...
	use strict;
	use PerlIO::Util;

	*STDOUT->push_layer(tee => $_) for @ARGV;

	while(read STDIN, $_, 2**12){
		print;
	}
	__END__


=head1 SEE ALSO

L<PerlIO::Util>.

=head1 AUTHOR

Goro Fuji (藤 吾郎) E<lt>gfuji (at) cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Goro Fuji E<lt>gfuji (at) cpan.orgE<gt>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
