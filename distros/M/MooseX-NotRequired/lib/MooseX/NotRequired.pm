package MooseX::NotRequired;

use 5.006;
use strict;
use warnings;
use Moose::Meta::Class;

=head1 NAME

MooseX::NotRequired - Make Moose sub classes with non required attributes.

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';


=head1 SYNOPSIS

This module allows you to create anonymous sub classes of Moose classes with all the
required flags on the attributes turned off.

    package SalesOrder;
    
    use Moose;

    has order_number    => (is => 'ro', isa => 'Str', required => 1);
    has reference       => (is => 'ro', isa => 'Str' );
    has date_ordered    => (is => 'ro', isa => 'DateTime', required => 1);
    has total_value     => (is => 'ro', isa => 'Int', required => 1);
    has customer        => (is => 'ro', isa => 'Str', required => 1);
    has notes           => (is => 'ro', isa => 'Str');

    1;

    ...

    use MooseX::NotRequired;

    my $new_class = MooseX::NotRequired::make_optional_subclass('SalesOrder');
    my $obj = $new_class->new(); # no blow up
    my $default = $new_class->new({ semi_required => undef }); # fine too
    ...
    my $second = ObjectA->new(); # blow up because required fields not present
    my $third = ObjectA->new({ order_number => 'a', semi_required => undef }); 
    # blow up because semi_required must be a string.

This module exists because while you want to make use of Moose's awesome type constraints
they're sometimes a little inconvenient.  Rather than throw out all your restrictions
because you need your class to be a little more permissive in a few scenarios, create
a subclass that has some of those restrictions weakened.  You can of course do this manually.

=head1 SUBROUTINES/METHODS

=head2 make_optional_subclass

This creates an anonymous sub class that has all the required flags on the attributes removed.
It also turns type constraints into Maybe constraints where possible.  That generally only works
for simple isa's like 'Str'.

=cut

sub make_optional_subclass 
{ 
    my $class = shift; 
    
    my $meta = Moose::Meta::Class->create_anon_class(superclasses => [$class], weaken => 0);
    for my $att ($meta->get_all_attributes)
    {
        my $name = $att->name;
        my $options = {};
        if($att->is_required) {
            $options->{required} = 0;
        }
        my $type = $att->{isa}; # FIXME: this is ugly
        unless (!$type || ref $type) {
            unless($type =~ /Maybe/)
            {
                my $new_type = "Maybe[$type]";
                $options->{isa} = $new_type;
            }
        }

        if(%$options) 
        {
            $meta->add_attribute("+$name", $options);
        }
    }
    return $meta->name;
}

=head1 AUTHOR

Colin Newell, C<< <colin.newell at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/colinnewell/MooseX-NotRequired/issues>.  I will be 
notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::NotRequired


You can also look for information at:

=over 4

=item * Github request tracker (report bugs here)

L<https://github.com/colinnewell/MooseX-NotRequired/issues>

=item * Github source code repository

L<https://github.com/colinnewell/MooseX-NotRequired/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-NotRequired>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-NotRequired>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-NotRequired/>

=back


=head1 ACKNOWLEDGEMENTS

This could wouldn't be possible without the help of doy on #moose.  The cool bits were written by
him and the bugs/bad practice added by Colin.  JJ also helped get things going again when I got stuck.
The Birmingham Perl Mongers also provided input which helped refine and improve the module.

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2015 OpusVL.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of MooseX::NotRequired
