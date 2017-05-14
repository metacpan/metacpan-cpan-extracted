package Demo_Export;
use Perl6::Export;

sub always is export(:MANDATORY) { "always heer" }

sub foo is export(:DEFAULT) { "foo heer" }

sub bar is export(:BAR) { "bar heer" }

sub import {
	use Data::Dumper 'Dumper';
	warn Dumper [ @_ ];
}

1;
