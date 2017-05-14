package MyLibrary;

=head1 NAME

MyLibrary tutorial - an overview of how to use the MyLibrary modules

=head1 DESCRIPTION

This tutorial gives the reader an overview of how to use the MyLibrary modules. It is only an introduction. The reader is expected to understand the principles of basic object-oriented Perl programming.

By the end of the tutorial the reader should be able to: create sets of facets, create sets of terms, create sets of librarians, create sets of location types, create sets of resources, classify librarians and resources with terms, work with sets of resources assoicated with particular sets of terms, output the resources' titles, descriptions and locations, create a freetext index of MyLibrary content, harvest OAI repositories and cache the content in a MyLibrary database.


=head2 Initialization

To include MyLibrary into your scripts you "use" it:

  # include the whole of MyLibrary
  use MyLibrary::Core;

This will enable all the necessary modules. You can use selected modules if you so desire. This will save you a bit of RAM and compile time, but not a whole lot. For example:

  # include just selected modules
  use MyLibrary::Facet;
  use MyLibrary::Term;

Make your life easy. Just include the whole of MyLibrary. See MyLibrary::Core's pod for more information.


=head2 Configuration

Each installation of the MyLibrary modules is configured, by default, to work against at least one MyLibrary instance. This instance was created during the make process. When you include MyLibrary::Core, the default instance will be read from and written to.

If you want to read and write to a different instance of MyLibrary, then you will need to use the MyLibrary::Config methods to specify the database options for that instance.


=head2 Facets

One of the first things you will want to do with any MyLibrary instance is create a set of facets.

Facets are a set of broad classification headings. Most instances of MyLibrary will contain some sort of Subjects facet to denote the "aboutness" of items. Other possible facets include Formats or Audiences. Formats could denote the physical manifestations of information resources. Audiences might denote who are the intended users of information resources.

Here are a number of ways to create and manipulate facet objects:

  # create a facet object
  $facet = MyLibrary::Facet->new;
  
  # set the facet's name and note
  $facet->facet_name('Subjects');
  $facet->facet_note('The "aboutness" of items');
  
  # save the facet to the database
  $code = $facet->commit;
  if ($code ne 1) { die 'commit failed' }
  
  # get the facet's id; think "database key"
  $id = $facet->facet_id;
  
  # get the facet's name and note
  $name = $facet->facet_name;
  $note = $facet->facet_note;
  
  # get a specific facet based on an id
  $facet = MyLibrary::Facet->new(id => 1);
  
Given the methods outlined above, you could use the following code to create, save, retrieve, and then display a facet:

  # configure
  $name = 'Formats';
  $note = 'The physical manifestation of resources';
  
  # create, save, retrieve, and display
  $facet = MyLibrary::Facet->new;
  $facet->facet_name($name);
  $facet->facet_note($note);
  
  # save
  $facet->commit;
  $id = $facet->facet_id;
  
  # retrieve
  $facet = MyLibrary::Facet->new(id => $id);
  
  # display
  print '  ID: ' . $facet->facet_id   . "\n";
  print 'Name: ' . $facet->facet_name . "\n";
  print 'Note: ' . $facet->facet_note . "\n";
  
You will often want to get a list of all the facets in your system in order to facilitate browsable interfaces to your collection of resources. The get_facets method is used for this purpose. Since get_facets returns an array of objects, you can now loop through the array and process each item. This is how you might display them:


  # create a list of all the facets in the system
  @facets = MyLibrary::Facet->get_facets;
  
  print "ID\tName\t(Note)\n";
  foreach $f (@facets) {

    print $f->facet_id   . "\t" . 
          $f->facet_name . "\t(" . 
          $f->facet_note . ")\n"
  
  }
  
Read the scripts named manage-facets.pl and subroutines.pl to see an example of how to manage sets of facets from a terminal-based interface. For more information read the pod of MyLibrary::Facets.


=head2 Terms

Terms are a set of narrower classification headings, and each term is associated with one and only one facet -- its parent. Terms are expected to be the controlled vocabulary of your MyLibrary implementation, and consequently they are expected to be assigned to one or more information resources. Terms might include Astronomy, Music, or Mathematics, and these terms may have a parent facet named Subjects. Other terms might be Book, Journal, or Image, and these terms might be associated with a facet called Formats. Still other examples include Catalog, Dictionary, or Encyclopedia, and could associated with a facet named Research Tools.

The methods of MyLibrary term objects are very similar to the methods of facet objects:

  # create a term object
  $term = MyLibrary::Term->new;
  
  # set the term's name and note
  $term->term_name('Dictionary');
  $term->term_note('A list of word definitions');
  
  # create a facet named Research Tools
  $facet = MyLibrary::Facet->new;
  $facet->facet_name('Research Tools');
  $facet->facet_note('Traditional library objects like dictionaries.');
  $facet->commit;
    
  # associate (join) this term to that facet
  $term->facet_id($facet->facet_id);
  
  # save the term to the database
  $code = $term->commit;
  if ($code ne 1) { die 'commit failed' }
  
  # get the term's id; think "database key"
  $id = $term->term_id;
  
  # get the term's name and note
  $name = $term->term_name;
  $note = $term->term_note;
  
  # get a specific term based on its id
  $term = MyLibrary::Term->new(id => 1);

Given the methods outlined above, you could use the following code to create, save, retrieve, and then display relevant term data:

  # configure
  $term_name  = 'Sophomores';
  $term_note  = 'Students in the second year of college';
  $facet_name = 'Audiences';
  $facet_note = 'People who use your services';
  
  # create a term
  $term = MyLibrary::Term->new;
  $term->term_name($term_name);
  $term->term_note($term_note);

  # create a facet 
  $facet = MyLibrary::Facet->new;
  $facet->facet_name($facet_name);
  $facet->facet_note($facet_note);
  $facet->commit;

  # join and save
  $term->facet_id($facet->facet_id);
  $term->commit;
  
  # get and display
  $id = $term->term_id;
  $term = MyLibrary::Term->new(id => $id);
  $facet = MyLibrary::Facet->new(id => $term->facet_id);
  print '    ID: ' . $term->term_id     . "\n";
  print '  Name: ' . $term->term_name   . "\n";
  print '  Note: ' . $term->term_note   . "\n";
  print 'Parent: ' . $facet->facet_name . "\n";

Like the facets, you will often want to get a list of all the terms in your system in order to facilitate some sort of browse function. The get_terms method is used for this purpose:

  # get all the terms
  @terms = MyLibrary::Term->get_terms;
  foreach $term (@terms) { print 'Term: ' . $term->term_name . "\n" }

Creating a list of sorted terms involves creating a list of term ids and calling the sort method denoting the sorting field, usually name:

  # get all terms
  @terms = MyLibrary::Term->get_terms;

  # print
  foreach $t (@terms) { print 'Term: ' . $t->term_name . "\n" }
  
  # create a list of term ids
  foreach $t (@terms) { push @term_ids, $t->term_id }
    
  # get a sorted list of term id 
  @terms = MyLibrary::Term->sort(term_ids => [@term_ids],
                                     type => 'name');

  # print, again
  foreach $t (@terms) {
  
    $term = MyLibrary::Term->new(id => $t);
    print 'Term: ' . $term->term_name . "\n";
    
  }
  
After terms have been assigned to MyLibrary resource objects a number of other useful term methods present themselves, but they are outlined in a later section named "Terms and resources revisited".

Read the scripts named manage-terms.pl and subroutines.pl to see how you can manage sets of terms from a terminal-based interface. For more detail read the MyLibrary::Term pod.


=head2 Librarians

Question: What do libraries have that Yahoo and Google don't have? Answer: Librarians -- people who are willing and able to address the information needs of others. That is why librarian objects are a part of MyLibrary.

Think of librarian objects as information resources with the characteristics of people: name, address, telephone number, and URL of home page. In libraries librarians usually have subject specialties, and that is why it is possible to "catalog" librarians with facet/term combinations.

The setting and getting of MyLibrary librarian objects works like this:

  # create a librarian
  $librarian = MyLibrary::Librarian->new;
  
  # give the librarian characteristics
  $librarian->name('Fred Kilgour');
  $librarian->email('kilgour@oclc.org');
  $librarian->telephone('1 (800) 555-1212');
  $librarian->url('http://oclc.org/~kilgour/');
  
  # create an astronomy term as a child of the subjecs facet
  $term = MyLibrary::Term->new;
  $term->term_name('Astronomy');
  $term->term_note('Studying the stars');
  $facet = MyLibrary::Facet->new(name => 'Subjects');
  $term->facet_id($facet->facet_id);
  $term->commit;
  
  # associate (join) the librarian with astronomy
  $librarian->term_ids(new => [$term->term_id]);
  
  # save the librarian
  $librarian->commit;
  
  # get the librarian
  $id = $librarian->id;
  $librarian = MyLibrary::Librarian->new(id => $id);
  
  # display basic information about the librarian
  print '       ID: ', $librarian->id, "\n";
  print '     Name: ', $librarian->name, "\n";
  print '    Email: ', $librarian->email, "\n";
  print 'Telephone: ', $librarian->telephone, "\n";
  print 'Home page: ', $librarian->url, "\n";
  
  # display each of their associated subject areas
  @term_ids = $librarian->term_ids;
  foreach $id (@term_ids) {
  
    $term = MyLibrary::Term->new(id => $id);
    print '    Term: ', $term->term_name, "\n";
  
  }

Just like everything else, you might want to pull all of the librarians out of the system. The class method get_librarians is used for this purpose. It returns an array of librarian objects:

  # get all librarians
  @librarians = MyLibrary::Librarian->get_librarians;
  
  # print each librarian's name and email address
  foreach $l (@librarians) { print $l->name . ' <' . $l->email . ">\n" }

Question: Who are you going to call? Answer: The Librarian. By creating a set of facet/term combinations and associating them with information resources you can effectively group like things together. By associating the same facet/term combinations to librarians you can begin to make connections between information resources and librarians. Thus, when displaying lists of information resources, consider adding the associated librarian's name and contact information to the list.

For more detail regarding librarian objects read the MyLibrary::Librarian pod.


=head2 Location types

The world of information resources is made up of many different types. For example there are books, journals, and websites. To complicate matters, things like the same books or journals can be manifested in physical or digital form. Heck, the book or journal could even exist in a number of physical forms such as a codex or microfiche or maybe even a film. Because of these things a single information resource may have many different locations and each of these locations may be of different types: call numbers, URL's, buildings, etc. Because all information resources have some sort of location will need to create at least one location type in your MyLibrary implementation.

Location types are just labels for different types of locations. For example, almost all MyLibrary implementations will have a location type such as Internet Resource, or URL. If the information resources in your MyLibrary implementation includes books -- physical, every-day books -- then another location type for your implementation might be Call Numbers. Suppose you have an electronic journal and one URL associated with the journal is a pointer to the content and another URL points to a help file. In this case you might want to have an additional location type such as Help Location.

Here are an example of how you might implement a simple Internet resource location type:

  # create a location type
  $location_type = MyLibrary::Resource::Location::Type->new;
  
  # give it characteristics
  $location_type->name('URL');
  $location_type->description('A type of Internet resource');
  
  # save it and get its id
  $location_type->commit;
  $id = $location_type->location_type_id;
  
  # get a location by an id and display its data
  $location_type = MyLibrary::Resource::Location::Type->new(id => $id);
  print '   ID: ' . $location_type->location_type_id . "\n";
  print ' Type: ' . $location_type->name . "\n";
  print ' Note: ' . $location_type->description . "\n";

Like most of the other modules, MyLibrary::Resource::Location::Type provide a class method for getting everything. In this case it is all_types, and it returns an array of location type ids:

  # get all location types
  @location_types = MyLibrary::Resource::Location::Type->all_types;
  
  # display them
  foreach $l (@location_types) {
  
    $location = MyLibrary::Resource::Location::Type->new(id => $l);
    print 'Type: ' . $location->name . "\n";
    
  }

You can also create a location type object by calling it by name, but the name must exist in the underlying database. To do this you supply the name parameter to the new method:

  # get the location type object named URL
  $location_type = MyLibrary::Resource::Location::Type->new(name => 'URL');
  
  # print
  print '  Location type ID: ' . $location_type->location_type_id . "\n";
  print 'Location type name: ' . $location_type->name             . "\n";
  print 'Location type note: ' . $location_type->description      . "\n";
  
Because information resources are manifested in many ways, and since each of these ways are usually associated with different types of "addresses" (such as URLs or call numbes) MyLibrary provides as means of creating and listing such types.

See the terminal-based program called location-types.pl as well as the pod for MyLibrary::Resource::Location::Type for more detail.


=head2 Resources

Now the fun really begins.

With the exception of the librarians, all of the previous sections essentially described how to create sets of controlled vocabularies. Facets. Terms. Location types. You are now ready to create lists of information resources, describe them, classify them, and save them to the underlying database. Once you have built your collection you are expected to write reports against it implementing various services such as: browse, search, What's New?, Find More Like This One, most popular, most useful, export subsets to a file, send subsets as email, create RSS feeds, etc. In today's world of changing user expectations it is not only about collections. It is more about the effective combination of collections and services.

MyLibrary resource objects include methods for setting and getting the objects' characteristics, and these characteristics are a superset of the basic fifteen Dublin Core elements. There is an implicit one-to-one relationship between the basic Dublin Core element names and many of the MyLibrary resource object methods/objects, listed below: 

  1. contributor --> MyLibrary::Resource->contributor 
  2. coverage    --> MyLibrary::Resource->coverage
  3. creator     --> MyLibrary::Resource->creator
  4. date        --> MyLibrary::Resource->date
  5. description --> MyLibrary::Resource->note
  6. format      --> MyLibrary::Resource->format
  7. identifier  --> MyLibrary::Resource::Location
  8. language    --> MyLibrary::Resource->language
  9. publisher   --> MyLibrary::Resource->publisher
 10. relation    --> MyLibrary::Resource->relation
 11. rights      --> MyLibrary::Resource->rights
 12. source      --> MyLibrary::Resource->source
 13. subject     --> MyLibrary::Resource->subject
 14. title       --> MyLibrary::Resource->name
 15. type        --> MyLibrary::Resource->type

This mapping makes it relatively easy to store Dublin Core-based descriptions of information resources into a MyLibrary implementation. The items described in OAI-PMH data repositories come immediately to mind. 

As a simple example of setting and getting values of MyLibrary resource objects, let's set and get a link to a fictional electronic version of The Adventures of Huckleberry Finn:

  # create a resource object
  $resource = MyLibrary::Resource->new;
  
  # describe it
  $resource->creator('Mark Twain');
  $resource->format('ebook');
  $resource->language('en');
  $resource->name('The Adventures of Huckleberry Finn');
  $resource->note('This is a coming of age story.');
  $resource->subject('young adult reading');
  $resource->type('text/html');
  
  # give it a URL
  $location_type = MyLibrary::Resource::Location::Type->new(name => 'URL');
  $resource->add_location(location      => 'http://library.org/finn.html',
                          location_type => $location_type->location_type_id);

  # save it
  $resource->commit;

  # get it
  $id = $resource->id;
  $resource = MyLibrary::Resource->new(id => $id);
  
  # output the data
  print '      Author: ' . $resource->creator     . "\n";
  print '      Format: ' . $resource->format      . "\n";
  print '    Language: ' . $resource->language    . "\n";
  print '       Title: ' . $resource->name        . "\n";
  print ' Description: ' . $resource->note        . "\n";
  print '     Subject: ' . $resource->subject     . "\n";
  print '   MIME type: ' . $resource->type        . "\n";

  # get the url; assume there is only one 
  @locations = $resource->resource_locations;
  print '         URL: ' . $locations[0]->location . "\n";

With the exception of the location attributes, this should be pretty straight-forward. (Remember, information resources can have more than one location and more than one location type. This is why setting and getting the location of resource objects is not as simple as the other attributes.)

While the procedure outlined above is functional, it is not necessarily complete. It does not take advantage of your facet/term combinations. Let's assume you have a facet called Subjects. Let's also assume you have the terms American Literature and Young Adult Reading assigned to the Subjects facet. Given this you can use the related_terms method to classify a resource with these terms. Very, very important! To get the terms back out you again use the related_terms method. It returns an array of term ids (keys):

  # get the facet id for subjects
  $facet = MyLibrary::Facet->new(name => 'Subjects');
  $facet_id = $facet->facet_id;
  
  # create the subject term amerian literature
  $term = MyLibrary::Term->new;
  $term->term_name('American Literature');
  $term->term_note('Writings of the New World');
  $term->facet_id($facet_id);
  $term->commit;
  $american_literature = $term->term_id;
  
  # create the subject term young adult reading
  $term = MyLibrary::Term->new;
  $term->term_name('Young Adult Reading');
  $term->term_note('Literature for the middle schoolers');
  $term->facet_id($facet_id);
  $term->commit;
  $young_reading = $term->term_id;
  
  # get huck finn and assume there is only one matching record
  @resources = MyLibrary::Resource->new(
    name => 'The Adventures of Huckleberry Finn');
  $resource = $resources[0];
  $resource->related_terms(new => [$american_literature, $young_reading]);
  $resource->commit;

  # output the data
  print '      Author: ' . $resource->creator     . "\n";
  print '      Format: ' . $resource->format      . "\n";
  print '    Language: ' . $resource->language    . "\n";
  print '       Title: ' . $resource->name        . "\n";
  print ' Description: ' . $resource->note        . "\n";
  print '     Subject: ' . $resource->subject     . "\n";
  print '   MIME type: ' . $resource->type        . "\n";

  # get the url; assume there is only one 
  @locations = $resource->resource_locations;
  print '         URL: ' . $locations[0]->location . "\n";

  # get the related terms
  @related_terms = $resource->related_terms;
  foreach $rt (@related_terms) {
 
    # print the term name
    $term = MyLibrary::Term->new(id => $rt);
    print '       Term : ' . $term->term_name . "\n";
    
  }
  
Read manage-resources.pl, subroutines.pl to learn how to implement these ideas in a terminal-based environment. See the pod of MyLibrary::Resource for more detail because there are many more methods to be found there.

A Zen Master once said, "Collections without services are useless, and services without collections are empty." Use MyLibrary to create a collection of information resources, and then use MyLibrary to provide services against the collection. Both are necessary in order to meet the expectations of today's users of libraries.


=head2 Terms and resources revisited

Once you have created sets of MyLibrary resources and associated them with sets of MyLibrary terms you can exploit a couple more term methods to query your MyLibrary database.

You can use the MyLibrary::Term class method called related_resources to create a list of resources associated with a term. For example, suppose you have a term named Astronomy, then you could use the following code to list the names and descriptions of all those resources:

  # require the necessary modules
  use MyLibrary::Term;
  use MyLibrary::Resource;

  # get the id for the astronomy term, assume there is only one
  @terms = MyLibrary::Term->get_terms(field => 'name', value => 'Astronomy');
  $term = MyLibrary::Term->new(id => @terms[0]->term_id);
  $astronomy = $term->term_id;

  # create astronomy resources, #1 of 3
  $resource = MyLibrary::Resource->new;
  $resource->name('Stars amoung us');
  $resource->note('No, not movie stars');
  $resource->related_terms(new => [$astronomy]);
  $resource->commit;

  # resource #2 of 3
  $resource = MyLibrary::Resource->new;
  $resource->name('Guiding lights');
  $resource->note('Soap operas and beyond');
  $resource->related_terms(new => [$astronomy]);
  $resource->commit;

  # resource #3 of 3
  $resource = MyLibrary::Resource->new;
  $resource->name('My Guide the the Galaxy');
  $resource->note('As if the Hitchhikers was not good enough');
  $resource->related_terms(new => [$astronomy]);
  $resource->commit;

  # get all astronomy resources through the term
  $term = MyLibrary::Term->new(id => $astronomy);
  @resource_ids = $term->related_resources;
  
  # display information about the resources
  foreach $id (@resource_ids) {
  
  	$resource = MyLibrary::Resource->new(id => $id);
  	print ' Name: ' . $resource->name . "\n";
  	print ' Note: ' . $resource->note . "\n\n";
  
  }

The suggested_resources method allows you to set and get lists of resource ids determined to be particularly useful. Think recommendations. For example, suppose there is a resource called Most Cool Astronomy Site. Suppose also it is determined that this particular site lives up to its name and when displaying lists of astronomy resources you would like to highlight this one in particular. To do this you would first use the suggested_resources method set this value:

  # get the id for astronomy; assume there is only one astronomy-like term
  @terms = MyLibrary::Term->get_terms(field => 'name', value => 'Astronomy');
  $term = MyLibrary::Term->new(id => @terms[0]->term_id);
  $astronomy = $term->term_id;

  # create an astronomy resource
  $resource = MyLibrary::Resource->new;
  $resource->name('Most Cool Astronomy Site');
  $resource->related_terms(new => [$astronomy]);
  
  # save and get its id (key)
  $resource->commit;
  $id = $resource->id;
 
  # get the astronomy term
  $term = MyLibrary::Term->new(id => $astronomy);
  
  # denote our resource as a suggested item for astronomy, and save
  $term->suggested_resources(new => [$id]);
  $term->commit;

You can then list all the resources associated with a term and then specify which ones are recommended:

  # get the id for astronomy; assume there is only one astronomy-like term
  @terms = MyLibrary::Term->get_terms(field => 'name', value => 'Astronomy');
  $term = MyLibrary::Term->new(id => @terms[0]->term_id);
  
  # get all astronomy resource ids and suggestion ids
  @resources   = $term->related_resources(sort => 'name');
  @suggestions = $term->suggested_resources;

  # process each resource
  foreach $r (@resources) {
  
  	# get the resource and print its name
  	$resource = MyLibrary::Resource->new(id => $r);
  	print ' Name: ' . $resource->name;
  	
  	# loop through each suggestion
  	foreach $s (@suggestions) {
  	
  	  # compare suggestion and resource ids
  	  if ($s == $r) {
  	  
  	    # specify this as suggested resource
  	    print ' (suggested)';
  	    last;
  	    
  	  }
  	
  	}
  
    print "\n";
    
  }

You will often want work with entire sets or subsets of resources from your MyLibrary implementation, and the get_resources method is used for this purpose. Once you get the set of resources you are expected to loop through them and extract the ones you really need. Here is a simple way to get all the resources as objects and print their names:

  # get all resources and display
  @resources = MyLibrary::Resource->get_resources;
  foreach $resource (@resources) { print $resource->name . "\n" }

You can do the same thing, but return a sorted list

  # get a sorted list, by name, of resources
  @resources = MyLibrary::Resource->get_resources(sort => 'name');
  foreach $resource (@resources) { print $resource->name . "\n" }
  
Besides the basic Dublin Core elements, MyLibrary allows you to assign additional attributes to resources. The first of note is foreign key through the fkey method. This is intended to store things like OCLC numbers, catalog record numbers, or OAI identifiers in MyLibrary resource objects. By combining the fkey values with things like URL it is often possible to link to back to some other list of information resources. You set and get fkey values just like most of the other attributes:

  # create a resource
  $resource = MyLibrary::Resource->new;
  
  # set the name and fkey value
  $resource->name('Tom Sawyer Rides Again');
  $resource->fkey('123457');
  $resource->commit;
  
  # print it
  print ' Foreign key: ' . $resource->fkey . "\n";
  
The lcd ("lowest common denominator") method is intended to denote information resources that are useful to anybody, not restricted to any MyLibrary term. For example, most librarians will believe the catalog is a tool useful for everybody for every discipline. A general encyclopedia and dictionary are other examples. Denote a resource as a "lowest common denominator" resource like this:

  # create and denote a resource as an "lcd" resource
  $resource = MyLibrary::Resource->new;
  $resource->name('Library catalog');
  $resource->lcd(1);
  $resource->commit;

To get a list of all the resource objects denoted as lowest common denominator resources, use the class method lcd_resources:

  # get all "lcd" resources and display
  @lcd_resources = MyLibrary::Resource->lcd_resources;
  print "These resources are useful to everyone:\n";
  foreach $r (@lcd_resources) { print "\t" . $r->name . "\n" }

Through the qsearch_prefix, qsearch_suffix, and qsearch_redirct methods you are able to reverse engineer many Internet search engines. Take a simple Google search for the word cat, http://www.google.com/search?q=cat. This URL can be divided into at least three parts: 1) the root (http://www.google.com/), 2) a prefix (search?q=), 3) the query itself (cat), and 4) an optional suffix (null in this example).
  
You might use this code to create a resource for Google and add a search prefix to it:

  # create a resource describing Google
  $resource = MyLibrary::Resource->new;
  $resource->name('Google');
  $resource->note('A very popular Internet index');
  
  # get the location type of URL
  $location_type = MyLibrary::Resource::Location::Type->new(name => 'URL');
  $type_id = $location_type->location_type_id;
    
  # give the resource a URL
  $resource->add_location(location => 'http://www.google.com/',
                          location_type => $type_id);
  
  # add a quick search prefix and save
  $resource->qsearch_prefix('search?q=');
  $resource->commit;
  $id = $resource->id;

  # begin echoing results
  $resource = MyLibrary::Resource->new(id => $id);
  print '  Title: ' . $resource->name . "\n";
  print '   Note: ' . $resource->note . "\n";
  
  # get the location; assume there is only one 
  @locations = $resource->resource_locations;
  
  # echo more results
  print '    URL: ' . $locations[0]->location . "\n";
  print ' Prefix: ' . $resource->qsearch_prefix . "\n";
  
Now suppose you have some sort of HTML form that accepts text input. Using the qsearch_redirect method the input can be transformed into a URL to search the resource. Something like this:

  # get a query
  $query = 'foobar';
  
  # get the Google resource; assume there is only one
  @resources = MyLibrary::Resource->new(name => 'Google');
  $resource  = $resources[0];
  
  # get the location; assume there is only one 
  @locations = $resource->resource_locations;
  $root_url  = $locations[0]->location;
  
  # build a URL to search
  $url = $resource->qsearch_redirect(resource_id => $resource->id, 
                                     qsearch_arg => $query,
                                     primary_location => $root_url);
  
  # display in an HTML snippet
  print "<a href='$url'>Click here</a> to search Google for '$query'.\n";

Take this technique a step further. Suppose your MyLibrary implementation contains records from your library catalog. Suppose each MyLibrary resource record includes an fkey value pointing to the full record in the catalog. Suppose that you also have a MyLibrary record describing your catalog, and that record is complete with a qsearch_prefix and optional qsearch_suffix values. Using the qsearch_redirect method you could display brief records on a Web page and link back to the full record in your library catalog by using the fkey value as the qsearch_arg attribute.


=head2 Implementing search

This section outlines a method for making the content of your MyLibrary implementation searchable.

MyLibrary is essentially a relational database application. As such, searching the database requires queries be converted into SQL. By definition these SQL queries must specify what fields to search. Unfortunately people expect to perform freetext queries against sets of content, not necessarily fielded searches. Moreover, people increasingly expect relevancy ranked output as well as output sorted by this, that, and the other thing. For these reasons you are encouraged to use an intermediary indexing application to implement searchability instead of querying the database directly.

Making your MyLibrary content searchable through an intermediate indexer uses this process:

 1. Write a report against MyLibrary.
 2. Feed the report to the indexer.
 3. Index the report.
 4. Provide a Perl interface to search the index.
 5. Search results are integers -- MyLibrary database keys.
 6. Use the keys to get data from MyLibrary.
 7. Reformat the data for display and return it to the user.

Swish-e is a good indexer. Simple, fast, and it comes with a Perl API. This will be the indexer in this example, but something like Plucene would work just as well.

The first step is to write a report against the MyLibrary database. Swish-e expects its input to look much like HTML. The following code outputs a very simple report containing only the titles and notes of every resource in a MyLibrary instance. The report is in a form swish-e expects:

  # require
  use MyLibrary::Resource;
  
  # first, get all of the resource ids
  @resource_ids = MyLibrary::Resource->get_ids;
  
  # process each id
  foreach $resource_id (@resource_ids) {
  
	 # get a resource
	 $resource = MyLibrary::Resource->new(id => $resource_id);
	 
	 # get its id, title, and note
	 $id    = $resource->id;
	 $title = $resource->name;
	 $note  = $resource->note;
		 
	 # build the report
	 $output = '';
	 $output .= '<html>';
	 $output .= '<head>';
	 $output .= "<meta name='title' content='$title' />";
	 $output .= "<meta name='note'  content='$note' />";
	 $output .= '</head>';
	 $output .= '<body>';
	 $output .= "<h1>$title</h1>";
	 $output .= "<p>$note</p>";
	 $output .= '</body>';
	 $output .= '</html>';
	 
	 # output a swish-e header
	 print "Path-Name: $id\n";
	 print "Content-length: " . scalar(length $output) . "\n";
	 print "Document-Type: HTML*\n";
	 print "\n";
	 
	 # output the report
	 print "$output";
  
  }

The next step is to build a configuration file telling swish-e what to look for in the report. In our case the configuration needs to know about the title and note, and the configuration could be this simple:

  # define fields to index and make searchable
  MetaNames title note 
  PropertyNames title note
  
  # define the location and name of the resulting index
  IndexFile ./mylibrary.idx

Finally, you need to run your report generator and pipe the output to swish-e specifying the configuration file. You can do this from the command line. Assuming your report generator is called mylibrary2swish.pl and your swish-e configuration file is called mylibrary2swish.cfg, then the command might look like this:

  ./mylibrary2swish.pl | swish-e -c ./mylibrary2swish.cfg -S prog -i stdin

The result should be a two files, mylibrary.idx and mylibrary.idx.prop. These files are your swish-e index and you should be able to search them from the command line using the swish-e binary. Remember, you only included name and note in your output so only those fields will be searched. Also, queries will only return ids, not words.

The next step is to provide the ability to search the index. As queries are accepted the swish-e Perl API is used to search the index. Queries return MyLibrary keys, and these keys are used to look up the values of resources:
  
  # require the necessary modules
  use MyLibrary::Resource;
  use SWISH::API;
  
  # define the location of your index
  $INDEX = './mylibrary.idx';
  
  # get the input
  print "Enter a query. ";
  chop (my $query = <STDIN>);
  
  # search the index
  $swish   = SWISH::API->new($INDEX);
  $results = $swish->Query($query);
  $hits    = $results->Hits;
  
  # branch according to the number of hits
  if ($hits) {
  
	  print "Your search ($query) returned $hits hit(s).\n\n";
	  $counter = 0;
	  
	  # process each result
	  while ($result = $results->NextResult) {
	  
		  # get the id (key)
		  $id = $result->Property("swishdocpath");
		  
		  # get the resource, title, and note
		  $resource = MyLibrary::Resource->new(id => $id);
		  $title    = $resource->name;
		  $note     = $resource->note;
		  
		  # increment the counter
		  $counter++;
		  
		  # print the result
		  print "$counter. $title - $note\n\n";
	  
	  }
  
  }
  
  else {
  
	  print "No hits. Sorry.\n";
	  
  }

This section has outlined the most basic of search interfaces. Your reports sent to swish-e will want to be much more verbose.

For more information see index-resources.pl, index-resources.cfg, resources2swish.pl, and search.pl that came with the distribution. These files implement a more full-featured, terminal-based program for search.


=head2 MyLibrary and OAI

Because the MyLibrary database so closely resembles the basic Dublin Core elements, and because OAI requires data repositories to support Dublin Core, it is almost trivial to harvest the content of OAI repositories and cache it to a MyLibrary database.

The following script does just that, and in a nutshell here is how it works:

  1. Define the repository to harvest.
  2. Create a facet called Formats, if it doesn't exist.
  3. Create a term called Images, if it doesn't exist.
  4. Create a location type called URL, if it doesn't exist.
  5. Harvest all the records from the repository.
  6. Loop through each harvested record.
  7. Create a MyLibrary resource object.
  8. Fill the resource with attributes.
  9. Save the resource.
 10. Go to Step #6 'till done.

  
  # include the necessary modules
  use MyLibrary::Core;
  use Net::OAI::Harvester;
  
  # define the repository
  $repository = 'http://infomotions.com/gallery/oai/index.pl';
  
  # check for a facet called Formats
  $facet = MyLibrary::Facet->new;
  if (! MyLibrary::Facet->get_facets(value => 'Formats', field => 'name')) {
  
	  # create it
	  $facet->facet_name('Formats');
	  $facet->facet_note('Types of physical items embodying information.');
	  $facet->commit;
	  print "\nThe facet Formats was created.\n";
  
  }
  
  else {
  
	  # already exists
	  $facet = MyLibrary::Facet->new(name => 'Formats');
	  print "\nThe facet Formats already exists.\n";
	  
  }
  
  # remember this facet id
  $facetID = $facet->facet_id;
  
  # check for a term named Images
  $term = MyLibrary::Term->new;
  if (! MyLibrary::Term->get_terms(value => 'Images', field => 'name')) {
  
	  # create it
	  $term->term_name('Images');
	  $term->term_note('These are things like photographs or paintings.');
	  $term->facet_id($facetID);
	  $term->commit;
	  print "The term Images was created.\n";
	  
  }
  
  else {
  
	  # it already exists
	  $term = MyLibrary::Term->new(name => 'Images');
	  print "The term Images already exists.\n";
	  
  }
  
  # remember this term id
  $imageTermID = $term->term_id;
  
  # check for a location type called URL
  $location_type = MyLibrary::Resource::Location::Type->new;
  if (! MyLibrary::Resource::Location::Type->new(name => 'URL')) {
  
	  # create it
	  $location_type->name('URL');
	  $location_type->description('A type of Internet resource.');
	  $location_type->commit;
	  print "The location type URL was created.\n";
  }
  
  else {
  
	  # it already exists
	  $location_type = MyLibrary::Resource::Location::Type->new(name => 'URL');
	  print "The location type URL already exists.\n";
  
  }
  
  # remember the location type id
  $location_type_id = $location_type->location_type_id;
  
  # create a harvester and get the data
  $harvester = Net::OAI::Harvester->new('baseURL' => $repository);
  $records = $harvester->listAllRecords('metadataPrefix' => 'oai_dc');
  
  # process each record
  while ($record = $records->next) {
	  
	  $FKey         = $record->header->identifier;
	  $metadata     = $record->metadata;
	  $name         = $metadata->title;
	  @description  = $metadata->description;
	  $description  = join (' ', @description);
	  $location     = $metadata->identifier;
	  print "$name...";
	  
	  # check to see if it already exits
	  if (! MyLibrary::Resource->new(fkey => $FKey)) {
		  
		  # create it
		  $resource = MyLibrary::Resource->new;
		  $resource->name($name);
		  $resource->note($description);
		  $resource->fkey($FKey);
		  $resource->related_terms(new => [$imageTermID]);
		  $resource->add_location(location => $location,
		                          location_type => $location_type_id);
		  $resource->commit;
		  print "added (", $resource->id, ").\n";
	  
	  }
	  
	  else {
	  
		  # already got it
		  print "already exists.\n";
  
	  }
	  
  }
  
  # done
  print "\nDone\n";
  exit;

While this was the longest example in this tutorial, this particular OAI to MyLibrary interface is very rudimentary. See the script named images2mylibrary.pl from the distribution to see how you can harvest OAI sets. See doaj2mylibrary.pl to see how you can more accurately classify incoming resources based on set names. The really enterprising reader will figure out ways to read the incoming Dublin Core subject fields and create facet/term combinations accordingly.


=head1 Summary

Unlike version 2.x of MyLibrary, version 3.x is more like a toolbox and less like a turn-key application. Developers are expected to read and write values to the MyLibrary database, manipulate these values to create sets of information services.

The examples above point to terminal-based scripts implementing the described concepts. The distribution comes with another set of scripts implementing these ideas using a Web-based interface. They use all of the concepts outlined above but they are CGI scripts implemented in a more graphical interface.

Use MyLibrary in conjunction with other Perl modules. In a more traditional library you might consider reading sets of MARC records to create a sort of online catalog. Provide an SRU interface to your indexed content and then transform the XML returned from the SRU server into email messages or RSS feeds. Create CGI scripts that return Javascript that simply write to the document window. Then call these CGI scripts from within HTML <script> elements. This will enable HTML authors to incorporate MyLibrary content into their pages. You might harvest data from various but similar OAI repositories to create subject-specific collections. Index the collection and provide an interface to it. You might create Web-based input screens allowing authors to submit information about publications thus implementing a sort of institutional repository. Use your imagination. Think a bit outside the box.

When you've got a hammer everything looks like a nail. While MyLibrary is not necessarily a perfect hammer, it can address many of the needs in libraries to create, maintain, and distribute classified lists of information resources. The key to success is discovering ways to re-purpose these lists meeting the expressed needs of library users.

=head1 AUTHOR

Eric Lease Morgan <emorgan@nd.edu>

=cut

1; # return true or die