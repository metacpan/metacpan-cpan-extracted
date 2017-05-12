package MooseX::Aspect::Util;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$MooseX::Aspect::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::Aspect::VERSION   = '0.001';
}

use Carp;
use Class::Load qw( load_class );
use Class::MOP qw();
use Devel::Caller qw( caller_args );
use Moose ();
use Moose::Exporter;
use namespace::sweep -also => [qw/ class_of /];

sub class_of {
	goto \&Class::MOP::class_of;
}

'Moose::Exporter'->setup_import_methods(
	as_is     => [qw( join_point )],
);

sub join_point
{
	my $meta = class_of scalar caller;
	my ($aspect, $join_point) = @_;
	
	return unless $meta->can('employs_aspect') && $meta->employs_aspect($aspect);
	
	my $args = [ caller_args(1) ];
	return class_of($aspect)->run_join_point($meta, $join_point, $args);
}

1;

__END__

=head1 NAME

MooseX::Aspect::Util - utils for aspect-oriented programming

=head1 DESCRIPTION

This package contains aspect-oriented programming utility functions which
are to be used outside the aspect definitions themselves.

=head2 Functions

=over

=item C<< join_point(ASPECT, JOINPOINT) >>

Calls a custom join point (one created with C<create_join_point>). The
call is silently ignored if the aspect is not set up for the caller package.

This function is exported by default.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-Aspect>.

=head1 SEE ALSO

L<MooseX::Aspect>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

