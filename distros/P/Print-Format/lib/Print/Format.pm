package Print::Format;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Print::Format', $VERSION);

1;

__END__

=head1 NAME

Print::Format - Responsive 'format'

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Print::Format qw/form/;

	form my $STDOUT => q{
		|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||100
		Bug Reports
		@<<<<<<<<<<<<<<<<<<<<<<<40 @|||||||||||||20 @>>>>>>>>>>>>>>>40
		$system              	   $number    	    $date
		***********************************************************100
		-
		<<<<<<<<<<<<<<20. @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<80,
		Subject: $subject
		<<<<<20. @<<<<<<<<<<<<<<<<<<<<<<<40 ^<<<<<<<<<<<<<<<<<<<<<<<40
		Index:   $index                      $description
		<<<<<20. @<<<<<<10 >>>>>>20. @<<<<10 ^<<<<<<<<<<<<<<<<<<<<<<40
		Priority: $priority     Date: $date  $description
		<<<<<<<<<<<<<<<<<<<<<30 ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<70 ~~
		$description
		***********************************************************100
		=
		<<2 @||||||||||24 @||||||||||24 @|||||||||24 @||||||||||24 >>2
		| @headers[|] |
		***********************************************************100
		=
		<2 @<<<<<<<<<<24~~ @<<<<<<<<24~~ @<<<<<<<<24~~ @<<<<<<<24~~ >2 ~~
		| @rows[|] |
		***********************************************************100
		=
	};

or

	form my $STDOUT => q{
		|100
		Bug Reports
		@<40 @|20 @>40
		$system $number $date
		*100
		-
		<20. @<80
		Subject: $subject
		<20. @<40 ^<40
		Index:   $index                      $description
		<20. @<10 >20. @<10 ^<40
		Priority: $priority     Date: $date  $description
		<30 ^<70 ~~
		$description
		*100
		=
		<2 @|24 @|24 @|24 @|24 >2
		| @headers[|] |
		*100
		=
		<2 @<24~~ @<24~~ @<24~~ @<24~~ >2 ~~
		| @rows[|] |
		*100
		=
	};

then

	open $STDOUT, '>', STDOUT, 100;

	print $STDOUT (
		system => 'Some System',
		number => 100,
		date => '20251201',
		rows => [
			['one', 'two', 'three', 'four'],
			...
		]
		...
	);

will print something like:

						    Bug Reports
	Some System                                     100                                         20251201
	----------------------------------------------------------------------------------------------------
	Subject:This is the subject of the line that should get cut off if long enough but we will keep
	Index:123                                                   This is the description of the bug repor
	Priority:High                                Date:20251201  t that should span multiple lines, This
				      is the description of the bug report that should span multiple lines.
				      This is the description of the bug report that should span multiple li
				      nes. This is the description of the bug report that should span multip
				      le lines. This is the description of the bug report that should span m
				      ultiple lines.	
	====================================================================================================
	|           one           |          two          |         three         |          four          |
	====================================================================================================
	| abc                     | def                   | ghi                   | jkl                    |
	| 1                       | 2                     | 3                     | 4                      |
	| a                       | b                     | c                     | d                      |
	====================================================================================================

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-print-format at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Print-Format>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Print::Format


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Print-Format>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Print-Format>

=item * Search CPAN

L<https://metacpan.org/release/Print-Format>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Print::Format
