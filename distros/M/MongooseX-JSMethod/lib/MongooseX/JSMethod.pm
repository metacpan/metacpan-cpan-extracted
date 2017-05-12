package MongooseX::JSMethod;

use Moose::Role;
use MongoDB::Code;
use Carp qw/croak/;
our $VERSION = '0.01';
           
requires qw/save/;

=head1 NAME

MongooseX::JSMethod - Set a method to run MongoDB-server side.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

If you want to create a recursive method to sum the value of a element and all its children (running on Mongo Server):

    package Test;
    use Moose;
    with 'Mongoose::Document';
    with 'MongooseX::JSMethod';
    
    has name     => (is => 'rw', isa => 'Str');
    has value    => (is => 'rw', isa => 'Int');
    has children => (is => 'rw', isa => 'Mongoose::Join[Test]', default => sub{Mongoose::Join->new(with_class => __PACKAGE__)});
                                                                                
    jsmethod(sum => << 'EOJS');                                                 
          var sum = this.value + 0;
          this.children.forEach(function(x){                                    
             sum += x.fetch().sum();
          });
          return sum;
    EOJS
    
    42

=head1 SUBROUTINES/METHODS

=head2 jsmethod

It is the reason of this Role. C<jsmethod()> needs 2 parameter:
The first is the name of the method and the second is a string with the javascript code of your method.
It will create 2 methods, one for perl that will call then second and return what it returns.
The other method is the javascript method, it is what the code you gave to C<jsmethod()> is.
It insert a new field on your document with the code. So if you do something like this with the Test class:

    use Test;
    Mongoose->db("my_database");
    $a = Test->new({name => "The answer", value => 42});
    $a->save;

On MongoDB, it will create the document:

    > db.test.findOne()
    {
    	"_id" : ObjectId("4f9395a1d9507ff008000000"),
    	"value" : NumberLong(42),
    	"name" : "The answer",
    	"children" : [ ],
    	"sum" : function cf__78_anon() {
           var sum = this.value + 0;
           this.children.forEach(function (x) {sum += x.fetch().sum();});
           return sum;
        }
    }

If on your MongoDB shell you run the C<sum()> method:

    > db.test.findOne().sum()
    42

Yes, it runs your method (returns 42).
If you run the perl method it will do the same:

    use Test;
    Mongoose->db("my_database");
    $a = Test->find_one()->sum;
    print $a, $/

Prints 42.

=cut

sub jsmethod {
   my $self   = caller;
   my $name   = shift;
   my $code   = shift;
   my $meta   = $self->meta;
   my $jscode = MongoDB::Code->new({code => $code});
   $meta->add_attribute($name => is => 'ro', default => sub{ $jscode });
   $meta->remove_method($name);
   $meta->add_method($name => sub{
      my $self = shift;
      die "Can not execute a JSMethod if the object wasn't save" unless exists $self->{_id};
      my $id  = $self->{_id};
      my $col = $self->collection->name;
      my $call = qq# return db.${col}.findOne({"_id": ObjectId("$id")}).${name}(); #;
      my $ret = $self->db->eval($call);
      $ret
   });
}     
      

=head1 AUTHOR

Fernando Correa de Oliveira, C<< <fernandocorrea at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mongoosex-jsmethod at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MongooseX-JSMethod>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MongooseX::JSMethod


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MongooseX-JSMethod>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MongooseX-JSMethod>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MongooseX-JSMethod>

=item * Search CPAN

L<http://search.cpan.org/dist/MongooseX-JSMethod/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Fernando Correa de Oliveira.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of MongooseX::JSMethod
