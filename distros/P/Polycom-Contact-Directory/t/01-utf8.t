# Before `make install' is performed this script should be runnable with
# `make test'.

#########################
use utf8;
use Test::More tests => 25;
BEGIN { use_ok('Polycom::Contact') };
BEGIN { use_ok('Polycom::Contact::Directory') };

# Test parsing of directories that contain non-ASCII UTF-8 characters
{
    my $xml = <<'DIR_XML';
    <directory>
      <item_list>
        <item>
          <ln>àæøý</ln>
          <fn>ë</fn>
          <ct>1234</ct>
        </item>
        <item>
          <ln>ГДЕЅЗ</ln>
          <fn>АБВГДЕЖ</fn>
          <ct>224</ct>
        </item>
        <item>
          <ln>マージャン</ln>
          <fn>ウーロン茶</fn>
          <ct>6545</ct>
        </item>
      </item_list>
    </directory>
DIR_XML

    my $dir = Polycom::Contact::Directory->new($xml);
    is($dir->count, 3);

    my @contacts = $dir->all;
    my $contact = $contacts[0];
    is($contact->{first_name}, 'ë');
    is($contact->{last_name},  'àæøý');
    $contact = $contacts[1];
    is($contact->{first_name}, 'АБВГДЕЖ');
    is($contact->{last_name},  'ГДЕЅЗ');
    $contact = $contacts[2];
    is($contact->{first_name}, 'ウーロン茶');
    is($contact->{last_name},  'マージャン');

    my @doe = $dir->search({ last_name => 'ГДЕЅЗ' });
    is(scalar(@doe), 1);

    $doe[0]->delete;

    @doe = $dir->search({ last_name => 'ГДЕЅЗ' });
    is(scalar(@doe), 0);

    my @smith = $dir->search({ last_name => 'Smith' });
    is(scalar(@smith), 0);
}

# Test contact object stringification
{
    my $bob = Polycom::Contact->new( 
        first_name => 'АБВГДЕЖ', 
        last_name  => 'àæøý', 
        contact    => '1234', 
    ); 
     
    is("$bob", 'АБВГДЕЖ àæøý at 1234');
}

# Create a contact directory containing UTF-8 characters
{
    my $contactDirectory = Polycom::Contact::Directory->new();
    $contactDirectory->insert(
       {   first_name => 'Bob',
           last_name  => 'àæøý',
           contact    => '1',
       },
       {   first_name => 'Jenny',
           last_name  => 'Xu',
           contact    => '2',
       },
       {   first_name => 'マージャン',
           last_name  => 'Cheng',
           contact    => '3',
       },
       {   first_name => 'ГДЕЅЗ',
           last_name  => 'АБВГДЕЖ',
           contact    => '4',
       },
     );

    # Create an XML file suitable for being read by the
    # phone that contains UTF-8 characters
    my $xml = $contactDirectory->to_xml;
    ok($xml =~ /<fn>Bob<\/fn>/);
    ok($xml =~ /<ln>àæøý<\/ln>/);
    ok($xml =~ /<ct>1<\/ct>/);
    ok($xml =~ /<fn>Jenny<\/fn>/);
    ok($xml =~ /<ln>Xu<\/ln>/);
    ok($xml =~ /<ct>2<\/ct>/);
    ok($xml =~ /<fn>マージャン<\/fn>/);
    ok($xml =~ /<ln>Cheng<\/ln>/);
    ok($xml =~ /<ct>3<\/ct>/);
    ok($xml =~ /<fn>ГДЕЅЗ<\/fn>/);
    ok($xml =~ /<ln>АБВГДЕЖ<\/ln>/);
    ok($xml =~ /<ct>4<\/ct>/);
}


