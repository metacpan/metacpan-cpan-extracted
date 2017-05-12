package Syntax::Collection::Basic;

use 5.010;

our $VERSION = "0.06";


use Syntax::Collector q/
	use strict 0;
	use warnings 0;
	use Modern::Perl 0 '2014';
	use true 0;
/;

1;

=head1 NAME

Syntax::Collection::Basic - yet another.

=head1 SYNOPSIS

   use Syntax::Collection::Basic;

Is really

	use strict;
	use warnings;
	use Modern::Perl '2014';
	use true;

=head1 AUTHOR

Erik Carlsson

=head1 COPYRIGHT

Copyright 2014 - Erik Carlsson

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
