package MooseX::DeclareX::Privacy;
$MooseX::DeclareX::Privacy::AUTHORITY = 'cpan:TOBYINK';
$MooseX::DeclareX::Privacy::VERSION   = '0.006';

__END__

=head1 NAME

MooseX::DeclareX::Privacy - shiny syntax for MooseX::Privacy

=head1 SYNOPSIS

	class Person extends Mammal
	{
		private method decide ($choices) {
			...;
		}
	}

=head1 DESCRIPTION

This distribution adds three new plugins to L<MooseX::DeclareX>.

=over

=item C<< private method >>

A method that can only be called from within this class.

=item C<< protected method >>

A method that can be called from within this class, or from derived classes.

=item C<< public method >>

Essentially a no-op.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-DeclareX-Privacy>.

=head1 SEE ALSO

L<MooseX::DeclareX>, L<MooseX::Privacy>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

