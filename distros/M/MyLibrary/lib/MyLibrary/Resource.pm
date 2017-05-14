package MyLibrary::Resource;

use MyLibrary::DB;
use Carp qw(croak longmess);
use strict;
use vars '$AUTOLOAD';

=head1 NAME

MyLibrary::Resource - A class for representing a MyLibrary resource


=head1 SYNOPSIS

	# require the necessary module
	use MyLibrary::Resource;
  
	# create a new Resource object
	my $resource = MyLibrary::Resource->new();
   
	# set attributes of the newly created object
	$resource->contributor('The Whole Internet Community');
	$resource->coverage('Items in the Catalogue date from 600 BC to the 1800\'s');
	$resource->creator('Infomotions, Inc.');
	$resource->date('2003-11-20');
	$resource->fkey('0002345');
	$resource->language('en');
	$resource->lcd(0);
	$resource->name('Alex Catalogue');
	$resource->note('This is a list of public domain classic literature');
	$resource->proxied(0);
	$resource->publisher('Infomotions, Inc.');
	$resource->qsearch_prefix('http://infomotions.com/alex?term=');
	$resource->qsearch_suffix('sortby=10');
	$resource->relation('http://www.promo.net/pg');
	$resource->format('Computer File');
	$resource->type('Organic Object');
	$resource->subject('Japanese; Mankind;');
	$resource->create_date('2005-08-01');
	$resource->rights('Items in the Catalogue are in the public domain');
	$resource->source('Materials of the Catalogue were gathered from all over the Internet.');
	$resource->access_note('Freely available on the World Wide Web');
	$resource->coverage_info('Aug. 1996-');
	$resource->full_text(1);
	$resource->reference_linking(1);

	# all appropriate object attribute can be changed to NULL values using the delete_* methods
	$resource->delete_note();
	$resource->delete_access_note();
 
	# save the data
	$resource->commit();

	# delete a resource
	$resource->delete();
   
	# get the id of this object
	$id = $resource->id();
   
	# create a new object with a specific id
	my $resource = MyLibrary::Resource->new(id => $id);

	# create a new object with a specific name 
	my $resource = MyLibrary::Resource->new(name => 'Web of Science');

	# create a new object with a specific fkey
	my $resource = MyLibrary::Resource->new(fkey => '00123456');
   
	# get selected data from the object
	my $name = $resource->name();
	my $note = $resource->note();

	# add a location
	$resource->add_location(location => 'http://mysite.com',  location_type => $type_id, location_note => 'This is mysite.');

	# modify a location
	$resource->modify_location($resource_location, resource_location => 'http://mysite2.com');
	$resource->modify_location($resource_location, location_note => 'This is my other site');

	# get a specific location by id or location string
	my $location = $resource->get_location(id => $id);
	my $location = $resource->get_location(resource_location => $location_string);

	# delete a location
	$resource->delete_location($resource_location);

	# get full array of related locations
	my @resource_locations = $resource->resource_locations();

	# get array of all resources
	@resource_objects = MyLibrary::Resource->get_resources();
	@resource_objects = MyLibrary::Resource->get_resources(sort => 'name');

	# get an array of resource within certain criteria
	@resource_objects = MyLibrary::Resource->get_resources(field => 'name', value => 'Web of science');

	# get array of specific list of sorted resources
	@resource_objects = MyLibrary::Resource->get_resources(list => [@list_resource_ids], sort => 'name');
	@resource_objects = MyLibrary::Resource->get_resources(list => [@list_resource_ids], sort => 'name', output => 'id');

	# get a list of resources by date
	my @resources_by_date = MyLibrary::Resource->get_resources(field => 'date_range', value => '2005-08-15_2005-08-17');
	
	# get array of all resource ids
	@resource_ids = MyLibrary::Resource->get_ids();

	# test for group membership based on term name
	my $return = $resource->test_relation(term_name => 'Biology');

	# get array of all lcd resources
	@lcd_resource_objects = MyLibrary::Resource->lcd_resources();

	# set new lcd resource flags
	MyLibrary::Resource->lcd_resources(new => @lcd_resources);

	# turn off lcd resource flags
	MyLibrary::Resource->lcd_resources(del => @lcd_resources);

	# return the appropriate quick search redirection string
	my $qsearch_redirect = MyLibrary::Resource->qsearch_redirect(resource_id => $id, qsearch_arg => $qsearch_string);

	# get array of fkey tagged resources
	@fkey_resources = MyLibrary::Resource->get_fkey();

	# get array of related term ids
	my @related_terms = $resource->related_terms();


=head1 DESCRIPTION

This class is used to represent a MyLibrary resource.


=head1 METHODS


=head2 new()

This method creates a new resource object. Called with no input, this method returns a new, empty resource:

   # create empty resource
   my $resource = MyLibrary::Resource->new();

Called with an id, this method returns a resource object containing the information from the underlying database:

   # create a resource from the underlying database
   my $resource = MyLibrary::Resource->new(id => 123);

The method returns undef if the id is invalid. The method can also be used to create a new object of an existing resource by supplying either a name or fkey parameter to the method. For example:

	# create a resource using an fkey parameter
	my $resource = MyLibrary::Resource->new(fkey => 12345);	

If name is passed as a parameter, the result returned will be based on the context in which the method was called. If called in a scalar context, the method will return the number of records found or undef if no records were found. If called in list context, and records are found, an array of resource objects will be returned.

	# number of records in database matching name criteria
	my $number_resources = MyLibrary::Resource->new(name => 'My Resource');

	# array of records matching name criteria
	my @resources = MyLibrary::Resource->new(name => 'My Resource');


=head2 name()

This method gets and sets the name of a resource object. The values of name is intended to be analogous to the Dublin Core name element. To set the name attribute:

   # set the name of a resource
   $resource->name('DAIAD Home Page');

To get the value of the name, try:

   # get the name
   my $name = $resource->name;
   
   
=head2 note()

Sets and gets the note attribute of a resource object. To set the note's value, try:

  $resource->note('This is a simple note.');

To get the value of the note attribute, do:

  my $note = $resource->note;

The sorts of values intended to be stored in note attributes correspond to the sorts of values assigned to Dublin Core description elements.

  
=head2 access_note()

The access_note method can be used either to retrieve or assign an access note to a resource:

   # set the access note value
   $resource->access_note('Available to Notre Dame patrons only.');

   # get the access note value
   my $access_note = $resource->access_note;

=head2 coverage_info()

The coverage_info method can be used either to retrieve or assign coverage info to a resource:

   # set the coverage info value
   $resource->coverage_info('Feb. 1996 - Aug. 2001');

   # get the coverage info value
   my $coverage_info = $resource->coverage_info;   

=head2 full_text()

The full_text method can be used either to retrieve or assign a full text flag to a resource:

   # set the full text flag (on)
   $resource->full_text(1); # the resource supports full text access

   # set the full text flag (off)
   $resource->full_text(0); # the resource does not support full text access

   # get the full text flag value
   my $full_text_flag = $resource->full_text;

=head2 reference_linking()

The reference_linking method can be used to retrieve or assign a reference linking flag to a resource. The reference
linking flag indicates whether the resource is listed in a find text aggregator such as SFX FindText. This flag can
then be used to inform the patron of this availability for the given institution.

   # set the reference linking flag (on)
   $resource->reference_linking(1); # the resource is supported by a reference linker

   # set the reference linking flag (off)
   $resource->reference_linking(0); # the resource is not supported by a reference linker

   # get the reference linking value
   my $reference_linking_val = $resource->reference_linking;
   
=head2 lcd()

This method is used to set and get the "lowest common denominator" (LCD) value of a resource. LCD resources are resources intended for any audience, not necessarily discipline-specific audiences. Good candidates for LCD resources are generic dictionaries, encyclopedias, a library catalog, or multi-disciplinary bibliographic databases. LCD resoruces are useful to anybody.

lcd attributes are Boolean in nature; valid values for lcd attributes are 0 and 1.

To set a resource's lcd attribute:

   $resource->lcd(1); # is an LCD resource
   $resource->lcd(0); # is not an LCD resource

To get the lcd resource:

   $lcd = $resource->lcd;

This method will "croak" if there is an attempt to set the value of lcd to something other than 0 or 1.


=head2 fkey()

Gets and sets the fkey value of a resource. Fkey's are "foreign keys" and intended to be the unique value (database key) of a resource from a library catalog. The combination of this attribute and the MARION field of the preferences table should create a URL allowing the user to see the cataloging record of this resource.

Setting and getting the fkey attribute works like this:

   # set the fkey
   $resource->fkey('0002345');
   
   # getting the fkey
   my $fkey = $resource->fkey;
   

=head2 qsearch_prefix() and qsearch_suffix()

These methods set and get the prefix and suffix values for "Quick Searches".

Quick Search resources result in an HTML form allowing the end-user to query a remote Internet database with one input box and one button. Quick Search resources are reverse-engineered HTML forms supporting the HTTP GET method. By analyzing the URL's of Internet searches it becomes apparent that the searches can be divided into three parts: the prefix, the query, and the suffix. For example, the prefix for a Google search looks like this:

   http://www.google.com/search?hl=en&ie=ISO-8859-1&q=

A query might look like this:

   mylibrary

The suffix might look like this:

   &btnG=Google+Search

By concatonating these three part together a URL is formed. Once formed a Web browser (user agent in HTTP parlance) can be redirected to the newly formed URL and the search results can be displayed.

The qsearch_prefix() and qsearch_suffix() methods are used set and get the prefixes and suffixes for Quick Searches, and they work just like the other methods:

   # set the prefix and suffix
   $resource->qsearch_prefix('http://www.google.com/search?hl=en&ie=ISO-8859-1&q=');
   $resource->qsearch_suffix('&btnG=Google+Search');
   
   # create a Quick Search URL by getting the prefixes and suffixes of a resource
   my $query = 'mylibrary';
   my $quick_search = $resource->qsearch_prefix . $query . $resource->qsearch_suffix;
   

=head2 date()

Use this method to set and get the date attribute of a resource. This value is intended to correspond to the the Dublin Core date element and is used in the system as a date stamp representing when this resource was last edited thus facilitating a "What's new?" functionality. Date values are intended to be in a YYYY-MM-DD format.

Setting and getting date attributes works like this:

   # set the date
   $resource->date('2003-10-28');
   
   # get the date
   my $date = $resource->date;
   

=head2 id()

Use this method to get the ID (database key) of a resource. Once committed, a resource will have a database key, and you can read the value of this key with this method:

   # get the ID of a resource
   my $id = $resource->id;

It is not possible to set the value of the id attribute.


=head2 commit()

Use this method to save a resource's attributes to the underlying database, like this:

   # save the resource
   $resource->commit;

If the resource already exists in the database (it has an id attribute), then this method will do an SQL UPDATE. If this is a new resource (no previously assigned id attribute), the method will do an SQL INSERT.

=head2 delete_[attribute_name]()

This is a generic object attribute method that can be used to apply NULL values to a given attribute such as name and access_note. However, the boolean attribute will be excluded from this method. Examples are given below:

	# delete note value
	$resource->delete_note();

	# delete coverage value
	$resource-> delete_coverage();

=head2 delete()

This method deletes a resource from the underlying database like this:

   # delete this resource
   $resource->delete;

Once called this method will do an SQL DELETE operation for the given resource denoted by its id attribute.

=head2 get_resources()

This method returns an array of resource objects or ids, specifically, an array of all the resources in the underlying database. Once called, the programmer is intended to sort, filter, and process the items in the array as they see fit. The return set from this method can either be an array of resource objects or ids as indicated by the 'output' parameter. This method does not require input:

	# get all the resources
	my @all_resources = MyLibrary::Resource->get_resources(output => 'id');
   
   # process each resource
	foreach my $r (@all_resources) {
   
		# check for resources from edu domains
		# change this
		if ($r->url =~ /edu/) {
      
			# print them
			print $r->name . "\n"
         
		}
  
	}

	# sort retrieved list of resource objects by name
	my @all_resources = MyLibrary::Resource->get_resources(sort => 'name');

A defined list of resources may also be retrieved using this method, if the sum total of resources is not desired or required. The list parameter can be used to retrieve such a list. Simply enclose the list in a pair of brackets.

	# retrieve specific list of resources
	my @specific_resources = MyLibrary::Resource->get_resources(list => [@resource_ids], output => 'object');

Also, a certain field in the resource record can be queried to determine if a resource with the specified criteria exists in the data set. This parameter cannot be used with the 'list' parameter. However, use of the method in this way requires that both a 'field' parameter and a 'value' parameter be supplied. If the correct combination of parameters is not supplied, incorrectly used parameters will simply be ignored. Example:

	# retrieve a list of resources matching title criteria
	my @criteria_specific_resources = MyLibrary::Resource->get_resources(field => 'name', value => 'Web of science');

A set of resources can be retrieved within a specified date range as well. The field name must state 'date_range' and the value must be in the following format: YYYY-MM-DD_YYYY-MM-DD where the first date is the beginning date and the second the ending date for the range. The output type can be either resource objects or resource ids depending on what is indicated by the output parameter. The date in question is the date that the item was entered into MyLibrary. Example:

	# retrieve a few days worth of resources
	my @resources_by_date = MyLibrary::Resource->get_resources(field => 'date_range', value => '2005-08-15_2005-08-17');

=head2 lcd_resources()

This class method will allow the retrieval of an array of recource objects which have been designated "lcd" or "lowest common denominator". These are resources that are useful to anyone in any discipline of study.  The method will always return a list (an array) of object references corresponding to the appropriate category. This method is very similar to the get_resources() method.

	# get all lcd resources
	@lcd_resources = MyLibrary::Resource->lcd_resources();

The method may also be used to set or delete lcd_resource flags. The first parameter should indicate whether lcd resource flags are being switched to true ('new') or false ('del). The second parameter should be a list or array of resources upon which the indicated operation will be performed. As mentioned previously, a list of current lcd resources will be returned upon successful execution of the method.

	# add new lcd resource flags
	MyLibrary::Resource->lcd_resources('new', @lcd_resources);

	# delete old lcd resource flags
	MyLibrary::Resource->lcd_resources('del', @lcd_resources);

If new flags are indicated which are already positive, they will simply be ignored. Flags set to be turned off which are not positive will not be modified. If a resource id is indicated which does not exist in the database, a fatal exception will be thrown in the calling application.

=head2 qsearch_redirect()

Quick Searches in MyLibrary are really a combination of four URL components. Thus, this class method will apply only to those resources that are related to a URL typed location. The three components of a quick search are: the search prefix, the search argument and if necessary, the search suffix. This method takes as an argument the resource id, and the argument to be used for the search. Each of these parameters is necessary or the method will return null.

The string returned from this method should be used to redirect the brower using the string as the redirection URL.

	# return the appropriate quick search redirection string
	my $qsearch_redirect = MyLibrary::Resource->qsearch_redirect(resource_id => $id, qsearch_arg => $qsearch_string);

=head2 get_fkey()

This class method will allow the retrieval of an array of lightweight objects with only two attributes: resource_id and fkey. The array will contain only those objects which correspond to resource records associated with an fkey (foreign database key). This array (or list) can then be used to process through the fkey resources by calling the class constructor and operating on the full resource objects or to otherwise process through the list of resource ids which are associated with an external system record. Unlike the lcd_resources() class mothod, these objects are lightweight for faster processing in deference to the latter processing option.

This method cannot be used to set fkeys for specific resources, it can only be used to retrieve a list representing the current list of resources with fkeys.

	# get lightweight fkey resource objects
	@fkey_resources = get_fkey();

=head2 test_relation()

This object method is used to quickly test whether a relation exists between the current resource and a term or facet identified either by the term/facet name or id number. It will always return a boolean value of either '0' (no relation exists) or '1' (relation exists). The method was designed so that group membership based upon a set of criteria can easily be determined. Multiple tests can be run to determine complex sets of criteria for group membership among a set of resources. Please note that only the first parameter submitted will be considered as test criteria.

	# test for group membership based on term_name
	my $return = $resource->test_relation(term_name => 'Biology');

	# test for group membership based on term id
	my $return = $resource->test_relation(term_id => 16);

	# test for group membership based on facet id
	my $return = $resource->test_relation(facet_id => 13);

=head2 related_terms()

This object method will allow the retrieval, addition and deletion of term relations with a given resource object. The return set is always a list (or array) of term ids which are currently related to this resource. The list can then be used to retrieve the related terms or otherwise process through the list. No parameters are necessary in order to retrieve a list of related term ids, however, new relations can be created by supplying a list of resource ids using the 'new' parameter. If a term is already related to this resource, the supplied term id will simply be ignored. Upon a resource commit (e.g. resource->commit()), the new relations will be created. Also, the input must be in the form of numeric digits. Care must be taken because false relationships could be created.

	# get all related terms
	my @related_terms = $resource->related_terms();

	# supply new related terms
	$resource->related_terms(new => [10, 11, 12]);
	or
	my @new_related_terms = $resource->related_terms(new => [@new_terms]);

The method will by default check to make sure that the new terms to which this resource should be related exist in the database. However, this may be switched off by supplying the strict => 'off' parameter. Changing this parameter to 'off' will switch off the default behavior and allow bogus term relations to be created.

	# supply new related terms with relational integrity switched off
	$resource->related_terms(new => [10, 12, 14], strict => 'off');

Terms which do not exist in the database will simply be rejected if strict relational integrity is turned on.

The method can also be used to delete a relationship between a term and a resource. This can be accomplished by supplying a list of terms via the 'del' parameter. The methodology is the same as the 'new' parameter with the primary difference being that referential integrity will be assumed (for example, that the term being severed already exists in the database). This will not delete the term itself, it will simply delete the relationship between the current resource object and the list of terms supplied with the parameter.

	# sever the relationship between this resource and a list of term ids
	$resource->related_terms(del => [10, 11, 12]);

	or

	$resource->related_terms(del => [@list_to_be_severed]);

If the list includes terms to which the current resource is not related, those term ids will simply be ignored. Priority will be given to term associations added to the object; deletions will occur during the commit() after new associations have been created.


=head2 proxied()

Gets and sets the value of the proxied attribute of a resource:

   # set the value of proxied
   $resource->proxied(0); # not proxied
   $resource->proxied(1); # is proxied
   
   # get the proxied attribute
   my $proxied = $resource->proxied;

If a particular resource is licensed, then user agents (Web browsers) usually need to go through a proxy server before accessing the resources. This attribute denotes whether or not a resource needs to be proxied. If true (1), then the resource's URL is intended to be prefixed with value of the proxy_prefix field in the preferences table. If false (0), then the URL is intended to stand on its own.

This method will "croak" if the value passed to it is not 1 or 0.


=head2 creator()

Use this method to set and get the creator of a resource. The creator attribute is intended to correspond to the Dublin Core creator element. The method works just like the note method:

   # set the creator value
   $resource->creator('University Libraries of Notre Dame');
   
   # get the creator
   my $creator = $resource->creator;
   
   
=head2 publisher()

Use this method to set and get the publisher of a resource. The publisher attribute is intended to correspond to the Dublin Core publisher element. The method works just like the note method:

   # set the publisher value
   $resource->publisher('O\'Reilly and Associates');
   
   # get the publisher
   my $publisher = $resource->publisher;
   
   
=head2 contributor()

Use this method to set and get the contributor of a resource. The contributor attribute is intended to correspond to the Dublin Core contributor element. The method works just like the note method:

   # set the contributor value
   $resource->contributor('The Whole Internet');
   
   # get the contributor
   my $contributor = $resource->contributor;
   
   
=head2 coverage()

Use this method to set and get the coverage of a resource. The coverage attribute is intended to correspond to the Dublin Core coverage element. The method works just like the note method:

   # set the coverage value
   $resource->coverage('Items in the Catalogue date from 600 BC to the 1800\'s.');
   
   # get the coverage
   my $coverage = $resource->coverage;
   
   
=head2 rights()

Use this method to set and get the rights of a resource. The rights attribute is intended to correspond to the Dublin Core rights element. The method works just like the note method:

   # set the rights value
   $resource->rights('This item is in the public domain.');
   
   # get the rights
   my $rights = $resource->rights;
   
   
=head2 language()

Use this method to set and get the language of a resource. The language attribute is intended to correspond to the Dublin Core language element. The method works just like the note method:

   # set the language value
   $resource->language('eng');
   
   # get the language
   my $language = $resource->language;
   
   
=head2 source()

Use this method to set and get the source of a resource. The source attribute is intended to correspond to the Dublin Core source element. The method works just like the note method:

   # set the source value
   $resource->source('This items originated at Virginia Tech.');
   
   # get the source
   my $source = $resource->source;
   
   
=head2 relation()

Use this method to set and get the relation of a resource. The relation attribute is intended to correspond to the Dublin Core relation element. The method works just like the note method:

   # set the relation value
   $resource->relation('http://www.promo.net/pg/');
   
   # get the relation
   my $relation = $resource->relation;

=head2 format()

Use this method to set and get the format of a resource. The format attribute is intended to correspond to the Dublin Core format element. The method works just like the note method:

	# set format
	$resource->format('Computer File');

	# get format
	my $format = $resource->format();

=head2 type()

Use this method to set and get the type of a resource. The type attribute is intended to correspond to the Dublin Core type element. The method works just like the note method:

	# set type
	$resource->type('Organic Object');

	# get type
	my $type = $resource->type();

=head2 subject()

Use this method to set and get the subject of a resource. The subject attribute is intended to correspond to the Dublin Core subject element. If more than one DCMI subject is required to describe the resource, it is suggested that the programmer delimit subject values in this field according to a pre-arranged pattern. For example, a pipe symbol '|' could be used to delimit subject entries. The method works just like the note method:

	# set the subject
	$resource->subject('Japanese; Mankind;');

	# get the subject entry
	my $subject_string = $resource->subject();

=head2 create_date()

This method is intended as an accessor to the date attribute of a resource object, corresponding to the date on which the resource was created, written, composed, manufactured, etc. This date field should NOT be used to indicate when a resource was added to this instance of MyLibrary.

	# set the create date
	$resource->create_date('2005-08-01');

	# get the create date
	my $create_date = $resource->create_date();

=head2 add_location()

This method will add a location to the resource object using supplied parameters. Required parameters are 'location' and 'location_type'. 'location note' may also be supplied as an optional parameter. The 'location_type' supplied must be a location type id. This id may be obtained using the Resource/Location.pm methods or supplied from an interface. The type must pre-exist in the database for this parameter to be valid. 'location_note' may be any string, but is usually some descriptive text about the location which may later be used as the string for the active URL or pointer to the specified location. This method will check to make sure that the location entered is unique to this resource. This method will return a '1' if the record was added, a '2' if a record with a duplicate location for this resource was found and a '0' for an unspecified problem.

	# add a location to a resource
	$resource->add_location(location => 'http://mysite.com', location_type => $location_type_id, location_note => 'This is my site.');
	
=head2 delete_location()

This object method will delete a location from the list of locations associated with a resource. The required parameter is the resource location object to be deleted.

	# delete a location from a resource
	$resource->delete_location($resource_location);

=head2 resource_locations()

This object method will allow the retrieval of an array of location objects associated with this resource. The objects returned can then be operated on using any Resource/Location.pm object methods. For example, you could cycle through the list of objects to perform other operations on them such as appending a proxy prefix.

	# obtain a list of resource location objects
	my @resource_locations = $resource->resource_locations();

	# cycle through list to process
	foreach my $resource_location (@resource_locations) {
		if ($resource_location->location() eq 'http://mysite.com') {
			$resource->delete_location($resource_location->id());
		}
	}

=head2 modify_location()

This method takes two parameters. The first parameter is a valid location object to be updated. The second parameter is the name of the location attribute to change. The second input parameter can be one (and only one) of the following: 'resource_location' and 'location_note'. The location type cannot be changed using this method. It is suggested that if the type changes, the resource location be deleted and a new resource location created. A location type change seems like a rare possibility indeed. Only one location attribute can be changed at a time.

	# modify a related location
	$resource->modify_location($resource_location, resource_location => 'http://mysite2.com');
	$resource->modify_location($resource_location, location_note => 'This is my other note.');

=head2 get_location()

Use this method to retrieve a specific location object associated with the current resource. The method can accept one of two parameters: id and resource_location. 'id' is the resource location id (key) and 'resource_location' is the string that matches the location desired. After retrieval, all of the attribute methods found in MyLibrary::Resource::Location will be available to the object. Other Resource class methods associated with locations can also be used to manipulate the object.

	# retrieve a specific location
	my $location = $resource->get_location(id => $id);
	my $location = $resource->get_location(resource_location => $resource_location_string);

=head1 SEE ALSO

For more information, see the MyLibrary home page: http://dewey.library.nd.edu/mylibrary/.

=head1 TODO

	--there needs to be better error checking and graceful returns when errors are encountered.
	--patron resource relational integrity needs to be addressed
	--methods created to accomodate the 'Reviews' module

=head1 HISTORY

First public release, October 28, 2003.

=head1 AUTHORS

Robert Fox <rfox2@nd.edu>
Eric Lease Morgan <emorgan@nd.edu>


=cut


sub new {

	# declare local variables
	my ($class, %opts) = @_;
	my $self           = {};

	# check for an id
	if ($opts{id}) {
	
		# get a handle
		my $dbh = MyLibrary::DB->dbh();
		
		# find this record
		my $rv = $dbh->selectrow_hashref('SELECT * FROM resources WHERE resource_id = ?', undef, $opts{id});
		
		# check for success
		if (ref($rv) eq "HASH") { 
			$self = $rv; 
			$self->{related_terms} = $dbh->selectall_arrayref('SELECT term_id FROM terms_resources WHERE resource_id = ?', undef, $opts{id});
		} else { 
			return; 
		}
	
	} elsif ($opts{name}) {
		
		# get a handle
		my $dbh = MyLibrary::DB->dbh();

		# find matching record(s)
		my $rv = $dbh->selectall_hashref('SELECT * FROM resources WHERE resource_name = ?', 'resource_id', undef, $opts{name});

		# check for success
		if (ref($rv) eq "HASH") {
			my $num_records = keys %{$rv};
			if (wantarray) {
				my @return_records;
				foreach my $resource_id (keys %{$rv}) {
					my $resource = $rv->{$resource_id};
					push(@return_records, bless($resource, $class));
				}
				return @return_records;
			} else {
				return $num_records;
			}
			#$self = $rv;
			#$self->{related_terms} = $dbh->selectall_arrayref('SELECT term_id FROM terms_resources WHERE resource_id = ?', undef, $self->{resource_id});
		} else {
			return;
		}

	} elsif ($opts{fkey}) {
		
		# get a handle
		my $dbh = MyLibrary::DB->dbh();
		
		# find this record
		my $rv = $dbh->selectrow_hashref('SELECT * FROM resources WHERE resource_fkey = ?', undef, $opts{fkey});

		# check for success
		if (ref($rv) eq "HASH") {
			$self = $rv;
			$self->{related_terms} = $dbh->selectall_arrayref('SELECT term_id FROM terms_resources WHERE resource_id = ?', undef, $self->{resource_id});
		} else {
			return;
		}

	}
	# fill in the database defaults
	if (! $self->{resource_lcd}) {
		$self->{resource_lcd} = 0;
	}
	if ( ! $self->{resource_proxied}) {
		$self->{resource_proxied} = 0;
	}
	if ( ! $self->{resource_full_text}) {
		$self->{resource_full_text} = 0;
	}
	if ( ! $self->{resource_reference_linking}) {
		$self->{resource_reference_linking} = 0;
	}
	
	# return the object
	return bless $self, $class;
	
}

sub AUTOLOAD {

	# added the following as per http://www.unix.org.ua/orelly/perl/prog3/ch12_05.htm --ELM
	return if our $AUTOLOAD =~ /::DESTROY$/;

	my $self = shift;
	# delete_[attribute] methods
	$AUTOLOAD =~ /.*::delete_(\w+)/
		or croak "No such method: $AUTOLOAD";
	exists $self->{"resource_${1}"}
		or croak "No such object attribute: $1";
	unless ($1 eq 'name' || $1 eq 'lcd' || $1 eq 'proxied' || $1 eq 'full_text' || $1 eq 'reference_linking') {
		$self->{"resource_${1}"} = undef;
	} else {
		croak "Illegal method call: $AUTOLOAD";
	}

}

sub name {

	my ($self, $name) = @_;
	
	if ($name) { $self->{resource_name} = $name }
	else { return $self->{resource_name} }
	
}


sub note {

	my ($self, $note) = @_;
	
	if ($note) { $self->{resource_note} = $note }
	else { return $self->{resource_note} }
	
}

sub creator {

	my ($self, $creator) = @_;
	
	if ($creator) { $self->{resource_creator} = $creator }
	else { return $self->{resource_creator} }
	
}

sub publisher {

	my ($self, $publisher) = @_;
	
	if ($publisher) { $self->{resource_publisher} = $publisher }
	else { return $self->{resource_publisher} }
	
}


sub contributor {

	my ($self, $contributor) = @_;
	
	if ($contributor) { $self->{resource_contributor} = $contributor }
	else { return $self->{resource_contributor} }
	
}

sub coverage {

	my ($self, $coverage) = @_;
	
	if ($coverage) { $self->{resource_coverage} = $coverage }
	else { return $self->{resource_coverage} }
	
}

sub language {

	my ($self, $language) = @_;
	
	if ($language) { $self->{resource_language} = $language }
	else { return $self->{resource_language} }
	
}


sub rights {

	my ($self, $rights) = @_;
	
	if ($rights) { $self->{resource_rights} = $rights }
	else { return $self->{resource_rights} }
	
}

sub source {

	my ($self, $source) = @_;
	
	if ($source) { $self->{resource_source} = $source }
	else { return $self->{resource_source} }
	
}


sub relation {

	my ($self, $relation) = @_;
	
	if ($relation) { $self->{resource_relation} = $relation }
	else { return $self->{resource_relation} }
	
}

sub format {

	my ($self, $format) = @_;

	if ($format) { $self->{resource_format} = $format }
	else { return $self->{resource_format} }

}

sub type {

	my ($self, $type) = @_;

	if ($type) { $self->{resource_type} = $type }
	else { return $self->{resource_type} }

}

sub subject {

	my ($self, $subject) = @_;

	if ($subject) { $self->{resource_subject} = $subject }
	else { return $self->{resource_subject} }

}

sub create_date {

	my ($self, $create_date) = @_;

	if ($create_date) { $self->{resource_create_date} = $create_date }
	else { return $self->{resource_create_date} }

}


sub lcd {

	my ($self, $lcd) = @_;
	
	if ( ! $lcd) {
		return $self->{resource_lcd};
	} elsif ($lcd eq '1' || $lcd eq '0') { 
		$self->{resource_lcd} = $lcd;
		return $self->{resource_lcd}; # operation successful
	} else { 
		croak("Invalid value for lcd: $lcd. Valid values are 1 and 0.");
	}
	
}

sub access_note {

    my ($self, $access_note) = @_;

	if ( ! $access_note) {
		return $self->{resource_access_note};
	} elsif ($access_note) {
		$self->{resource_access_note} = $access_note;
		return $self->{resource_access_note}; # operation successful
	}
}

sub coverage_info {

	my ($self, $coverage_info) = @_;

	if (! $coverage_info) {
		return $self->{resource_coverage_info};
	} elsif ($coverage_info) {
		$self->{resource_coverage_info} = $coverage_info;
		return $self->{resource_coverage_info}; # operation successful
	}
}

sub full_text {

	my ($self, $full_text) = @_;

	if ( ! $full_text) {
		return $self->{resource_full_text};
	} elsif ($full_text eq '1' || $full_text eq '0') {
		$self->{resource_full_text} = $full_text;
		return $self->{resource_full_text}; # operation successful
	} else {
		croak("Invalid value for full_text: $full_text. Valid values are 1 and 0.");
	}
}

sub reference_linking {

	my ($self, $reference_linking) = @_;

	if (! $reference_linking) {
		return $self->{resource_reference_linking};
	} elsif ($reference_linking eq '1' || $reference_linking eq '0') {
		$self->{resource_reference_linking} = $reference_linking;
		return $self->{resource_reference_linking}; # operation successful
	} else {
		croak("Invalid value for reference_linking: $reference_linking. Valid values are 1 and 0.");
	}
}

sub proxied {

	my ($self, $proxied) = @_;
	
	if (! $proxied) { }  # do nothing
	elsif ($proxied eq '1' || $proxied eq '0') { $self->{resource_proxied} = $proxied }
	else { croak("Invalid value for proxied: $proxied. Valid values are 1 and 0.") }
	
	return $self->{resource_proxied};
	
}


sub fkey {

	my ($self, $fkey) = @_;
	
	if ($fkey) { $self->{resource_fkey} = $fkey }
	else { return $self->{resource_fkey} }
	
}


sub qsearch_prefix {

	my ($self, $qsearch_prefix) = @_;
	
	if ($qsearch_prefix) { $self->{qsearch_prefix} = $qsearch_prefix }
	else { return $self->{qsearch_prefix} }
	
}


sub qsearch_suffix {

	my ($self, $qsearch_suffix) = @_;
	
	if ($qsearch_suffix) { $self->{qsearch_suffix} = $qsearch_suffix }
	else { return $self->{qsearch_suffix} }
	
}


sub date {

	my ($self, $date) = @_;
	
	if ($date) { $self->{resource_date} = $date }
	else { return $self->{resource_date} }
	
}


sub id {

	my $self = shift;
	
	return $self->{resource_id};
	
}


sub commit {

	# get myself, :-)
	my $self = shift;
	
	# get a database handle
	my $dbh = MyLibrary::DB->dbh();	
	
	# see if the object has an id
	if ($self->id() && scalar($dbh->selectrow_array('SELECT resource_id FROM resources WHERE resource_id = ?', undef, $self->id())) >= 1) {
	
		# update the record with this id
		my $return = $dbh->do('UPDATE resources SET resource_name = ?, resource_note = ?, resource_lcd = ?, resource_fkey = ?, resource_date = ?, qsearch_prefix = ?, qsearch_suffix = ?, resource_proxied = ?, resource_creator = ?, resource_publisher = ?, resource_contributor = ?, resource_coverage = ?, resource_rights = ?, resource_language = ?, resource_source = ?, resource_relation = ?, resource_format = ?, resource_type = ?, resource_subject = ?, resource_create_date = ?, resource_access_note = ?, resource_coverage_info = ?, resource_full_text = ?, resource_reference_linking = ? WHERE resource_id = ?', undef, $self->name(), $self->note(), $self->lcd(), $self->fkey(), $self->date(), $self->qsearch_prefix(), $self->qsearch_suffix(), $self->proxied(), $self->creator(), $self->publisher(), $self->contributor(), $self->coverage(), $self->rights(), $self->language(), $self->source(), $self->relation(), $self->format(), $self->type(), $self->subject(), $self->create_date(), $self->access_note(), $self->coverage_info(), $self->full_text(), $self->reference_linking(), $self->id());
		if ($return > 1 || ! $return) { croak "Resources update in commit() failed. $return records were updated." }
		# update resource=>term relational integrity
		my @related_terms = $self->related_terms();
		if (scalar(@related_terms) > 0 && @related_terms) {
			my $arr_ref = $dbh->selectall_arrayref('SELECT term_id FROM terms_resources WHERE resource_id =?', undef, $self->id());
			# determine which resources stay put
			if (scalar(@{$arr_ref}) > 0) {
				foreach my $arr_val (@{$arr_ref}) {
					my $j = scalar(@related_terms);
					for (my $i = 0; $i < scalar(@related_terms); $i++)  {
						if ($arr_val->[0] == $related_terms[$i]) {
							splice(@related_terms, $i, 1);
							$i = $j;
						}
					}
				}
			}
			# add the new associations
			foreach my $related_term (@related_terms) {
				my $return = $dbh->do('INSERT INTO terms_resources (resource_id, term_id) VALUES (?,?)', undef, $self->id(), $related_term);
				if ($return > 1 || ! $return) { croak "Unable to update resource=>term relational integrity. $return rows were inserted." }
			}
			# determine which term associations to delete
			my @del_related_terms;
			my @related_terms = $self->related_terms();
			if (scalar(@{$arr_ref}) > 0) {
				foreach my $arr_val (@{$arr_ref}) {
					my $found;
					for (my $i = 0; $i < scalar(@related_terms); $i++)  {
						if ($arr_val->[0] == $related_terms[$i]) {
							$found = 1;
							last;
						} else {
							$found = 0;
						}
					}
					if (!$found) {
						push (@del_related_terms, $arr_val->[0]);
					}
				}
			}
			# delete removed associations
			foreach my $del_rel_term (@del_related_terms) {
				 my $return = $dbh->do('DELETE FROM terms_resources WHERE resource_id = ? AND term_id = ?', undef, $self->id(), $del_rel_term);
				if ($return > 1 || ! $return) { croak "Unable to delete resource=>term association. $return rows were deleted." }
				$return = $dbh->do('DELETE FROM suggestedResources WHERE resource_id = ? AND term_id = ?', undef, $self->id(), $del_rel_term);
			}
		}
		
	} else {
	
		# get a new sequence if necessary
		my $id;
		unless ($self->id()) {
			$id = MyLibrary::DB->nextID();	
		} else {
			$id = $self->id();
		}
		
		# create a new record
		my $return = $dbh->do('INSERT INTO resources (resource_id, resource_name, resource_note, resource_lcd, resource_fkey, resource_date, qsearch_prefix, qsearch_suffix, resource_proxied, resource_creator, resource_publisher, resource_contributor, resource_coverage, resource_rights, resource_language, resource_source, resource_relation, resource_format, resource_type, resource_subject, resource_create_date, resource_access_note, resource_coverage_info, resource_full_text, resource_reference_linking) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', undef, $id, $self->name(), $self->note(), $self->lcd(), $self->fkey(), $self->date(), $self->qsearch_prefix(), $self->qsearch_suffix(), $self->proxied(), $self->creator(), $self->publisher(), $self->contributor(), $self->coverage(), $self->rights(), $self->language(), $self->source(), $self->relation(), $self->format(), $self->type(), $self->subject(), $self->create_date(), $self->access_note(), $self->coverage_info(), $self->full_text(), $self->reference_linking());
		if ($return > 1 || ! $return) { longmess 'Resources commit() failed.'; }
		$self->{resource_id} = $id;
		# update resource=>term relational integrity
		my @related_terms = $self->related_terms();
		if (scalar(@related_terms) > 0 && @related_terms) {
			foreach my $related_term (@related_terms) {
				my $return = $dbh->do('INSERT INTO terms_resources (resource_id, term_id) VALUES (?,?)', undef, $self->id(), $related_term);
				if ($return > 1 || ! $return) { croak "Unable to update resource=>term relational integrity. $return rows were inserted." }
			}
		}
	}
	
	# done
	return 1;
}


sub delete {

	my $self = shift;

	if ($self->{resource_id}) {

		my $dbh = MyLibrary::DB->dbh();
		my @resource_locations = $self->resource_locations();
		foreach my $resource_location (@resource_locations) {
			$resource_location->delete();
		} 
		my $rv = $dbh->do('DELETE FROM resources WHERE resource_id = ?', undef, $self->{resource_id});
		if ($rv != 1) {croak ("Deleted $rv records. I'll bet this isn't what you wanted.");} 
		$rv = $dbh->do('SELECT * FROM terms_resources WHERE resource_id = ?', undef, $self->{resource_id});
		if ($rv > 0) {
			$rv = $dbh->do('DELETE FROM terms_resources WHERE resource_id = ?', undef, $self->{resource_id});
			if ($rv < 1 || ! $rv) {croak ("Resource => Term associations could not be deleted. Referential integrity may be compromised.");}
		}
		$rv = $dbh->do('SELECT * FROM suggestedResources WHERE resource_id = ?', undef, $self->{resource_id});
		if ($rv > 0) {
			$rv = $dbh->do('DELETE FROM suggestedResources WHERE resource_id = ?', undef, $self->{resource_id});
			if ($rv < 1 || ! $rv) {croak ("Resource => Term associations could not be deleted. Referential integrity may be compromised.");}
		}

		$rv = $dbh->do('DELETE FROM patron_resource WHERE resource_id = ?', undef, $self->{resource_id});

		return 1;

	}

	return 0;

}


sub get_resources {

	my $self = shift;
	my %opts = @_;
	my ($sort, $field, $value, $query_field, $output);
	my @rv   = ();
	my @list_ids;
	if (%opts) {
		if ($opts{'sort'}) {
			$sort = $opts{'sort'};	
		}
		if ($opts{'list'} && !$opts{'field'}) {
			@list_ids = @{$opts{'list'}};
		}
		if ($opts{'field'} && $opts{'value'} && ! $opts{'list'}) {
			$field = $opts{'field'};
			$value = $opts{'value'};
			if ($field eq 'name') {
				$query_field = 'resource_name';
			} elsif ($field eq 'description') {
				$query_field = 'resource_note';
			} elsif ($field eq 'fkey') {
				$query_field = 'resource_fkey';
			} elsif ($field eq 'access_note') {
				$query_field = 'resource_access_note';
			} elsif ($field eq 'date_range') {
				$query_field = 'date_range';
			} elsif ($field eq 'creator') {
				$query_field = 'resource_creator';
			}
		}
		if ($opts{'output'}) {
			$output = $opts{'output'};
		}
	}
	if (!$output) {
		$output = 'object';
	}
	my $list_of_ids;
	if (@list_ids && scalar(@list_ids) >= 1) {
		foreach my $list_id (@list_ids) {
			$list_of_ids .= "$list_id, ";
		}
		chop($list_of_ids);
		chop($list_of_ids);
	}
	
	# create and execute a query
	my $dbh = MyLibrary::DB->dbh();
	my $resource_ids;
	if ( ! $sort && $list_of_ids ) { $resource_ids = $dbh->selectcol_arrayref("SELECT resource_id FROM resources WHERE resource_id IN ($list_of_ids)"); }
	elsif ( ! $sort ) { $resource_ids = $dbh->selectcol_arrayref('SELECT resource_id FROM resources'); }
	elsif ( $sort && $sort eq 'name' && ! $list_of_ids && ! $field && ! $value ) { $resource_ids = $dbh->selectcol_arrayref('SELECT resource_id FROM resources ORDER BY resource_name'); } 
	elsif ( $sort && $sort eq 'name' && ! $list_of_ids && $field && $value ) {
	
		if ($field ne 'date_range') { $resource_ids = $dbh->selectcol_arrayref("SELECT resource_id FROM resources WHERE $query_field LIKE \'%$value%\' ORDER BY resource_name");}
		elsif ($field eq 'date_range') {
		
			$value =~ /(.+)?_(.+)/;
			my $date_1 = $1;
			my $date_2 = $2;
			$resource_ids = $dbh->selectcol_arrayref("SELECT resource_id FROM resources WHERE resource_date BETWEEN \'$date_1\' AND \'$date_2\'");
		
		}
		
	}
	
	elsif ( ! $sort && $sort eq 'name' && ! $list_of_ids && $field && $value ) {
	
		if ($field ne 'date_range') { $resource_ids = $dbh->selectcol_arrayref("SELECT resource_id FROM resources WHERE $query_field LIKE \'%$value%\'"); }
		elsif ($field eq 'date_range') {
		
			$value =~ /(.+)?_(.+)/;
			my $date_1 = $1;
			my $date_2 = $2;
			$resource_ids = $dbh->selectcol_arrayref("SELECT resource_id FROM resources WHERE resource_date BETWEEN \'$date_1\' AND \'$date_2\' ORDER BY resource_name");
		
		}
		
	}
	
	elsif ( $sort && $sort eq 'name' && $list_of_ids ) { $resource_ids = $dbh->selectcol_arrayref("SELECT resource_id FROM resources WHERE resource_id IN ($list_of_ids) ORDER BY resource_name"); }
	elsif ( $sort && $sort eq 'creator' && $list_of_ids ) { $resource_ids = $dbh->selectcol_arrayref("SELECT resource_id FROM resources WHERE resource_id IN ($list_of_ids) ORDER BY resource_creator"); } 

	# determine type of output
	if ($output eq 'object') {
		foreach my $resource_id (@$resource_ids) {
			push (@rv, MyLibrary::Resource->new(id => $resource_id));
		}
	} elsif ($output eq 'id') {
		foreach my $resource_id (@$resource_ids) {
			push (@rv, $resource_id);
		}
	} else {
		foreach my $resource_id (@$resource_ids) {
			push (@rv, MyLibrary::Resource->new(id => $resource_id));
		}
	}

	return @rv;
}

sub get_ids {
	my $self = shift;
	my $dbh = MyLibrary::DB->dbh();
	my $resource_ids = $dbh->selectcol_arrayref('SELECT resource_id FROM resources');
	return @{$resource_ids};
}

sub lcd_resources {

	my $class = shift;
	my $first_parameter = shift;
	my @lcd_resources = @_;
	my @rv   = ();
	my $dbh = MyLibrary::DB->dbh();
	
	if ($first_parameter) {
		if ($first_parameter ne 'new' && $first_parameter ne 'del') {
			croak ("Operation parameter supplied is not correct. Parameter \'$first_parameter\' was submitted.\n");
		}
		if (@lcd_resources && scalar(@lcd_resources) > 0) {
			my $resource_list = $dbh->selectcol_arrayref('SELECT resource_id FROM resources');
			my $found;
			foreach my $lcd_resource_id (@lcd_resources) {
				if ($lcd_resource_id !~ /^\d+$/) {
					croak ("Non number submitted as resource id.\n");
				}
				foreach my $resource_id (@$resource_list) {
					if ($lcd_resource_id == $resource_id) {
						$found = 1;
						last;
					} else {
						$found = 0;
					}
				}
				if (!$found) {
					croak ("Resource $lcd_resource_id not found in lcd_resources() method.\n");
				}
			}
		}
		if ($first_parameter eq 'new' && @lcd_resources) {
			foreach my $lcd_resource_id (@lcd_resources) {
				my $rv = $dbh->do('UPDATE resources SET resource_lcd = 1 WHERE resource_id = ?', undef, $lcd_resource_id);
				if ($rv > 1 || ! $rv) { 
					croak ("Resources update in lcd_resources() failed. $rv records were updated.");
				}
			}
		} elsif ($first_parameter eq 'del' && @lcd_resources) {
			foreach my $lcd_resource_id (@lcd_resources) {
				my $rv = $dbh->do('UPDATE resources SET resource_lcd = 0 WHERE resource_id = ?', undef, $lcd_resource_id);
				if ($rv > 1 || ! $rv) {
					croak ("Resources update in lcd_resources() failed. $rv records were updated.");
				}
			}
		}
	}

	my $rows = $dbh->prepare('SELECT * FROM resources WHERE resource_lcd = 1 ORDER BY resource_name');
	$rows->execute();

	# build array
	while (my $row = $rows->fetchrow_hashref()) {
		push (@rv, bless ($row, 'MyLibrary::Resource'));
	}

	return @rv;
}

sub qsearch_redirect {

	my $class = shift;
	my %args = @_;

	unless ($args{'resource_id'}) {
		return;
	}

	my $resource = MyLibrary::Resource->new(id => $args{'resource_id'});
	my $q_prefix = $resource->qsearch_prefix();
	my $q_suffix = $resource->qsearch_suffix();

	unless ($q_prefix) {
		return;
	}

	unless ($args{'qsearch_arg'}) {
		return;
	}

	my $qsearch_arg = $args{'qsearch_arg'};

	my $return_string = $q_prefix . $qsearch_arg . $q_suffix;

	return $return_string;
}

sub get_fkey {

	my $class = shift;
	my @rv = ();

	# connect to database
	my $dbh = MyLibrary::DB->dbh();
	my $rows = $dbh->prepare('SELECT resource_id, resource_fkey FROM resources WHERE resource_fkey IS NOT NULL ORDER BY resource_id');
	$rows->execute();

	# build array
	while (my $row = $rows->fetchrow_hashref()) {
		push (@rv, bless($row, 'MyLibrary::Resource'));
	}
	return @rv;
}

sub test_relation {

	my $self = shift;
	my %opts = @_;
	my $rv = 0;
	use MyLibrary::Term;
	use MyLibrary::Facet;

	if ($opts{'term_name'}) {
		my @term_ids = $self->related_terms();
		foreach my $term_id (@term_ids) {
			my $term = MyLibrary::Term->new(id => $term_id);
			if ($term->term_name() eq $opts{'term_name'}) {
				$rv = 1;
				last;
			}
		}
	} elsif ($opts{'term_id'}) {
		my @term_ids = $self->related_terms();
		foreach my $term_id (@term_ids) {
			if ($term_id == $opts{'term_id'}) {
				$rv = 1;
				last;
			}
		}
	} elsif ($opts{'facet_name'}) {
		my @term_ids = $self->related_terms();
		my $facet = MyLibrary::Facet->new(name => $opts{'facet_name'});
		my @related_term_ids = $facet->related_terms();
		if (!$facet) {
			return 0;
		}
		foreach my $term_id (@term_ids) {
			foreach my $facet_term_id (@related_term_ids) {
				if ($term_id == $facet_term_id) {
					$rv = 1;
					last;
				}
			}
			if ($rv) {
				last;
			}
		}
	} elsif ($opts{'facet_id'}) {
		my @term_ids = $self->related_terms();
		my $facet = MyLibrary::Facet->new(id => $opts{'facet_id'});
		my @related_term_ids = $facet->related_terms();
		if (!$facet) {
			return 0;
		}
		foreach my $term_id (@term_ids) {
			foreach my $facet_term_id (@related_term_ids) {
				if ($term_id == $facet_term_id) {
					$rv = 1;
					last;
				}
			}
			if ($rv) {
				last;
			}
		}
	}
	return $rv;	
}

sub related_terms {

	my $self = shift;
	my %opts = @_;
	my @new_related_terms;
	if ($opts{new}) {
		@new_related_terms = @{$opts{new}};
	}
	my @del_related_terms;
	if ($opts{del}) {
		@del_related_terms = @{$opts{del}};
	}
	my @related_terms;
	my $strict_relations;
	if ($opts{strict}) {
		if ($opts{strict} == 1) {
			$strict_relations = 'on';
		} elsif ($opts{strict} == 0) {
			$strict_relations = 'off';
		} elsif (($opts{strict} !~ /^\d$/ && ($opts{strict} == 1 || $opts{strict} == 0)) || $opts{strict} ne 'off' || $opts{strict} ne 'on') { 
			$strict_relations = 'on';
		} else {
			$strict_relations = $opts{strict};
		}
	} else {
		$strict_relations = 'on';
	}
	if (@new_related_terms) {
		TERMS:	foreach my $new_related_term (@new_related_terms) {
			if ($new_related_term !~ /^\d+$/) {
				croak "Only numeric digits may be submitted as term ids for resource relations. $new_related_term submitted.";
			}
			if ($strict_relations eq 'on') {
				my $dbh = MyLibrary::DB->dbh();
				my $term_list = $dbh->selectcol_arrayref('SELECT term_id FROM terms');
				my $found_term;
				TERM_VAL: foreach my $term_list_val (@$term_list) {
					if ($term_list_val == $new_related_term) {
						$found_term = 1;
						last TERM_VAL;
					} else {
						$found_term = 0;
					}
				}
				if ($found_term == 0) {
					next TERMS;
				}
			}
			my $found = 0;
			if ($self->{related_terms}) {
				foreach my $related_term (@{$self->{related_terms}}) {
					if ($new_related_term == @$related_term[0]) {
						$found = 1;
					} 
				}
			} else {
				$found = 0;
			}
			if ($found) {
				next TERMS;
			} else {
				my @related_term_num = ();
				my $related_term_num = \@related_term_num;
				$related_term_num->[0] = $new_related_term;
				push(@{$self->{related_terms}}, $related_term_num);
			}
		}
	} 
	if (@del_related_terms) {
		foreach my $del_related_term (@del_related_terms) {
			my $j = scalar(@{$self->{related_terms}});
			for (my $i = 0; $i < scalar(@{$self->{related_terms}}); $i++) {
				if ($self->{related_terms}->[$i]->[0] == $del_related_term) {
					splice(@{$self->{related_terms}}, $i, 1);
					$i = $j;
				}
			}
		}
	}
	
	foreach my $related_term (@{$self->{related_terms}}) {
		push(@related_terms, $related_term->[0]);
	}
	
	return @related_terms;
}

sub add_location {

	my $self = shift;
	my %opts = @_;
	unless ($self->id()) {
		$self->{resource_id} = MyLibrary::DB->nextID();
	}
	if (!$opts{location}) {
		croak('add_location() requires location parameter input.');
	}
	if (!$opts{location_type}) {
		croak('add_location() requires location_type parameter input.');
	}
	use MyLibrary::Resource::Location;
	my @resource_locations = MyLibrary::Resource::Location->new(location => $opts{location});
	my $found = 0;
	if (scalar(@resource_locations) >= 1) {
		foreach my $location (@resource_locations) {
			# check to see if this is the correct location/resource_id combination
			if ($location->resource_id() == $self->id()) {
				$found = 1;
				last;
			}
		}
	}
	if ($found) {
		return 2;
	}
	unless ($found) {
		
		my $resource_location = MyLibrary::Resource::Location->new();
		$resource_location->location($opts{location});
		$resource_location->resource_location_type($opts{location_type});
		if ($opts{location_note}) {
			$resource_location->location_note($opts{location_note});
		}
		$resource_location->resource_id($self->id(), strict => 'off');
		$resource_location->commit();
		return 1;
	}
	return 0;
}

sub delete_location {

	my $self = shift;
	my $location_object = shift;
	if (ref($location_object) ne 'MyLibrary::Resource::Location') {
		croak('Location object not passed to delete_location() method.');
	}
	$location_object->delete();
	return 1;

}

sub modify_location {

	my $self = shift;
	my $location_object = shift;
	my %opts = @_;
	if (ref($location_object) ne 'MyLibrary::Resource::Location') {
		croak('Location object not passed to modify_location() method.');
	}
	if (!$opts{resource_location} && !$opts{location_note}) {
		croak('missing parameter for modify_location() method.');
	}
	if ($opts{resource_location}) {
		$location_object->location($opts{resource_location});
	}
	if ($opts{location_note}) {
		$location_object->location_note($opts{location_note});
	} elsif (!$opts{location_note} || $opts{location_note} =~ /^\s+$/) {
		$location_object->delete_location_note();
	}
	$location_object->commit();
	return 1;

}

sub get_location {
	my $self = shift;
	my %opts = @_;
	if (!$opts{resource_location} && !$opts{id}) {
		croak ('Necessary paramter missing in call to get_location() method.');
	} elsif ($opts{resource_location} && $opts{id}) {
		croak ('Too many parameters entered for get_location() method.');
	}
	if ($opts{id}) {
		my $location = MyLibrary::Resource::Location->new(id => $opts{id});
		return $location;
	} elsif ($opts{resource_location}) {
		my @locations = MyLibrary::Resource::Location->new(location => $opts{resource_location});
		if (scalar(@locations) >= 1) {
			foreach my $location (@locations) {
				if ($location->resource_id() == $self->id()) {
					return $location;
				}
			}
		} else {
			return 0;
		}
	}	

	# non specific error	
	return 0;

}

sub resource_locations {

	my $self = shift;
	use MyLibrary::Resource::Location;
	unless ($self->id() =~ /\d+/) {
		return;
	}
	my @resource_locations = MyLibrary::Resource::Location->get_locations(id => $self->id());
	return @resource_locations;

}


# return true
1;
