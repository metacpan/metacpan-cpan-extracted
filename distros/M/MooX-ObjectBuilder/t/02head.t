=pod

=encoding utf-8

=head1 PURPOSE

Basic test using a silly aggregated object.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

{
	package Eye;
	use Moo;
	has colour => (is => 'ro');
}

{
	package Eye::Glass;
	use Moo;
	extends qw(Eye);
}

{
	package Mouth;
	use Moo;
}

{
	package Face;
	use Moo;
	use MooX::ObjectBuilder;
	my $mouth_builder = make_builder( Mouth => {} );
	has left_eye   => (is => make_builder( Eye => {eye_colour=>'colour',left_eye_class=>'__CLASS__'} ));
	has right_eye  => (is => make_builder( Eye => {eye_colour=>'colour',right_eye_class=>'__CLASS__'} ));
	has mouth      => (is => 'lazy', builder => $mouth_builder);
	has expression => (is => 'ro');
}

{
	package Hair;
	use Moo;
	has colour => (is => 'ro');
}

{
	package Head;
	use Moo;
	use MooX::ObjectBuilder;
	
	my $ctor = sub { Hair->new(@_) };
	
	has face => (is => make_builder( Face  => [qw/ left_eye_class right_eye_class eye_colour expression /] ));
	has hair => (is => make_builder( $ctor => {hair_colour => 'colour'} ));
}

my $head = Head->new(
	eye_colour  => 'blue',
	hair_colour => 'blonde',
	expression  => 'happy',
	right_eye_class => 'Eye::Glass',
);

isa_ok($head, 'Head', '$head');
isa_ok($head->face, 'Face', '$head->face');
isa_ok($head->face->left_eye, 'Eye', '$head->face->left_eye');
is($head->face->left_eye->colour, 'blue', '$head->face->left_eye->colour');
isa_ok($head->face->right_eye, 'Eye', '$head->face->right_eye');
isa_ok($head->face->right_eye, 'Eye::Glass', '$head->face->right_eye');
is($head->face->right_eye->colour, 'blue', '$head->face->right_eye->colour');
isnt($head->face->left_eye, $head->face->right_eye, '$head->face->left_eye == $head->face->right_eye');
isa_ok($head->face->mouth, 'Mouth', '$head->face->mouth');
is($head->face->expression, 'happy', '$head->face->expression');
isa_ok($head->hair, 'Hair', '$head->hair');
is($head->hair->colour, 'blonde', '$head->hair->colour');

done_testing;
