package Test::Data::Hash;
use strict;

use Exporter qw(import);

our @EXPORT = qw(exists_ok not_exists_ok
	hash_value_defined_ok hash_value_undef_ok
	hash_value_true_ok hash_value_false_ok);

our $VERSION = '1.241';

use Test::Builder;
my $Test = Test::Builder->new();

=encoding utf8

=head1 NAME

Test::Data::Hash -- test functions for hash variables

=head1 SYNOPSIS

	use Test::Data qw(Hash);

=head1 DESCRIPTION

This modules provides a collection of test utilities for
hash variables.  Load the module through Test::Data.

=head2 Functions

=over 4

=item exists_ok( KEY, HASH [, NAME] )

Ok if the value for KEY in HASH exists.  The function
does not create KEY in HASH.

=cut

sub exists_ok($\%;$)
	{
	my $key  = shift;
	my $hash = shift;
	my $name = shift || "Hash key [$key] exists";

	$Test->ok( exists $hash->{$key}, $name );
	}

=item not_exists_ok( KEY, HASH [, NAME] )

Ok if the value for KEY in HASH does not exist.  The function
does not create KEY in HASH.

=cut

sub not_exists_ok($\%;$)
	{
	my $key  = shift;
	my $hash = shift;
	my $name = shift || "Hash key [$key] does not exist";

	$Test->ok( exists $hash->{$key} ? 0 : 1, $name );
	}

=item hash_value_defined_ok( KEY, HASH [, NAME] )

Ok if the value for KEY in HASH is defined.  The function
does not create KEY in HASH.

=cut

sub hash_value_defined_ok($\%;$)
	{
	my $key  = shift;
	my $hash = shift;
	my $name = shift || "Hash value for key [$key] is defined";

	$Test->ok( defined $hash->{$key}, $name );
	}

=item hash_value_undef_ok( KEY, HASH [, NAME] )

Ok if the value for KEY in HASH is undefined.  The function
does not create KEY in HASH.

=cut

sub hash_value_undef_ok($\%;$) {
	my $key  = shift;
	my $hash = shift;
	my $name = shift || "Hash value for key [$key] is undef";

	$Test->ok( defined $hash->{$key} ? 0 : 1, $name );
	}

=item hash_value_true_ok( KEY, HASH [, NAME] )

Ok if the value for KEY in HASH is true.  The function
does not create KEY in HASH.

=cut

sub hash_value_true_ok($\%;$) {
	my $key  = shift;
	my $hash = shift;
	my $name = shift || "Hash value for key [$key] is true";

	$Test->ok( $hash->{$key}, $name );
	}

=item hash_value_false_ok( KEY, HASH [, NAME] )

Ok if the value for KEY in HASH is false.  The function
does not create KEY in HASH.

=cut

sub hash_value_false_ok($\%;$) {
	my $key  = shift;
	my $hash = shift;
	my $name = shift || "Hash value for key [$key] is false";

	$Test->ok( $hash->{$key} ? 0 : 1, $name );
	}

=back

=head1 SEE ALSO

L<Test::Data>,
L<Test::Data::Array>,
L<Test::Data::Function>,
L<Test::Data::Scalar>,
L<Test::Builder>

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/test-data

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2016, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

"red leather yellow leather";
