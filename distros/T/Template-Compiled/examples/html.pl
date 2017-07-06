#!/bin/env perl

use strict;
use warnings;

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

print $template->render(\%values), "\n";

