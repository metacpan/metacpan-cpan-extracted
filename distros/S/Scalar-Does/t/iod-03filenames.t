=head1 PURPOSE

Check IO::Detect can detect filename-like things.

This file originally formed part of the IO-Detect test suite.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use IO::Detect qw( is_filename FileName );

my @filenames = qw(
	0
	/dev/null
	readme.txt
	README
	C:\Windows\Notepad.exe
	C:\Windows\
);

{
	package Local::Stringifier;
	use overload q[""], sub { $_[0][0] };
	sub new { bless \@_, shift }
}

push @filenames, Local::Stringifier->new(__FILE__);

ok !is_filename([]), 'is_filename ARRAY';
ok !is_filename(undef), 'is_filename undef';
ok !is_filename(''), 'is_filename empty string';
ok !is_filename(<<'FILENAME'), 'is_filename multiline';
multi
line
string
FILENAME

if ($] >= 5.010 and $] < 5.017)
{
	eval q[
		use IO::Detect -smartmatch, -default;
		
		ok(is_filename, "is_filename $_") for @filenames;

		ok not([]    ~~ FileName), 'ARRAY ~~ FileName';
		ok not(undef ~~ FileName), 'undef ~~ FileName';
		ok not(''    ~~ FileName), 'empty string ~~ FileName';

		for (@filenames)
			{ ok $_ ~~ FileName, "$_ ~~ FileName" };
	];
}

done_testing();
