package MooX::Struct::Util;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.016';

use strict;
use warnings;
use Exporter::Tiny ();

our @ISA    = qw(Exporter::Tiny);
our @EXPORT = qw(lazy_default);

sub lazy_default (&)
{
	my $sub = shift;
	return [
		lazy    => 1,
		default => $sub,
	];
}

1;

__END__

=head1 NAME

MooX::Struct::Util - extensions for MooX::Struct that would have been overkill to include

=head1 LAZY DEFAULTS

=begin trustme

=item lazy_default

=end trustme

Sugar for lazily defaulted attributes. The following two are effectively
the same.

 use MooX::Struct WebPage1 => [
    user_agent => [
       lazy     => 1,
       default  => sub { LWP::UserAgent->new },
    ],
 ];
 
 use MooX::Struct::Util qw(lazy_default);
 use MooX::Struct WebPage2 => [
    user_agent => lazy_default { LWP::UserAgent->new },
 ];

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-Struct>.

=head1 SEE ALSO

L<MooX::Struct>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

