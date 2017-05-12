=pod

=encoding utf-8

=head1 PURPOSE

Serialize a more complex graph and check the result is isomorphic
to the input.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use JSON qw( to_json -convert_blessed_universally );
use RDF::Trine;
use match::smart qw(match);

require RDF::Trine::Graph;
require RDF::Trine::Model;
require RDF::Trine::Parser::Turtle;
require RDF::Trine::Serializer::Turtle;
require RDF::TrineX::Serializer::MockTurtleSoup;

require RDF::Prefixes;
plan match("RDF::Prefixes"->VERSION, [qw(0.003 0.004)])
	? (tests => 3)
	: (skip_all => "tests designed for RDF::Prefixes 0.003/0.004");

sub check
{
	my ($input, $opts, $expected) = @_;
	
	my $do_str_test = !!delete($opts->{str_test});
	my $prio = delete($opts->{priorities}) and $opts->{priorities} = 1;
	
	subtest sprintf("testing with opts %s", to_json($opts, {canonical=>1,convert_blessed=>1})), sub
	{
		plan tests => ($do_str_test ? 2 : 1);
		
		my $mts = "RDF::TrineX::Serializer::MockTurtleSoup"->new(%$opts, priorities => $prio);
		my $got = $mts->serialize_model_to_string($input);
		
		is($got, $expected, "serialized string matches") if $do_str_test;
		
		my $model = "RDF::Trine::Model"->new;
		"RDF::Trine::Parser::Turtle"->new->parse_into_model(
			"http://localhost/",
			$got,
			$model,
		);
		
		my $g1 = "RDF::Trine::Graph"->new($input);
		my $g2 = "RDF::Trine::Graph"->new($model);
		ok($g1->equals($g2), "graphs are isomorphic") or diag($got);
	};
}

my $model = "RDF::Trine::Model"->new;
"RDF::Trine::Parser::Turtle"->new->parse_file_into_model(
	"http://localhost/",
	\*DATA,
	$model,
);

check($model, { str_test => 0 }, "");
check($model, { str_test => 0, repeats => 1 }, "");
check($model, { str_test => 0, priorities => sub { return 100 if $_[1]->is_blank; return } }, "");

__DATA__
@base <http://example.com/>.

<foo>
	<bar>
		( _:baz _:quux ) .

_:quux <xyzzy> _:baz .

<bar> a _:monkey .
<baz> a _:monkey, _:puzzle .

_:puzzle a <foo>.

_:cyclic <cycle> _:cyclic ; <branch> _:branch .
