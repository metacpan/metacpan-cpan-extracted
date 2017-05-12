#!/usr/bin/perl -w

package My::Template;

use strict;
use Test::More tests => 137;

BEGIN { use_ok 'Template::Declare::Tags', 'Bricolage' or die };

# Check functions exported here.
for my $f (@{ Template::Declare::TagSet::Bricolage->get_tag_list }) {
    $f = Template::Declare::TagSet::Bricolage->get_alternate_spelling($f) || $f;
    ok defined &{$f}, "$f {} should be exported";
}

# Try using them.
use base 'Template::Declare';
template bricolage => sub {
    xml_decl { 'xml', version => '1.0', encoding => 'utf-8' };
    assets {
        attr { xmlns =>  'http://bricolage.sourceforge.net/assets.xsd' };
        story {
            attr { id => 1234, type => 'story' };
            name { 'This is the title' }
        };
    };
};

package main;
use Test::More;
use Test::XML;
use Template::Declare;

Template::Declare->init( roots => ['My::Template']);
is_xml(Template::Declare->show('bricolage'), <<'    EOX', 'We should be able to generate XML' );
    <assets xmlns="http://bricolage.sourceforge.net/assets.xsd">
      <story id="1234" type="story">
        <name>This is the title</name>
      </story>
    </assets>
    EOX
