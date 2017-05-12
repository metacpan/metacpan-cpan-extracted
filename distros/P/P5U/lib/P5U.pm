package P5U;

use 5.010;
use utf8;

use App::Cmd::Setup -app;
use Object::AUTHORITY;

BEGIN {
	$P5U::AUTHORITY = 'cpan:TOBYINK';
	$P5U::VERSION   = '0.100';
};

__PACKAGE__
__END__

=head1 NAME

P5U - utilities for Perl 5 development and administration

=head1 SYNOPSIS

 use P5U;
 P5U->run;

=head1 DESCRIPTION

This is the module supporting the C<p5u> command-line tool.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=P5U>.

=head1 SEE ALSO

L<p5u>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

