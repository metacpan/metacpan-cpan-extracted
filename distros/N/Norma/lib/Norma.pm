package Norma;

use warnings;
use strict;

=head1 NAME

Norma - easy, limited, Moose-based ORM for the unafraid

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Norma provides a "Mappable" role to compose into your Moose-based modules.  When you compose the role into a class, you map that class to a table in the database.  You can also specify relationships.  With the role composed, columns become attributes, and you have methods available to read and write to that table.  
Schema management is left to you.  You create your tables on your own, and Norma will discover what you've done and adapt accordingly.

=head1 COMPOSING THE ROLE

Here's an example where we compose the role into a class to represent recipes.  The role takes a table name and a database handle at a minimum.

  # create a "recipes" table with an id, title, etc
  mysql> CREATE TABLE recipes (id int auto_increment, title ...)

  # create a class to represent a recipe
  package MyApp::Recipe;

  use Moose;
  with 'Norma::ORM::Mappable' => {
      table_name => 'recipes',
      dbh => $dbh
  };
  
=head1 READING AND WRITING 

Now we have access to CRUD operations on the table.  Here we insert a row with a call to save() after instantiating a new object: 

  my $recipe = MyApp::Recipe->new(
      title => "Scrambled Eggs",
      instructions => "Break two eggs into a bowl...",
      ...
  );
  $recipe->save;

To instantiate an object from an existing row, use load():

  my $recipe = MyApp::Recipe->load( id => 1 );

Update a row by setting attributes and calling save():

  $recipe->title("Delicious Scrambled Eggs");
  $recipe->save;

Delete a row by calling delete() on an instantiated object

  $recipe->delete

=head1 QUERYING FOR COLLECTIONS 

To retrieve a set of objects, use collect() as a class method:

  my $recipes = MyApp::Recipe->collect;

Now we have a Norma::ORM::Collection, which gives us access to instantiated recipe objects, and other metadata about the result set.

  $recipes->items        # => list of instantiated recipe objects
  $recipes->total_count  # => count of matching items

See Norma::ORM::Collection for more about specifying criteria with joins and "where" conditions, etc.

=head1 RELATIONSHIPS

When we compose the role we can also specify relationships.  This is up to us -- there's no magic to try and discover this.  

Assuming we have an "authors" table with an id, name, and email, and assuming we have an author_id column in the "recipes" table, we can specify the relationship:

  package MyApp::Author;

  with 'Norma::ORM::Mappable' => {
      table_name => 'authors',
      dbh => MyApp::DB->new,
  }

  package MyApp::Recipe;

  with 'Norma::ORM::Mappable' => {
      table_name => 'recipes',
      dbh => MyApp::DB->new,
      relationships => [
          {
              name => 'author'
              class => 'MyApp::Author',
              nature => 'belongs_to'
          }
      ]
  };
  
With the relationship defined, now we can access the author through the recipe:

  my $recipe = MyApp::Recipe->load(...);
  $recipe->author; # => MyApp::Author object

This related data is loaded lazily, only when we ask for it.  For has_many relationships, we get back a Collection instead of an instantiated object.

For more see L<Norma::ORM::Mappable> and L<Norma::ORM::Collection>.

=head1 SEE ALSO

L<Norma::ORM::Mappable>, L<Norma::ORM::Collection>

=head1 AUTHOR

David Chester <davidchester@gmx.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2011 by David Chester.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

1;
