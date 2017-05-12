package Method::Generate::ClassAccessor;

use 5.008;
use strict;
use warnings;
no warnings qw( void once uninitialized numeric );

BEGIN {
	no warnings 'once';
	$Method::Generate::ClassAccessor::AUTHORITY = 'cpan:TOBYINK';
	$Method::Generate::ClassAccessor::VERSION   = '0.011';
}

use B 'perlstring';

use base qw(Method::Generate::Accessor);

sub generate_method
{
	my ($self, $into, $name, $spec, $quote_opts) = @_;
	local $Method::Generate::Accessor::CAN_HAZ_XS = 0; # sorry
	$spec->{_classy} ||= $into;
	my $r = $self->SUPER::generate_method($into, $name, $spec, $quote_opts);
	
	# Populate default value
	unless ($spec->{lazy})
	{
		my $storage = do {
			no strict 'refs';
			\%{"$spec->{_classy}\::__ClassAttributeValues"};
		};
		
		my $default;
		if (ref($default = $spec->{default}))
		{
			$storage->{$name} = $default->($into);
		}
		elsif ($default = $spec->{default})
		{
			$storage->{$name} = $default;
		}
		elsif ($default = $spec->{builder})
		{
			$storage->{$name} = $into->$default;
		}
	}
	
	return $r;
}

sub _generate_simple_get
{
	my ($self, $me, $name, $spec) = @_;
	my $classy = $spec->{_classy};
	"\$$classy\::__ClassAttributeValues{${\perlstring $name}}";
}

sub _generate_core_set
{
	my ($self, $me, $name, $spec, $value) = @_;
	my $classy = $spec->{_classy};
	"\$$classy\::__ClassAttributeValues{${\perlstring $name}} = $value";
}

sub _generate_simple_has
{
	my ($self, $me, $name, $spec) = @_;
	my $classy = $spec->{_classy};
	"exists \$$classy\::__ClassAttributeValues{${\perlstring $name}}";
}

sub _generate_simple_clear
{
	my ($self, $me, $name, $spec) = @_;
	my $classy = $spec->{_classy};
	"delete \$$classy\::__ClassAttributeValues{${\perlstring $name}}";
}

1;

__END__

=head1 NAME

Method::Generate::ClassAccessor - generate class accessor method

=head1 DESCRIPTION

This class inherits from L<Method::Generate::Accessor>; see the very fine
documentation for that module.

This class overrides the following methods:

=over

=item C<generate_method>

=item C<_generate_simple_get>

=item C<_generate_core_set>

=item C<_generate_simple_has>

=item C<_generate_simple_clear>

=back

=head1 CAVEATS

B<< Moo 1.001000 has a bug that breaks this module. >>
Any other Moo should be fine and dandy.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-ClassAttribute>.

=head1 SEE ALSO

L<Method::Generate::Accessor>,
L<MooX::ClassAttribute>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

