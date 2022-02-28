use Test::More;

use lib 't/lib';

use POD::Generate;

my $pg = POD::Generate->new();

my $nested = $pg->name("Test::Package");

$nested->description("Some more text which can be formatted with tabs...");

my $string = $nested->generate();

my $expected = q|=head1 NAME

Test::Package

=cut

=head1 DESCRIPTION

Some more text which can be formatted with tabs...

=cut|;

is($string, $expected);

$nested->synopsis(q|Perhaps a code snippet

	use Test::Package;
	my $tp = Test::Package->new();|)->p("Add some more text because that is a thing");

$nested->methods();

$nested->h2("Some Function", "okay add some text")->p(q|	SELECT thing
	FROM TABLE|);

$string = $nested->generate();

$expected = q|=head1 NAME

Test::Package

=cut

=head1 DESCRIPTION

Some more text which can be formatted with tabs...

=cut

=head1 SYNOPSIS

Perhaps a code snippet

	use Test::Package;
	my $tp = Test::Package->new();

Add some more text because that is a thing

=cut

=head1 METHODS

=cut

=head2 Some Function

okay add some text

	SELECT thing
	FROM TABLE

=cut|;

is($string, $expected);

$nested->h2("other", "add a list within");

$nested->item("one");

$nested->item("two");

$nested->item("three");

$nested->author("LNATION C<< <email at lnation.org> >>");

$string = $nested->generate();

$expected = q|=head1 NAME

Test::Package

=cut

=head1 DESCRIPTION

Some more text which can be formatted with tabs...

=cut

=head1 SYNOPSIS

Perhaps a code snippet

	use Test::Package;
	my $tp = Test::Package->new();

Add some more text because that is a thing

=cut

=head1 METHODS

=cut

=head2 Some Function

okay add some text

	SELECT thing
	FROM TABLE

=cut

=head2 other

add a list within

=over

=item one

=item two

=item three

=back

=cut

=head1 AUTHOR

LNATION C<< <email at lnation.org> >>

=cut|;

is($string, $expected);

$string = $pg->generate;

is($string->{"Test::Package"}, $expected);

$nested->bugs()->support()->acknowledgements()->license();

$nested->generate('file');

$nested->generate('seperate_file');

done_testing();
