package Perl6::Caller;

use warnings;
use strict;

our $VERSION = '0.100';
$VERSION = eval $VERSION;

use overload '""' => \&package, fallback => 1;

sub import {
    my ($class) = @_;
    my $callpack = caller;
    no strict 'refs';
    *{"$callpack\::caller"} = \&caller;
}

sub caller {
    my $thing = shift || 0;
    my $frame =
      __PACKAGE__ eq $thing
      ? ( shift || 0 )
      : $thing;
    return __PACKAGE__->new($frame);
}

my @methods;

BEGIN {
    @methods = qw/package filename line subroutine hasargs
      wantarray evaltext is_require/;
    foreach my $method (@methods) {
        no strict 'refs';
        *$method = sub {
            my ( $self, $frame ) = @_;
            return $self->{$method};
        };
    }
}

sub new {
    my $class = shift;
    my $frame = @_ ? (shift || 0) : -1;
    $frame += 2;

    my $self = bless {} => __PACKAGE__;
    my @caller = CORE::caller($frame);
    return @caller if CORE::wantarray;
    @$self{@methods} = @caller;
    return $self;
}

1;

__END__

=head1 NAME

Perl6::Caller - OO C<caller()> interface

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

 use Perl6::Caller;

 my $sub         = caller->subroutine;
 my $line_number = caller->line;
 my $is_require  = caller(3)->is_require;

=head1 EXPORT

=head1 C<caller>

 # standard usage
 print "In ",           caller->subroutine,
       " called from ", caller->file,
       " line ",        caller->line;

 # get a caller object
 my $caller = caller;
 my $caller = caller();   # same thing

 # get a caller object for a different stack from
 my $caller = caller(2);  # two stack frames up
 print $caller->package;  # prints the package name

 # enjoy the original flavor
 my @caller = caller;     # original caller behavior
 print $caller[0],        # prints the package name

=head1 DESCRIPTION

This module is experimental.  It's also alpha.  Bug reports and patches
welcome.

By default, this module exports the C<caller> function.   This automatically
returns a new C<caller> object.  An optional argument specifies how many stack
frames back to skip, just like the C<CORE::caller> function.  This lets you do
things like this:

 print "In ",           caller->subroutine,
       " called from ", caller->file,
       " line ",        caller->line;

If you do not wish the C<caller> function imported, specify an empty import
list and instantiate a new C<Perl6::Caller> object.

 use Perl6::Caller ();
 my $caller = Perl6::Caller->new;
 print $caller->line;

B<Note>:  if the results from the module seem strange, please read 
S<perldoc -s caller> carefully.  It has stranger behavior than you might be
aware.

=head1 METHODS

The following methods are available on the C<caller> object.  They return the
same values as documented in S<perldoc -f caller>.

There are no C<hints> and C<bitmask> methods because those are documented as
for internal use only.

=over 4

=item * C<package>

=item * C<filename>

=item * C<line>

=item * C<subroutine>

=item * C<hasargs>

=item * C<wantarray>

=item * C<evaltext>

=item * C<is_require>

=back

Note that each of these values will report correctly for when the caller
object was created.  For example, the following will probably print different
line numbers:

 print caller->line;
 foo();
 sub foo { 
    print caller->line;
 }

However, the following will print the I<same> line numbers:

 my $caller = Perl6::Caller->new;   # everything is relative to here
 print $caller->line;
 foo($caller);
 sub foo { 
    my $caller = shift;
    print $caller->line;
 }

=cut
=head1 CAVEATS

Most of the time, this package should I<just work> and not interfere with
anything else.

=over 4

=item * C<$hints>, C<$bitmask>

'hints' and 'bitmask' are not available.  They are documented to be for
internal use only and should not be relied upon.  Further, the bitmask caused
strange test failures, so I opted not to include them.

=item * Subclassing

Don't.

=item * Perl 6

I'm not entirely comfortable with the namespace.  The S<Perl 6> caller
actually does considerably more, but for me to have a hope of working that in,
I need proper introspection and I don't have that.  Thus, I've settled for
simply having a caller object.

=item * C<*CORE::GLOBAL::caller>

I didn't implement this, though I was tempted.  It turns out to be a bit
tricky in spots and I'm very concerned about globally overriding behavior.  I
might change my mind in the future if there's enough demand.

=item * Overloading

In string context, this returns the package name.  This is to support the
original C<caller> behavior.

=item * List Context

In list context, we simply default to the original behavior of
C<CORE::caller>.  However, this I<always> assumes we've called caller with an
argument.  Calling C<caller> and C<caller(0)> are identical with this module.
It's difficult to avoid since the stack frame changes.

=back

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid@cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Thanks to C<phaylon> for helping me revisit a bad design issue with this.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-perl6-caller@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl6-Caller>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
