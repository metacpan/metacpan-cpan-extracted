package Rose::ObjectX::CAF;
use warnings;
use strict;
use base qw( Rose::Object );
use Carp;
use Rose::ObjectX::CAF::MethodMaker;

our $VERSION = '0.03';

=head1 NAME

Rose::ObjectX::CAF - Class::Accessor::Fast compatability for Rose::Object

=head1 SYNOPSIS

 package MyClass;
 use strict;
 use base qw( Rose::ObjectX::CAF );
 __PACKAGE__->mk_accessors(qw( foo bar ));
 __PACKAGE__->mk_ro_accessors(qw( color name ));
 1;
 
=head1 DESCRIPTION

Rose::ObjectX::CAF is a compatability layer for Class::Accessor::Fast users who
want to migrate to Rose::Object.

As evidenced in L<App::Benchmark::Accessors>, 
L<Rose::Object> + L<Class::XSAccessor> is
much faster than Class::Accessor::Fast (and more extensible). 
I decided to switch over, but had a lot of code already using CAF. 
So this class was born to make the migration easier.

Just replace this line in your classes:

 use base qw( Class::Accessor::Fast );

with this:

 use base qw( Rose::ObjectX::CAF );

and no other changes should be necessary.

=head1 METHODS

=head2 new

Works like CAF, but may take a hash (the Rose::Object style)
or hash ref (the CAF style).

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->init( @_ > 1 ? @_ : %{ $_[0] } );
    return $self;
}

=head2 init

Like Rose::Object, called by new(). Do not override new() in your
subclasses; override init() instead. And be sure to call:

 $self->SUPER::init(@_);  # or with MRO::Compat, $self->next::method(@_);

in your subclass.

Rather than calling
the method name for each param passed in new(), the value
is simply set in the object as a hash ref. This assumes
every object is a blessed hash ref.

The reason the hash is preferred over the method call
is to support read-only accessors, which will croak
if init() tried to set values with them.

=cut

sub init {
    my $self = shift;

    # assume object is hash and set key
    # rather than call method, since we have read-only methods.
    while (@_) {
        my $method = shift;
        if (!$self->can($method)) {
            croak "No such method $method";
        }
        $self->{$method} = shift;
    }

    return $self;
}

=head2 mk_accessors( I<@list_of_method_names> )

Just like CAF.

=cut

sub mk_accessors {
    my $class = shift;
    Rose::ObjectX::CAF::MethodMaker->make_methods(
        { target_class => $class, },
        scalar => \@_ );
}

=head2 mk_ro_accessors( I<@list_of_method_names> );

Just like CAF, for read-only (accessor/getter) methods.

=cut

sub mk_ro_accessors {
    my $class = shift;
    Rose::ObjectX::CAF::MethodMaker->make_methods(
        { target_class => $class, },
        'scalar --ro' => \@_ );
}

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rose-objectx-caf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rose-ObjectX-CAF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rose::ObjectX::CAF


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-ObjectX-CAF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rose-ObjectX-CAF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Rose-ObjectX-CAF>

=item * Search CPAN

L<http://search.cpan.org/dist/Rose-ObjectX-CAF/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Rose::ObjectX::CAF
