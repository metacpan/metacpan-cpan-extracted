#!/usr/bin/perl -w

use strict;
use Test::More tests => 146;
use Test::XML;

BEGIN { use_ok 'Template::Declare::Bricolage' or die; }

# Check functions in the module.
for my $f (qw(bricolage assets private template xml_decl attr)) {
    ok defined &{"Template::Declare::Bricolage::$f"},
        "Template::Declare::Bricolage::$f() should be defined";
}

# Check functions exported here.
ok defined &bricolage, 'bricolage {} should be exported';
ok defined &is, 'is {} should be exported';
for my $f (@{ Template::Declare::TagSet::Bricolage->get_tag_list }) {
    $f = Template::Declare::TagSet::Bricolage->get_alternate_spelling($f) || $f;
    ok defined &{$f}, "$f {} should be exported";
}

# Make sure that we can use those functions to generate XML.
is_xml bricolage {
    story {
        attr { id => 1234, type => 'story' };
        name { 'This is the title' };
    }
}, <<'    EOX', 'bricolage { } should work';
    <assets xmlns="http://bricolage.sourceforge.net/assets.xsd">
      <story id="1234" type="story">
        <name>This is the title</name>
      </story>
    </assets>
    EOX

# Make sure that the synopsis example works.
is_xml bricolage {
    workflow {
        attr { id => 1027 };
        name   { 'Blogs' }
        description { 'Blog Entries' }
        site   { 'Main Site' }
        type   { 'Story' }
        active { 1 }
        desks  {
            desk { attr { start => 1 };   'Blog Edit' }
            desk { attr { publish => 1}; 'Blog Publish' }
        }
    }
}, <<'    EOX', 'Synopsis example should work';
    <assets xmlns="http://bricolage.sourceforge.net/assets.xsd">
     <workflow id="1027">
      <name>Blogs</name>
      <description>Blog Entries</description>
      <site>Main Site</site>
      <type>Story</type>
      <active>1</active>
      <desks>
       <desk start="1">Blog Edit</desk>
       <desk publish="1">Blog Publish</desk>
      </desks>
     </workflow>
    </assets>
    EOX


