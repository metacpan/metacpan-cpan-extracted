package Template::Plugin::Java::Constants;

=head1 NAME

Template::Plugin::Java::Constants - Constants for the Java Template plugin
modules.

=head1 SYNOPSIS

use Template::Plugin::Java::Constants qw/:regex/;
use Template::Plugin::Java::Constants qw/:boolean/;
use Template::Plugin::Java::Constants qw/:all/;

=head1 DESCRIPTION

=over 8

=item B<regex>

The "regex" tag exports qr// compiled regular expressions SCALAR, PRIMITIVE,
STRING and ARRAY, these are for matching Java types. All of these match a whole
line, with no extra whitespace, and return the matched java type as $1. They
may be used as:

$string =~ /@{[SCALAR]}/; # Ugly but effective and relatively fast.

=over 8

=item B<SCALAR>

Any primitive or encapsulated primitive: int, or Integer, or String, etc.

=item B<PRIMITIVE>

Only primitive types like int, float, double, byte, etc.

=item B<STRING>

An incarnation of java.lang.String.

=item B<ARRAY>

A java.util.Vector.

=back

=item B<boolean>

The boolean tag just exports the constants TRUE as 1 and FALSE as 0.

=item B<all>

Exports all of the proceeding.

=back

=cut

require Exporter;
@ISA = qw( Exporter );

use strict;
use vars qw(@EXPORT_OK %EXPORT_TAGS);

use constant INSTALL_PREFIX => '@@INSTALL_PREFIX@@';

my @boolean = qw(TRUE FALSE);
use constant TRUE   => 1;
use constant FALSE  => 0;

my @regex = qw(SCALAR STRING ARRAY);

use constant SCALAR => qr{^(
	(?:java\.lang\.)?
	(?:[Bb]yte|[Cc]har|[Ss]hort|Integer|int|[Ll]ong|[Ff]loat|[Dd]ouble|String)
)$}x;

use constant STRING => qr{^((?:java\.lang\.)?String)$};

use constant ARRAY  => qr{^((?:java\.util\.)?Vector)$};

@EXPORT_OK   = (@boolean, @regex, 'INSTALL_PREFIX');
%EXPORT_TAGS = (
	'all'	=> [ @EXPORT_OK ],
	'boolean'=>[ @boolean   ],
	'regex'	=> [ @regex     ]
);

1;

__END__

=head1 AUTHOR

Rafael Kitover (caelum@debian.org)

=head1 COPYRIGHT

This program is Copyright (c) 2000 by Rafael Kitover. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=head1 SEE ALSO

L<perl(1)>,
L<Template(3)>,
L<Template::Plugin::Java::Utils(3)>,
L<Template::Plugin::Java::SQL(3)>

=cut
