# Before `make install' is performed this script should be runnable with
# `make test'.

#########################

use Test::More tests => 39;
BEGIN { use_ok('Polycom::Contact') };
BEGIN { use_ok('Polycom::Contact::Directory') };

# Test that the appropriate methods exist
can_ok('Polycom::Contact', qw(new diff delete is_valid));
can_ok('Polycom::Contact::Directory', qw(new insert all count equals is_valid save search to_xml));

# Test parsing a very simple contact directory
{
    my $xml = <<'DIR_XML';
    <directory>
      <item_list>
        <item>
          <ln>Doe</ln>
          <fn>John</fn>
          <ct>1234</ct>
          <sd>1</sd>
          <rt>3</rt>
          <dc>0</dc>
          <ad>0</ad>
          <ar>0</ar>
          <bw>0</bw>
          <bb>0</bb>
        </item>
        <item>
          <ln>Johnson</ln>
          <fn>Bobby</fn>
          <ct>224</ct>
        </item>
      </item_list>
    </directory>
DIR_XML

    my $dir = Polycom::Contact::Directory->new($xml);
    is($dir->count, 2);

    my @contacts = $dir->all;
    my $contact = $contacts[0];
    is($contact->{first_name}, 'John');
    is($contact->{last_name},  'Doe');
    is($contact->{contact},    1234);
    is($contact->{speed_index}, 1);
    is($contact->{ring_type},   3);
    is($contact->{divert},      0);
    is($contact->{auto_reject}, 0);
    is($contact->{auto_divert}, 0);
    is($contact->{buddy_watching}, 0);
    is($contact->{buddy_block}, 0);

    is($contact->first_name, 'John');
    is($contact->last_name,  'Doe');
    is($contact->contact,    1234);
    is($contact->speed_index, 1);
    is($contact->ring_type,   3);
    is($contact->divert,      0);
    is($contact->auto_reject, 0);
    is($contact->auto_divert, 0);
    is($contact->buddy_watching, 0);
    is($contact->buddy_block, 0);

    # Test searching and deleting from a directory
    my @doe = $dir->search({ last_name => 'Doe' });
    is(scalar(@doe), 1);

    $doe[0]->delete;

    @doe = $dir->search({ last_name => 'Doe' });
    is(scalar(@doe), 0);

    my @smith = $dir->search({ last_name => 'Smith' });
    is(scalar(@smith), 0);
}

# Test contact object stringification
{
    my $bob = Polycom::Contact->new( 
        first_name => 'Bob', 
        last_name  => 'Smith', 
        contact    => '1234', 
    ); 
     
    is("$bob", 'Bob Smith at 1234');
}

# Test creating a contact directory from scratch
{
    my $contactDirectory = Polycom::Contact::Directory->new();
    $contactDirectory->insert(
       {   first_name => 'Bob',
           last_name  => 'Smith',
           contact    => '1',
       },
       {   first_name => 'Jenny',
           last_name  => 'Xu',
           contact    => '2',
       },
       {   first_name => 'Jacky',
           last_name  => 'Cheng',
           contact    => '3',
       },
     );

    my $xml = $contactDirectory->to_xml;
    ok($xml =~ /<fn>Bob<\/fn>/);
    ok($xml =~ /<ln>Smith<\/ln>/);
    ok($xml =~ /<ct>1<\/ct>/);
    ok($xml =~ /<fn>Jenny<\/fn>/);
    ok($xml =~ /<ln>Xu<\/ln>/);
    ok($xml =~ /<ct>2<\/ct>/);
    ok($xml =~ /<fn>Jacky<\/fn>/);
    ok($xml =~ /<ln>Cheng<\/ln>/);
    ok($xml =~ /<ct>3<\/ct>/);
}

# Test saving an empty directory
{
    my $contactDirectory = Polycom::Contact::Directory->new();

    my $xml = $contactDirectory->to_xml;
    ok($xml =~ /<directory>\s*<item_list>\s*<\/item_list>\s*<\/directory>/);
}


