my $version = do {
	require "./lib/Object/Iterate.pm";
	$Object::Iterate::VERSION;
	};
print "Version is $version\n";

if( @ARGV ) {
	require File::Basename;
	require File::Path;
	unlink $ARGV[0] or die "Could not remove prior $ARGV[0]: $!\n";
	my $dirname = File::Basename::dirname( $ARGV[0] );
	File::Path::make_path( $dirname );
	open my $fh, '>:utf8', $ARGV[0]
		or die "Could not open file <$ARGV[0]>: $!";
	select( $fh );
	}

my %CONFIG;
$CONFIG{PROTOTYPE_ATTRIBUTE} = $] >= 5.020;

LINE: while( <DATA> ) {
	s/%%VERSION%%/$version/g;
	unless( /\A#ifdef\s+(\S+)/ ) { print; next; }
	my $item = $1;
	if( $CONFIG{$item} ) {
		while(<DATA>) {
			if( /\A#else/ ) {
				while(<DATA>) { last if /\A#endif/ }
				next LINE;
				}
			print;
			}
		}
	else {
		while(<DATA>) { last if /\A#else/ }
		while(<DATA>) {
			last if /\A#endif\s*\z/;
			print;
			}
		}
	}

__END__
package Object::Iterate;
#ifdef PROTOTYPE_ATTRIBUTE
use v5.20;
#else
use v5.008;
die <<"HERE" if $] >= 5.020;
Perl less than v5.20 required--this is $^V, stopped.
HERE
#endif

use strict;
use warnings;
no warnings;

=encoding utf8

=head1 NAME

Object::Iterate - iterators for objects that know the next element

=head1 SYNOPSIS

	use Object::Iterate qw(iterate igrep imap);

	iterate {...} $object;

	my @filtered    = igrep {...} $object;

	my @transformed = imap  {...} $object;

=head1 DESCRIPTION

This module provides control structures to iterate through the
elements of an object that cannot be represented as list of items all
at once.  Objects can represent a virtual collection that is beyond
the reaches of foreach, map, and grep because they cannot turn
themselves into a list.

If the object can return a next element, it can use this module.
Iterate assumes that the object responds to C<__next__> with the next
element, and to C<__more__> with TRUE or FALSE if more elements remain
to be processed.  The C<__init__> method is called before the first
iteration (if it exists), and is silently skipped otherwise. The
control structure continues until the C<__more__> method returns FALSE
(which does not mean that it visited all of the elements but that the
object has decided to stop iterating).  At the end of all iterations
(when C<__more__> returns false), C<Object::Iterate> calls
C<__final__> if it exists, and skips it otherwise.

Each control structure sets C<$_> to the current element, just like
foreach, map, and grep.

=head2  Mutable method names

You do not really have to use the C<__next__>, C<__more__>,
C<__init__>, or C<__final__> names. They are just the defaults which
<Object::Iterate> stores in the package variables C<$Next>, C<$More>,
C<$Init>, and C<$Final> respectively.  This module does not export
these variables, so you need to use the full package specification to
change them (I<i.e.> C<$Object::Iterate::Next>). If your object does
not have the specified methods, the functions will die.  You may want
to wrap them in eval blocks.

Since this module uses package variables to store these methods names,
the method names apply to every use of the functions no matter the
object.  You might want to local()-ise the variables for different
objects.

Before any control structure does its job, it checks the object to see
if it can respond to these two methods, whatever you decide to call
them, so your object must know that it can respond to these methods.
AUTOLOADed methods cannot work since the module cannot know if they
exist.

=cut

use Carp qw(croak);
use Exporter qw(import);
our @EXPORT_OK   = qw(iterate igrep imap);
our %EXPORT_TAGS = (
	all => \@EXPORT_OK,
	);

our $VERSION = '%%VERSION%%';

our $Next  = '__next__';
our $More  = '__more__';
our $Init  = '__init__';
our $Final = '__final__';

sub _check_object {
	croak( "iterate object has no $Next() method" )
		unless eval { $_[0]->can( $Next ) };
	croak( "iterate object has no $More() method" )
		unless eval { $_[0]->can( $More ) };

	$_[0]->$Init() if eval { $_[0]->can( $Init ) };

	return 1;
	}

=over 4

=item iterate BLOCK, OBJECT

Applies BLOCK to each item returned by C<< OBJECT->__next__ >>.

	iterate { print "$_\n" } $object;

This is the same thing as using a while loop, but C<iterate()>
stays out of your way.

	while( $object->__more__ ) {
		local $_ = $object->__next__;
		...BLOCK...
		}

=cut

#ifdef PROTOTYPE_ATTRIBUTE
sub iterate :prototype(&$) {
#else
sub iterate (&$) {
#endif
	my $sub    = shift;
	my $object = shift;

	_check_object( $object );

	while( $object->$More() ) {
		local $_;
		$_ = $object->$Next();
		$sub->();
		}

	$object->$Final() if $object->can( $Final );
	}

=item igrep BLOCK, OBJECT

Applies BLOCK to each item returned by C<< OBJECT->__next__ >>, and
returns all of the elements for which the BLOCK returns TRUE.

	my $output = igrep { print "$_\n" } $object;

This is a grep for something that cannot be represented as a
list at one time.

	while( $object->__more__ ) {
		local $_ = $object->__next__;
		push @output, $_ if ...BLOCK...;
		}

=cut

#ifdef PROTOTYPE_ATTRIBUTE
sub igrep :prototype(&$) {
#else
sub igrep (&$) {
#endif
	my $sub    = shift;
	my $object = shift;

	_check_object( $object );

	my @output = ();

	while( $object->$More() ) {
		local $_;
		$_ = $object->$Next();
		push @output, $_ if $sub->();
		}

	$object->$Final() if $object->can( $Final );

	wantarray ? @output : scalar @output;
	}

=item imap BLOCK, OBJECT

Applies BLOCK to each item returned by C<< OBJECT->__next__ >>, and
returns the combined lists that BLOCK returns for each of the
elements.

	my @output = imap { print "$_\n" } $object;

This is a map for something that cannot be represented as a
list at one time.

	while( $object->$More ) {
		local $_ = $object->__next__;

		push @output, ...BLOCK...;
		}

=cut

#ifdef PROTOTYPE_ATTRIBUTE
sub imap :prototype(&$) {
#else
sub imap (&$) {
#endif
	my $sub    = shift;
	my $object = shift;

	_check_object( $object );

	my @output = ();

	while( $object->$More ) {
		local $_;
		$_ = $object->$Next;
		push @output, $sub->();
		}

	$object->$Final if $object->can( $Final );

	@output;
	}

=back

=head1 ERROR MESSAGES

=over 4

=item iterate object has no C<__more__()> method at script line N

You need to provide the method to let C<Object::Iterate> determine if
more elements are available.  You don't have to call it C<__more__> if
you change the value of C<$Object::Iterate::More>.

=item iterate object has no C<__next__()> method at script line N

You need to provide the method to let Object::Iterate fetch the next
element.  You don't have to call it C<__next__> if you change the
value of C<$Object::Iterate::Next>.

=back

=head1 SOURCE AVAILABILITY

This module is on Github:

	http://github.com/briandfoy/object-iterate

=head1 TO DO

* let the methods discover the method names per object.

=head1 CREDITS

Thanks to Slaven Rezic for adding C<__init__> support

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>.

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2024, brian d foy <briandfoy@pobox.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut

1;
