package SWISH::API::Object;
use strict;
use warnings;
use Carp;
use base qw( SWISH::API::Stat );
use SWISH::API::Object::Results;

our $VERSION = '0.14';

sub init {
    my $self = shift;

    $self->SUPER::init(@_);    # Stat init()

    $self->mk_accessors(
        qw( properties class stash serial_format filter filter_cache ));

    $self->filter_cache( {} );

    my $i = $self->indexes->[0];    # just use the first one for header vals

    unless ( $self->properties && ref( $self->properties ) ) {
        $self->properties( {} );

        my @p = $self->handle->property_list("$i");
        for (@p) {
            $self->properties->{ $_->name } = $_->id;
        }
    }

    my $d = $self->handle->header_value( $i, 'Description' ) || '';
    my ( $class, $format ) = split( m/\ +/, $d );
    unless ( $self->class ) {
        if ( $class && $class =~ m/class:(\S+)/ ) {
            $self->class($1);
        }
        else {
            $self->class('SWISH::API::Object::Result::Instance');
        }
    }
    unless ( $self->serial_format ) {
        if ( $format && $format =~ m/format:(\S+)/ ) {
            $self->serial_format($1);
        }
        else {
            $self->serial_format('json');
        }
    }

    # this ISA trickery has 2 benefits:
    # (1) a default new() method
    # (2) easy accessor maker
    unless ( $self->class->can('new') ) {
        no strict 'refs';
        push( @{ $self->class . '::ISA' }, 'Class::Accessor::Fast' );
        $self->class->mk_accessors( keys %{ $self->properties } );
    }

}

sub props {
    my $self = shift;
    $self->{_props} ||= [ sort keys %{ $self->properties } ];
    return wantarray ? @{ $self->{_props} } : $self->{_props};
}

1;

__END__

=head1 NAME

SWISH::API::Object - return SWISH::API results as objects

=head1 SYNOPSIS

  use SWISH::API::Object;
  
  my $swish = SWISH::API::Object->new(
                    indexes     => [ qw( my/index/1 my/index/2 )],
                    class       => 'My::Class',
                    properties  => {
                        swishlastmodified => 'result_property_str',
                        myproperty        => 1,
                        },
                    stash       => {
                                dbh => DBI->connect($myinfo)
                                },
                    serial_format => 'yaml',
                    filter      => sub { my ($sao, $result) = @_; return 1 },
                    );
                    
  my $results = $swish->query('foo');
  
  while ( my $object = $results->next ) {
    
    # $object is a My::Class object
    for my $prop ($swish->props) {
        printf("%s = %s\n", $prop, $object->$prop);
    }
    
    # $object also has all methods of My::Class
    printf("mymethod   = %s\n", $object->mymethod);
  }



=head1 DESCRIPTION

SWISH::API::Object changes your SWISH::API::Result object into an object blessed
into the class of your choice.

SWISH::API::Object will automatically create accessor methods for every result
property you specify, or all of them if you don't specify any.

In addition, the result object will inherit all the methods and attributes of
the I<class> you specify. If your I<class> has a B<new()> method, it will be called
for you. Otherwise, a generic new() method will be used.

=head1 REQUIREMENTS

L<SWISH::API::More>

=head1 METHODS

SWISH::API::Object is a subclass of SWISH::API::More. Only new or overridden methods
are documented here.

=head2 new

=over

=item indexes

Same as in SWISH::API::More.

=item class

The class into which your Result object will be blessed. If not specified,
the index header will be searched according to the API specified in SWISH::Prog::Object,
and if no suitable class name is found, will default to 
C<SWISH::API::Object::Result::Instance>, which is a subclass of L<Class::Accessor::Fast>
(whose magic is inherited from L<SWISH::API::More>).

The class should expect at least one property called C<swish_result>
which contains the original SWISH::API::Result object.


=item properties

A hash ref of PropertyNames and their formats. Keys are PropertyNames you'd like
made into accessor methods. Values are the SWISH::API::Property methods you'd like
called on each property value when it is set in the object.

The default is to use all PropertyNames defined in the index, with the default
format.

=item stash

Pass along any data you want to the Result object. Examples might include passing a DBI
handle so your object could query a database directly based on some method you define.
The stash value should be a hash reference, whose keys/values will be merged and supercede
the properties values passed to the B<class> new() method.

=item serial_format

What format should serialized Perl values be assumed to be? The default is C<yaml>.
You might also specify C<json>. If you have serialized values in some other format,
then you'll need to subclass SWISH::API::Object::Result and override deserialize().

If your properties are simple strings, numbers or dates, and you haven't indexed
them as serialized objects, then just set serial_format equal to C<1>.

See L<SWISH::Prog::Object>.

=item filter

Pass in a CODE ref to filter results in the SWISH::API::Object::Results next_result()
method. Your filter should expect two arguments: the SWISH::API::Object object
and a SWISH::API::More::Result object.

Your filter may use the filter_cache() method on the S::A::O object to stash
data between next_result() calls. The default return value of filter_cache() 
is an empty hash ref.

If your filter returns true, the result will be object-ified and returned.
If false, then next_result() will be called again internally and the next
SWISH::API::Result object passed on to your filter.

=back


=head2 class

Get/set the class name passed in new().

=head2 properties

Get/set the I<properties> hash ref passed in new().

=head2 props

Utitlity method. Returns sorted array of property names. Shortcut for:

 sort keys %{ $swish->properties }


=head1 SWISH::API::Object::Result

The internal SWISH::API::Object::Results class is used to extend the SWISH::API
next_result() method with a next_result_after() method. 
See SWISH::API::More for documentation about how the *_after() methods work.

=head1 SEE ALSO

L<SWISH::API>, L<SWISH::API::More>

=head1 AUTHOR

Peter Karman, E<lt>karman@cpan.orgE<gt>

Thanks to L<Atomic Learning|http://www.atomiclearning.com/> for supporting some
of the development of this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
