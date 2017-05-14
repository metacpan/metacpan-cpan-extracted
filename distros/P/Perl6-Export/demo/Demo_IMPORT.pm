package Demo_IMPORT;
use Perl6::Export;

IMPORT {
	use Data::Dumper 'Dumper';
	warn Dumper [ @_ ];
}

sub always is export(:MANDATORY) { "always heer" }

sub foo is export(:DEFAULT) { "foo heer" }

sub bar is export(:BAR) { "bar heer" }


1;
