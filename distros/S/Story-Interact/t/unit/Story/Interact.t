=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<Story::Interact>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use Test2::V0 -target => 'Story::Interact';
use Test2::Tools::Spec;
use Data::Dumper;

describe "class `$CLASS`" => sub {

	tests 'blah blah blah' => sub {
	
		pass;
	};
};

done_testing;
