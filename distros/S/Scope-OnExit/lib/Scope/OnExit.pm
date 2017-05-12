package Scope::OnExit;

use strict;
use warnings;
use base qw/Exporter DynaLoader/;

our $VERSION = '0.02';

bootstrap Scope::OnExit $VERSION;

##no critic ProhibitAutomaticExportation
our @EXPORT = qw/on_scope_exit/;

1;    # End of Scope::OnExit

__END__

=head1 NAME

Scope::OnExit - Running code on scope exit

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Execute code on scope exit

    use Scope::OnExit;

	{
	my $var = foo();
	on_scope_exit { do_something($var) };
	something_else();
	} # scope exit, do_something($var) is run now.

=head1 FUNCTIONS

=head2 on_scope_exit { block }

This will make the block run at scope exit. 

=head1 AUTHOR

Leon Timmermans, C<< <leont at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-scope-onexit at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Scope-OnExit>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Scope::OnExit

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Scope-OnExit>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Scope-OnExit>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Scope-OnExit>

=item * Search CPAN

L<http://search.cpan.org/dist/Scope-OnExit>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Leon Timmermans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
