## ----------------------------------------------------------------------------
#  Sub::ScopeFinalizer
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/Sub-ScopeFinalizer/lib/Sub/ScopeFinalizer.pm 202 2006-11-03T10:24:44.000948Z hio  $
# -----------------------------------------------------------------------------
package Sub::ScopeFinalizer;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK = qw(scope_finalizer);

our $VERSION = '0.02';

1;

# -----------------------------------------------------------------------------
# scope_finalizer {CODE;...};
# scope_finalizer {CODE;...} { args=>[...] };
#  shortcut of Sub::ScopeFinalizer->new(...);
#
sub scope_finalizer(&;@)
{
	Sub::ScopeFinalizer->new(@_);
}

# -----------------------------------------------------------------------------
# Sub::ScopeFinalizer->new(sub{ ... });
# Sub::ScopeFinalizer->new(sub{ ... }, { args=>[...] });
#  create colosing object. it is similar to destructor or finally clause.
#
sub new
{
	my $pkg  = shift;
	my $code = shift;
	my $opts = shift;
	
	my $this = bless {}, $pkg;
	$this->{code}     = $code;
	$this->{args}     = $opts->{args} || undef;
	$this->{disabled} = $opts->{disabled};
	$this;
}

# -----------------------------------------------------------------------------
# $obj->raise();
# $obj->raise({ args => [...] });
#  invoke scope_finalizer code before it run automatically.
#
sub raise
{
	my $this = shift;
	my $opts = shift || {};
	if( !$this->{disabled} )
	{
		my $args = $opts->{args} || $this->{args} || [];
		$this->{code}->(@$args);
		$this->{disabled} = 1;
	}else
	{
		return;
	}
}

# -----------------------------------------------------------------------------
# $obj->disable();
#  disable auto raise.
#
sub disable
{
	my $this = shift;
	$this->{disabled} = @_ ? shift : 1;
	$this;
}

# -----------------------------------------------------------------------------
# DESTRUCTOR.
#  invoke scope_finalizer code.
#
sub DESTROY
{
	my $this = shift;
	$this->raise();
}

# -----------------------------------------------------------------------------
# End of Module.
# -----------------------------------------------------------------------------
__END__

=encoding utf-8

=head1 NAME

Sub::ScopeFinalizer - execute a code on exiting scope.


=head1 VERSION

Version 0.02


=head1 SYNOPSIS

 use Sub::ScopeFinalizer qw(scope_finalizer);
 
 {
   my $anchor = scope_finalizer { print "put clean up code here.\n"; };
   print "running block.\n";
 }

=head1 DESCRIPTION

Sub::ScopeFinalizer invoke BLOCK, triggered by leaving a scope.
It is similar to destructor or finally clause.


=head1 EXPORT

This module exports one function, C<scope_finalizer>.


=head1 FUNCTION

=head2 scope_finalizer

 $o = scope_finalizer BLOCK;
 $o = scope_finalizer BLOCK { args =>[...] };

Create a finalizer object.
This is shortcut to invoke C<< Sub::ScopeFinalizer->new(...) >>.


BLOCK will be executed when object is destroyed.
In other words, process just exits a scope which object is binded on.


Second argument is optional hashref. 
$opts->{args} can contain argument for BLOCK as ARRAYref.


If you only call this function without bind, BLOCK is executed
immediately because object is destroyed as soon as return from function.
Don't forget to bind.


=head1 CONSTRUCTOR

=head2 $pkg->new(CODEref);

=head2 $pkg->new(CODEref, HASHref);

Create a finalizer object.
You must bind it with variable on scope.


See L</scope_finalizer>.


=head1 METHODS

=head2 $obj->raise();

 $obj->raise();
 $obj->raise({args=>[...]});

Invoke finalizer before it run automatically.
This method disables default invokation on scope leaving.


This method takes one argument as optional hashref. 
$opts->{args} can contain argument for BLOCK as ARRAYref.
if $opts->{args} is passed, args parameter on constructor 
is ignored.


=head2 $obj->disable();

 $obj->disable();
 $obj->disable($flag);

Turn off BLOCK invoking.
If optional argument $flag is passwd and it is false, 
cancel disabling, that is, enable invoking.


=head1 AUTHOR

YAMASHINA Hio, C<< <hio at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-sub-scopescope_finalizer at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-ScopeFinalizer>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.


    perldoc Sub::ScopeFinalizer

You can also look for information at:


=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sub-ScopeFinalizer>


=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sub-ScopeFinalizer>


=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-ScopeFinalizer>


=item * Search CPAN

L<http://search.cpan.org/dist/Sub-ScopeFinalizer>


=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 YAMASHINA Hio, all rights reserved.


This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


