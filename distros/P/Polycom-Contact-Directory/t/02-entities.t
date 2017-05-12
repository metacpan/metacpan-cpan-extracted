# Before `make install' is performed this script should be runnable with
# `make test'.

#########################
use Test::More tests => 17;
BEGIN { use_ok('Polycom::Contact') };
BEGIN { use_ok('Polycom::Contact::Directory') };

# Test parsing directories that contain XML character entities
{
    my $xml = <<'DIR_XML';
    <directory>
      <item_list>
        <item>
          <ln>&amp;&lt;&amp;</ln>
          <fn>&quot;&apos;</fn>
          <ct>1234</ct>
        </item>
        <item>
          <ln>Bob&amp;</ln>
          <fn>Smith&amp;</fn>
          <ct>5324</ct>
        </item>
      </item_list>
    </directory>
DIR_XML

    my $dir = Polycom::Contact::Directory->new($xml);
    is($dir->count, 2);

    my @contacts = $dir->all;
    my $contact = $contacts[0];
    is($contact->{first_name}, '"\'');
    is($contact->{last_name},  '&<&');
    $contact = $contacts[1];
    is($contact->{first_name}, 'Smith&');
    is($contact->{last_name},  'Bob&');

    my @doe = $dir->search({ last_name => '&<&' });
    is(scalar(@doe), 1);

    $doe[0]->delete;

    @doe = $dir->search({ last_name => '&<&' });
    is(scalar(@doe), 0);

    my @smith = $dir->search({ last_name => '&<&' });
    is(scalar(@smith), 0);
}

# Test contact object stringification
{
    my $bob = Polycom::Contact->new( 
        first_name => '<&>', 
        last_name  => '>&>', 
        contact    => '1234', 
    ); 
     
    is("$bob", '<&> >&> at 1234');
}

# Create a contact directory
{
    my $contactDirectory = Polycom::Contact::Directory->new();
    $contactDirectory->insert(
       {   first_name => '<&>',
           last_name  => '>&<',
           contact    => '1',
       },
       {   first_name => '"',
           last_name  => '\'',
           contact    => '2',
       },
     );

    # Create an XML file suitable for being read by the phone
    my $xml2 = $contactDirectory->to_xml;
    ok($xml2 =~ /<fn>&lt;&amp;&gt;<\/fn>/);
    ok($xml2 =~ /<ln>&gt;&amp;&lt;<\/ln>/);
    ok($xml2 =~ /<ct>1<\/ct>/);
    ok($xml2 =~ /<fn>&quot;<\/fn>/);
    ok($xml2 =~ /<ln>&apos;<\/ln>/);
    ok($xml2 =~ /<ct>2<\/ct>/);
}



