package Module::Pragma;

use 5.010_000;

use strict;
use warnings;

#use Smart::Comments; # for debugging

our $VERSION = '0.02';

my %register  = ();

sub import
{
	my $class = shift @_;

	return if $class eq __PACKAGE__;

	@_ = $class->default_import() unless @_;

	### import: \@_, join ' ', caller

	$class->check_exclusive(@_);

	$^H{$class}  |=  $class->pack_tags(@_);
	$^H{$class}  &= ~$class->pack_tags( $class->exclusive_tags(@_) );
}

sub unimport
{
	my $class = shift @_;

	return if $class eq __PACKAGE__;

	### unimport: \@_, join ' ', caller

	if(@_){
		$class->check_exclusive(@_);

		$^H{$class}  |=  $class->pack_tags( $class->exclusive_tags(@_) );
		$^H{$class}  &= ~$class->pack_tags(@_);
	}
	else{
		delete $^H{$class};
	}
}

sub enabled
{
	my $class = shift @_;

	my $bits = $class->hint(1);

	$bits &= $class->pack_tags(@_) if @_;

	return wantarray ? $class->unpack_tags($bits) : $bits;
}

sub hint
{
	my($class, $level) = @_;

	my $hint_hash;
	my $bits;
	do {
		my $pkg;
		($pkg, $hint_hash) = ( caller ++$level )[0, 10];

		return undef unless defined $pkg;

	} until defined( $bits =  $hint_hash->{$class} );

	return $bits;
}

sub unknown_tag
{
	my($class, $tag) = @_;

	$class->_die("unknown subpragma '$tag'");
}


sub default_import
{
	my($class) = @_;

	$class->_die('requires explicit arguments');
}

sub _die
{
	my $class = shift @_;

	require Carp;
	Carp::croak("$class: ", @_);
}


sub register_tags
{
	my($class, @tags) = @_;

	my $map = $register{$class} //= {};

	my $bit_ref = \($map->{___bit___});


	while(defined(my $tag = shift @tags)){

		unless($$bit_ref){
			$$bit_ref = 1;
		}
		else{
			my $old = $$bit_ref;
			$$bit_ref <<= 1;

			#bitmask test
			if($$bit_ref == 0){
				__PACKAGE__->_die("$tag=($old << 1) is not a valid bitmask (integer overflowed?)");
			}
		}

		if($tag =~ /^___/){
			__PACKAGE__->_die("'$tag' is not a valid tag name");
		}

		if(@tags && $tags[0] =~ /^\d+$/){
			$$bit_ref = int shift @tags;
		}

		$map->{$tag} = $$bit_ref;

	}

	return $$bit_ref;
}

sub register_bundle
{
	my($class, $bundle, @tags) = @_;

	$register{$class}{':' . $bundle} = $class->pack_tags(@tags);
}

sub register_exclusive
{
	my $class = shift @_;

	my $ex = $register{$class}{___ex___} //= {};

	foreach my $x(@_){
		foreach my $y(@_){
			unless($x eq $y){
				push @ {$ex->{$x} }, $y;
				$ex->{$x, $y} = 1;
			}
		}
	}
}

sub exclusive_tags
{
	my $class = shift @_;

	my $ex = $register{$class}{___ex___} or return;

	my @ex_tags;
	my %seen;

	# expansion and regulation
	foreach my $tag(grep{ $ex->{$_} } map{ $class->unpack_tags( $class->tag($_) ) } @_)
	{
		push @ex_tags,
			grep{ !$seen{$_}++ } # uniq
			map { $class->unpack_tags( $class->tag($_) ) }
			@{ $ex->{$tag} };

	}
	return @ex_tags;
}
sub check_exclusive
{
	my $class = shift @_;

	my $ex = $register{$class}{___ex___} or return;

	# check whether these are exclusive
	foreach my $x(@_){
		foreach my $y(@_){
			$class->_die("'$x' and '$y' are exclusive mutually") if $ex->{$x, $y};
		}
	}
}

sub tag
{
	my($class, $tag) = @_;
	return $register{$class}{$tag} // $class->unknown_tag($tag);
}

sub tags
{
	my($class) = @_;

	my $map = $register{$class} or return;

	return grep{ not( /^:/ or /^__/ ) } keys %$map;
}


sub pack_tags
{
	my $class = shift @_;

	my $bits = 0;
	foreach my $tag(@_){
		$bits |= $class->tag($tag);
	}
	return $bits;
}
sub unpack_tags
{
	my($class, $bits) = @_;

	return unless defined $bits;

	return grep{ $class->tag($_) & $bits or $class->tag($_) == $bits } $class->tags;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Module::Pragma - Support for implementation of pragmas

=head1 SYNOPSIS

	# Foo.pm
	package Foo;
	use base qw(Module::Pragma);

	__PACKAGE__->register_tags(qw(-SHA1 -MD5));
	__PACKAGE__->exclusive_tag( __PACKAGE__->tags );

	sub something
	{
		# ...
		if(__PACKAGE__->enabled(-SHA1)){
			$mod = 'Digest::SHA1';
		}
		elsif(__PACKAGE__->enabled(-MD5)){
			$mod = 'Digest::MD5';
		}
		else{
			$mod = $Digest_Default;
		}
		# ...
	}
	# ...
	1;
	__END__

	# foo.pl
	use Foo;

	Foo->something(); # Foo->enabled(-SHA1) is true
	{
		use Foo -MD5;
		Foo->something(); # Foo->enabled(-MD5) is true
	}
	Foo->something(); # Foo->enabled(-SHA1) is true

	# ...

=head1 DESCRIPTION

With perl 5.10.0 you can write lexical pragma modules,
which influence some aspect of the compile time or run time behavior of Perl
programs. Module::Pragma helps to write such a module.

Module::Pragma supports bitmask-based options. That is, a subpragma takes only a
bool, true or false. And a pragma uses an integer for its storage, so the number
of subpragmas is limited to at most 32 or 64 (depends on the perl integer size).

=head2 How to set it up

Module::Pragma is designed as Object-Oriented and all the methods are
B<class methods>.

First, load the module and set it a super class.

	package mypragma;
	use base qw(Module::Pragma);

Next, register subpragmas (called B<tags> in this module) with
C<register_tags()> method.

	__PACKAGE__->register_tags(qw(foo bar baz));

You can also make a bundle of tags with C<register_bunlde()> method.

	__PACKAGE__->register_bundle('foobar' => ['foo', 'bar']);

To make some tags exclusive, call C<regsiter_exclusive()> method.

	__PACKAGE__->register_exclusive('foo', 'baz');

Here you have finished setting up a new pragma. It's used like other pragmas.

	use mypragma 'foo';
	use mypragma 'baz';     # 'foo' and 'baz' are exclusive;
	                        #  'foo' removed and 'baz' set on.
	use mypragma ':foobar'; # 'baz' removed ,and 'foo' and 'bar' set on.

This pragma requires explicit arguments and refuses unknown tags by
default.

	use mypragma;        # die!
	use mypragma 'fooo'; # die!

If you don't want this behavior, you can override C<default_import()> and
C<unknown_tag()>.

=head1 METHODS

=head2 Registration of tags

=over 4

=item PRAGMA->register_tags(tagname [ => flag] [, more tags ...])

Registers I<tags> and returns the last value of I<tags>. Each I<tag> is
assigned to a bitmask automatically unless othewise specified.

For example:

	PRAGMA->register_tags(
		'A' =>   0b00100,
		'B',   # 0b01000
		'C',   # 0b10000
		'D' =>   0b00001,
		'E',   # 0b00010
	); # -> returns 0b00010 (corresponding to 'E')

Cannot register those which begin with triple underscores, because they are
reserved for Module::Pragma internals.

=item PRAGMA->register_bundle(bundlename => tags...)

Makes a bundle of I<tags>.  To use the bundle, add a semicolon to the
I<bundlename> as a prefix.

=item PRAGMA->register_exclusive(tags...)

Declares I<tags> exclusive. Exclusive tags are not specified simultaneously.

=back

=head2 Checking Effects

=over 4

=item PRAGMA->enabled(tags...)

Checks at the run time whether I<tags> are in effect. If no argument is
supplied, it returns the state of I<PRAGMA>.

When scalar context (including bool context) is wanted then it returns an
integer, otherwise it returns a list of the tags enabled;

=back

=head2 use/no Directives

C<Module::Pragma> itself do nothing on C<import()> nor C<unimport()>. They work
only when called as methods of subclass;

These two methods call C<check_exclusive()>, so if exclusive tags are
supplied at the same time, it will cause C<_die()>.

=over 4

=item PRAGMA->import(tags...)

Enables I<tags> and disables the exclusive tags.

If no argument list is suplied, it calls C<default_import()>, and if it doesn't
C<_die()> then it will use the return value as the arguments.

=item PRAGMA->unimport(tags...)

Disables I<tags> and enables the exclusive tags.

if no argument is suplied, it disables all the effect.

=back

=head2 Handling Exception

There are some exception handlers which are overridable.

=over 4

=item PRAGMA->default_import( )

Called in C<import()> when the arguments are not supplied. It will
C<_die()> by default. So if needed, you can override it. The return values are
used as the arguments of C<import()>.

=item PRAGMA->unknown_tag(tagname)

Called in C<tag()> when an unknown I<tagname> is found. It will C<_die()> by
default. To change the behavior, override it. Expected to return an integer
used as a bitmask.

=back

=head2 Utilities

Module::Pragma provides pragma module authors with utilities.

=over 4

=item PRAGMA->hint([level_to_go_back])

Returns the state of I<PRAGMA>.


=item PRAGMA->_die(messages...)

Loads C<Carp.pm> and calls C<croak()> with I<PRAGMA> and I<messages>.

=item PRAGMA->tag(tagname)

Returns the bitmask corresponding to I<tagname>.

If I<tagname> is unregistered, it will call C<unknown_tag()> with I<tagname>.

=item PRAGMA->tags( )

Returns all the registered tags.

Note that tags beginning with double underscores are ignored.

=item PRAGMA->pack_tags(tags...)

Returns the logical sum of I<tags>.

=item PRAGMA->unpack_tags(bits)

Returns the names of tags corresponding to I<bits>.

=item PRAGMA->exclusive_tags(tags...)

Returns tags which are exclusive to I<tags>.

=item PRAGMA->check_exclusive(tags...)

Checks whether I<tags> are exclusive and if so, causes C<_die()>.

=back

=head1 EXAMPLES

=head2 An implementation of F<less.pm>

The minimal implementation of C<less.pm> would be something like this:

	package less;
	use base qw(Module::Pragma);
	sub default_import{
		return 'please';
	}
	sub unknown_tag{
		my($class, $tag) = @_;
		return $class->register_tags($tag);
	}
	1; # End of file

This is almost equal to the standard C<less.pm> module (but the interface
is a little different).

	require less;
	sub foo{
		if(less->enabled()){
			foo_using_less_resource();
		}
		else{
			foo_using_more_resource();
		}
	}

	{
		use less; # or use less 'CPU' etc.
		foo(); # in foo(), less->enabled() returns true
	}
	foo(); # less->enabled() returns false

=head1 BUGS

Please report bugs relevant to C<Module::Pragma> to C<< <gfuji(at)cpan.org> >>.

=head1 SEE ALSO

See L<perlpragma> for the internal details.

=head1 AUTHOR

Goro Fuji (藤 吾郎) C<< <gfuji(at)cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008 Goro Fuji.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
