=pod

=encoding utf-8

=head1 PURPOSE

Test a more complicated template.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Template::Compiled;
use Types::Standard -types;

my $template = Template::Compiled->new(
	trim       => !!1,
	outdent    => 2,
	signature  => [ name => Str, question => Str, lines => ArrayRef ],
	escape     => 'html',
	delimiters => [qw[ {{ }} ]],
	template   => q{
		<html>
			<head>
				<title>Example Template</title>
			</head>
			<body>
				<p>Hello {{= $name }}</p>
				<p>{{= $question }}</p>
				<ul>
				{{
					echo "\n";
					foreach my $line (@lines) {
						echof "$INDENT<li>%s</li>\n", _( $line );
					}
				}}
				</ul>
			</body>
		</html>
	},
);

my %values = (
	name      => 'Bob',
	question  => 'How are you today & tomorrow?',
	lines     => [qw/ foo b&r /],
);

is($template->render(\%values)."\n", <<'EXPECTED');
<html>
	<head>
		<title>Example Template</title>
	</head>
	<body>
		<p>Hello Bob</p>
		<p>How are you today &amp; tomorrow?</p>
		<ul>
		
			<li>foo</li>
			<li>b&amp;r</li>

		</ul>
	</body>
</html>
EXPECTED

done_testing;

