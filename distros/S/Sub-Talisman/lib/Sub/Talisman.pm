package Sub::Talisman;

use 5.008;
use strict;
use warnings;

BEGIN {
	$Sub::Talisman::AUTHORITY = 'cpan:TOBYINK';
	$Sub::Talisman::VERSION   = '0.005';
}

use Attribute::Handlers;
use Sub::Identify qw( get_code_info );
use Sub::Name     qw( subname );
use Scalar::Does  qw( does -constants );
use Scalar::Util  qw( refaddr );

sub _identify
{
	my $sub = shift;
	if (does $sub, CODE)
	{
		my ($p, $n) = get_code_info($sub);
		$n .= sprintf('(%d)', refaddr($sub)) if $n eq '__ANON__';
		return ($p, $n);
	}
	elsif ($sub =~ /::/)
	{
		my ($p, $n) = ($sub =~ /^(.*)::(\w+)$/);
		$p = 'main' if $p eq q();
		return ($p, $n);
	}
	else
	{
		return ($_[0], $sub);
	}
}

use namespace::clean;
my (%TALI, %FETCH);

sub setup_for
{
	my ($class, $caller, $opts) = @_;
	my $atr = $opts->{attribute};
	eval qq{
		package $caller;
		sub $atr :ATTR(CODE)
		{
			unshift \@_, q[$class], q[$caller];
			my \$callback = "$class"->can("_callback");
			goto \$callback;
		}
	};
	namespace::clean->import(
		-cleanee => $caller,
		$opts->{attribute},
	);
	unless ($FETCH{$caller})
	{
		no strict 'refs';
		my $subname = "$caller\::FETCH_CODE_ATTRIBUTES";
		*$subname = subname $subname, sub {
			my ($class, $sub) = @_;
			return map { /(\w+)$/ ? $1 : () }
				__PACKAGE__->get_attributes($sub);
		};
		$FETCH{$caller} = 1;
	}
}

sub import
{
	my $class  = shift;
	my $caller = caller;
	foreach my $atr (@_)
	{
		$class->setup_for($caller, { attribute => $atr });
	}
}

sub _process_params
{
	my ($class, $attr, $params) = @_;
	return $params;
}

sub _callback
{
	my ($class, $installation_pkg, $caller_pkg, $glob, $ref, $attr, $params, $step, $file, $line) = @_;
	my ($p, $n)   = _identify($ref, scalar caller);
	my $full_attr = join q[::], $installation_pkg, $attr;
	my $obj       = $class->_process_params($full_attr, $params);
	$TALI{$p}{$n}{$full_attr} = $obj;
}

sub get_attributes
{
	my ($class, $sub) = @_;
	my ($p, $n) = _identify($sub, scalar caller);
	my %hash = %{ $TALI{$p}{$n} || {} };
	return sort keys %hash;
}

sub get_attribute_parameters
{
	my ($class, $sub, $attr) = @_;
	$attr = scalar(caller).'::'.$attr unless $attr =~ /::/;
	my ($p, $n) = _identify($sub, scalar caller);
	return unless exists $TALI{$p}{$n}{$attr};
	return $TALI{$p}{$n}{$attr};
}

sub get_subs
{
	my ($class, $attr) = @_;
	$attr = scalar(caller).'::'.$attr unless $attr =~ /::/;
	my @subs;
	foreach my $pkg (keys %TALI)
	{
		push @subs,
			map  { "$pkg\::$_" }
			grep { exists $TALI{$pkg}{$_}{$attr} }
			grep { not /^__ANON__\([0-9]+\)$/ }
			keys %{ $TALI{$pkg} };
	}
	return @subs;
}

1;

__END__

=head1 NAME

Sub::Talisman - use attributes to tag or classify subs

=head1 SYNOPSIS

	package Local::Example;
	
	use Sub::Talisman qw( Awesome Info );
	
	sub mysub :Awesome {
		...;
	}
	
	sub othersub :Info("Hello World") {
		...;
	}
	
	my @awesome_subs = Sub::Talisman->get_subs("Local::Example::Awesome");
	
	print Sub::Talisman    # prints "Hello World"
		-> get_attribute_parameters(\&othersub, "Local::Example::Info")
		-> [0];

=head1 DESCRIPTION

Sub::Talisman allows you to define "talisman" attibutes for your subs,
and provides a basic introspection API for these talismans.

=head2 Class Methods

Sub::Talisman's methods are designed to be called as class methods.

=over

=item C<< setup_for $package, \%options >>

This is used by C<import> to setup a single attribute. As an example, to
create a "Purpose" talisman in UNIVERSAL, then:

	Sub::Talisman->setup_for(
		'UNIVERSAL',
		{ attribute => 'Purpose' },
	);

The only option understood is "attribute" which provides the name of the
attribute.

=item C<< get_attributes($sub) >>

Gets a list of attributes associated with the sub. Each attribute is a
package-qualified name, such as "Local::Example::Awesome" from the
SYNPOSIS.

C<< $sub >> can be a code ref or a sub name. In the case of subs which
have been exported and imported between packages, using the sub name
may not be very reliable. Using a code reference is recommended.

This function only returns attributes defined via Sub::Talisman. For
other attributes such as the Perl built-in C<< :lvalue >> attribute,
see the C<get> function in the L<attributes> package.

=item C<< get_attribute_parameters($sub, $attr) >>

Given a sub and an attribute name, retrieves the parenthesized list of
parameters. For example:

	sub foo :Info("Hello World") { ... }
	my $params = Sub::Talisman->get_attribute_parameters(\&foo, "Info");

The attribute name can be package-qualified. If it is not, then the
caller package is assumed.

The list of parameters retrieved is a simple arrayref (or undef if the
attribute was used without parentheses). For a more structured approach
including compile-time validation of the parameters, see
L<Sub::Talisman::Struct>.

=item C<< get_subs($attr) >>

Finds all subs which have the attribute, and returns a list of their
names. Anonymous subs are not returned.

=back

=head1 CAVEATS

=head2 Anonymous subs

Talisman attributes may be added to anonymous subs too, but it is
suspected that this may not be thread-safe...

	my $sub = sub :Awesome { ... };

Anonymous subs can of course be assigned into the symbol tables, a la:

	*foo = sub :Awesome { ... };

But as far as Sub::Talisman is concerned, they were anonymous at the time
of definition, so remain anonymous. A workaround would be:

	no warnings 'redefine';
	sub foo :Awesome;
	*foo = sub :Awesome { ... };

=head2 Talisman naming

Perl reserves lower-case attributes for its own future use; lower-cased
talisman attributes may work, but will probably spew warnings. Try to name
your talisman attributes in UpperCamelCase.

=head2 Talisman subs

Be aware that creating an attribute Foo will also create a sub called "Foo"
in your package. Sub::Talisman uses L<namespace::clean> to later wipe that
sub away, but that temporary sub does need to exist during compile-time,
so you won't be able to use that name for your own subs.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Sub-Talisman>.

=head1 SEE ALSO

L<attributes>, L<Attribute::Handlers>, L<Sub::Talisman::Struct>.

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

