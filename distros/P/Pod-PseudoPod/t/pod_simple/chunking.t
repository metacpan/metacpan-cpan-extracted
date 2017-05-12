
#use Pod::Simple::Debug (2);

use strict;
use Test;
BEGIN { plan tests => 11 };

BEGIN {
    chdir 't' if -d 't';
#    unshift @INC, '../../blib/lib';
    unshift @INC, '../../lib';
}

ok 1;

use Pod::PseudoPod::DumpAsXML;
use Pod::PseudoPod::XMLOutStream;
print "# Pod::PseudoPod version $Pod::PseudoPod::VERSION\n";
sub e ($$) { Pod::PseudoPod::DumpAsXML->_duo(@_) }

ok( Pod::PseudoPod::XMLOutStream->_out("=head1 =head1"),
    '<Document><head1>=head1</head1></Document>'
);

ok( Pod::PseudoPod::XMLOutStream->_out("\n=head1 =head1"),
    '<Document><head1>=head1</head1></Document>'
);

ok( Pod::PseudoPod::XMLOutStream->_out("\n=head1 =head1\n"),
    '<Document><head1>=head1</head1></Document>'
);

ok( Pod::PseudoPod::XMLOutStream->_out("\n=head1 =head1\n\n"),
    '<Document><head1>=head1</head1></Document>'
);

&ok(e "\n=head1 =head1\n\n" , "\n=head1 =head1\n\n");

&ok(e "\n=head1\n=head1\n\n", "\n=head1 =head1\n\n");

&ok(e "\n=pod\n\nCha cha cha\n\n" , "\n=pod\n\nCha cha cha\n\n");
&ok(e "\n=pod\n\nCha\tcha  cha\n\n" , "\n=pod\n\nCha cha cha\n\n");
&ok(e "\n=pod\n\nCha\ncha  cha\n\n" , "\n=pod\n\nCha cha cha\n\n");

print "# Wrapping up... one for the road...\n";
ok 1;
print "# --- Done with ", __FILE__, " --- \n";

