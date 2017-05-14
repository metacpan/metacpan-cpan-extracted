use Test::More tests => 17;
use strict;

# use the module
use_ok('MyLibrary::Librarian');

# create a librarian object
my $librarian = MyLibrary::Librarian->new();
isa_ok($librarian, "MyLibrary::Librarian");

# set the librarian's name
$librarian->name('Eric Lease Morgan');
is($librarian->name, 'Eric Lease Morgan', 'set name()');

# set the librarian's telephone number
$librarian->telephone('(574) 631-8604');
is($librarian->telephone, '(574) 631-8604', 'set telephone()');

# set the librarian's email address
$librarian->email('emorgan@nd.edu');
is($librarian->email, 'emorgan@nd.edu', 'set email()');

# set the librarian's url to their home page
$librarian->url('http://infomotions.com/');
is($librarian->url, 'http://infomotions.com/', 'set url()');

# set the librarian's term ids
my @vars = $librarian->term_ids(new => [9999991, 9999992, 9999993], strict => 'off');
is(scalar(@vars), 3, 'set term_ids()');

# save a new librarian record
is($librarian->commit(), '1', 'commit()');

# get a librarian id
my $id = $librarian->id();
like ($id, qr/^\d+$/, 'get id()');

# get record based on an id
$librarian = MyLibrary::Librarian->new(id => $id);
is ($librarian->name(), 'Eric Lease Morgan', 'get name()');
is ($librarian->telephone(), '(574) 631-8604', 'get telephone()');
is ($librarian->email(), 'emorgan@nd.edu', 'get email()');
is ($librarian->url(), 'http://infomotions.com/', 'get url()');

# update a librarian
$librarian->name('Alcuin');
$librarian->telephone('555-1212');
$librarian->email('alcuin@infomotions.com');
$librarian->url('http://infomotions.com/alcuin/');
$librarian->commit();
$librarian = MyLibrary::Librarian->new(id => $id);
is ($librarian->email, 'alcuin@infomotions.com', 'commit()');

# delete a term association
my @terms = $librarian->term_ids(del => [9999992], strict => 'off');
$librarian->commit();
is (scalar($librarian->term_ids()), 2, 'delete term_ids()');

# get librarians
my @l = MyLibrary::Librarian->get_librarians;
my $flag = 0;
foreach $librarian (@l) { 
	if ($librarian->{name} =~ /Alcuin/) { $flag = 1; }
}
is ($flag, 1, 'get_librarians()');

# delete a librarian
is ($librarian->delete(), '1', 'delete() a librarian');
