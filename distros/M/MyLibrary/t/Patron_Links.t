use Test::More tests => 10;
use strict;

# use the module
use_ok('MyLibrary::Patron::Links');

# create a bogus patron record
use MyLibrary::Patron;
my $patron = MyLibrary::Patron->new();
$patron->patron_firstname('Johan');
$patron->patron_surname('Hamann');
$patron->patron_stylesheet_id('4');
$patron->commit();
my $patron_id = $patron->patron_id();

# create a patron link object
my $patron_link = MyLibrary::Patron::Links->new();
isa_ok($patron_link, "MyLibrary::Patron::Links");

# set the link name attribute
$patron_link->link_name('TEST LINK');
is($patron_link->link_name(), 'TEST LINK', 'set link_name()');

# set the link URL attribute
$patron_link->link_url('http://test_site.mysite.com');
is($patron_link->link_url(), 'http://test_site.mysite.com', 'set link_url()');

# associate a patron with this link
$patron_link->patron_id($patron_id);
is($patron_link->patron_id(), $patron_id, 'set patron_id()');

# save new patron link record
$patron_link->commit();
my $link_id = $patron_link->link_id();
like ($link_id, qr/^\d+$/, 'get link_id()');

# get list of associated links for patron id
my @link_ids = MyLibrary::Patron::Links->get_links(patron_id => $patron_id);
cmp_ok (scalar(@link_ids), '>=', 1, 'get_links()');

# get link record based on id
my $patron_link2 = MyLibrary::Patron::Links->new(id => $link_id);
is($patron_link2->link_name(), 'TEST LINK', 'get link_name()');
is($patron_link2->link_url(), 'http://test_site.mysite.com', 'get link_url()');

# update link record
$patron_link2->link_name('TEST LINK2');
$patron_link2->commit();
my $patron_link3 = MyLibrary::Patron::Links->new(id => $link_id);
is($patron_link3->link_name(), 'TEST LINK2', 'commit()');

# delete bogus patron
$patron->delete();

# delete patron link
$patron_link->delete();
