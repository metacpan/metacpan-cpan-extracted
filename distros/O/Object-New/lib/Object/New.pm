package Object::New;

use warnings;
use strict;

=head1 NAME

Object::New - A default constructor for standard objects

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

When you want Moose, there is Moose, but when you just want to 
write "standard" Perl5 OO code, there is a bit of boilerplate, 
and "->new" is one bit of it. This module just does just one thing: provide
a sane default constructor you can use for standard Perl5 objects.
(A standard object is here taken to be a blessed hash.)

If you want anything else, there is lots out there: Moose, obviously, 
but also Object::Tiny, and Rose::Object and many others. This modules is
simply an exercise in code reuse, and an attempt to avoid a common
piece of boilerplate.


=head1 THE GUTS

The new routine in all its glory is:

    sub new {
        my $class = shift;
        my $object = {};
        bless $object, $class;
        if $object->can("init") {
            $object->init(@_);
        }
        return $object;
    }

So you get a blessed hash at the end. If your code has a init routine defined 
that an object in its namespace can access, it will call init as well, with the 
argument list passed to new. 

To customise object construction, all you have to do is define an init routine:

  package POW;

  use Object::New;
  use feature "say";

  sub init {
    my $self = shift;
    my ($name, $rank, $serial_number) = @_;
    $self->set_name($name);
    $self->set_rank($rank);
    $self->set_serial_number($serial_number);
  }

  # attribute accessors defined here...

  sub interrogate {
    my $self = shift;
    say join(", ", $self->name, $self->rank, $self->serial_number);
  }

=head1 EXPORT

This module exports one routine by default: "new"

If you don't want to import this, you don't want to be using this module.

=cut

use Exporter 'import';
our @EXPORT = qw/new/;

=head1 SUBROUTINES/METHODS

=head2 new

A default constructor. This returns a reference to a hash, blessed into its
invoking class. If an init method is available, it is called with the argument
list passed to the constructor.

=cut

sub new {
    my $class = shift;
    my $object = {};
    bless $object, $class;
    if ($object->can("init")) {
        $object->init(@_);
    }
    return $object;
}


=head1 AUTHOR

Alex Kalderimis, C<< <alex at gmail dot com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-object-new at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-New>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Object::New


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Object-New>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Object-New>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Object-New>

=item * Search CPAN

L<http://search.cpan.org/dist/Object-New/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alex Kalderimis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Object::New
