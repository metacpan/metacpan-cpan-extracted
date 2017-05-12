package Sub::Talisman::Struct;

use 5.012;
use strict;
use warnings;

BEGIN {
	$Sub::Talisman::Struct::AUTHORITY = 'cpan:TOBYINK';
	$Sub::Talisman::Struct::VERSION   = '0.005';
}

use base qw( Sub::Talisman );
use MooX::Struct ();
use Carp qw( confess );
use Data::OptList ();
use namespace::clean;
	
sub import
{
	my $class  = shift;
	my $caller = caller;
	
	foreach my $arg (@{ Data::OptList::mkopt(\@_) })
	{
		my ($atr, $str) = @$arg;
		$class->setup_for($caller => {
			attribute => $atr,
			struct    => $str,
		});
	}
}

my %PROCESSORS;
my %STRUCTS;
sub setup_for
{
	my ($class, $caller, $opts) = @_;
	$class->SUPER::setup_for($caller, $opts);
	my $proc   = $PROCESSORS{$caller} //= 'MooX::Struct::Processor'->new;
	my $struct = $proc->make_sub(
		$opts->{attribute},
		$opts->{struct} || [],
	);
	$STRUCTS{"$caller\::$opts->{attribute}"} = $struct;
}

sub _process_params
{
	my ($class, $attr, $params) = @_;
	
	my %new;
	my @p = @{ $params || [] };
	my @f = $STRUCTS{$attr}->()->FIELDS;
	confess "Too many parameters for attribute $attr" if @p > @f;
	for my $i ( 0 .. $#p )
	{
		$new{ $f[$i] } = $p[$i];
	}
	my $obj = eval { $STRUCTS{$attr}->()->new(%new) };
	return $obj if $obj;
	chomp(my $msg = $@);
	$msg =~ s{ at \(.+?\) line \d+\.?}{};
	confess $msg;
}

1;

__END__

=head1 NAME

Sub::Talisman::Struct - the spawn of MooX-Struct and Sub-Talisman

=head1 SYNOPSIS

	package Local::MyExample;
	
	use Sub::Talisman:::Struct
		Provenance => [qw( $creator $date )],
		Tested     => [qw( $status! )],
	;
	
	sub myfunc :Provenance("Joe Bloggs","2012-10-19") :Tested("ok")
	{
		...;
	}
	
	my $prov = Sub::Talisman::Struct
		->get_attribute_parameters(\&myfunc, 'Provenance');
	
	say $prov->creator;  # says "Joe Bloggs"
	say $prov->date;     # says "2012-10-19"

=head1 DESCRIPTION

L<MooX::Struct> creates light-weight objects which can have required
attributes, type constraints, etc. L<Sub::Talisman> allows you to associate
data with subs. This module is a bit of glue between MooX::Struct and
Sub::Talisman.

The import routine uses the same syntax as L<MooX::Struct>, but instead
of creating struct-like classes for you to use, it creates struct-like
classes for Sub::Talisman to bless attribute parameters into.

Sub::Talisman::Struct itself is a subclass of Sub::Talisman, so inherits
the C<get_attributes>, C<get_attribute_parameters>, C<get_subs> and
C<setup_for> methods as documented.

Note that the term "attribute" is incredibly overloaded, applying both to
the tags like C<< :Provenance >> applied to the subs, and also to the
members of Moo classes, so in depth discussions of this module will tend
to descend into chaos. So I'll leave it at that for the documentation.
If you need any further clarification, take a peek at the bundled test
suite.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Sub-Talisman-Struct>.

=head1 SEE ALSO

L<Sub::Talisman>, L<MooX::Struct>.

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

