
use strict;
use Test;
BEGIN { plan tests => 13 };

BEGIN {
    chdir 't' if -d 't';
#    unshift @INC, '../../blib/lib';
    unshift @INC, '../../lib';
}

#use Pod::PseudoPod::Debug (6);

ok 1;

use Pod::PseudoPod::DumpAsXML;
use Pod::PseudoPod::XMLOutStream;
print "# Pod::PseudoPod version $Pod::PseudoPod::VERSION\n";
sub e ($$) { Pod::PseudoPod::DumpAsXML->_duo(@_) }

my $x = 'Pod::PseudoPod::XMLOutStream';

# changed N to Q, because N is a valid code in PseudoPod
sub accept_Q { $_[0]->accept_codes('Q') }

print "# Some sanity tests...\n";
ok( $x->_out( "=pod\n\nI like pie.\n"), # without acceptor
  '<Document><Para>I like pie.</Para></Document>'
);
ok( $x->_out( \&accept_Q, "=pod\n\nI like pie.\n"),
  '<Document><Para>I like pie.</Para></Document>'
);
ok( $x->_out( "=pod\n\nB<foo\t>\n"), # without acceptor
  '<Document><Para><B>foo </B></Para></Document>'
);
ok( $x->_out( \&accept_Q,  "=pod\n\nB<foo\t>\n"),
  '<Document><Para><B>foo </B></Para></Document>'
);

print "# Some real tests...\n";

ok( $x->_out( \&accept_Q,  "=pod\n\nQ<foo\t>\n"),
  '<Document><Para><Q>foo </Q></Para></Document>'
);
ok( $x->_out( \&accept_Q,  "=pod\n\nB<Q<foo\t>>\n"),
  '<Document><Para><B><Q>foo </Q></B></Para></Document>'
);
ok( $x->_out( "=pod\n\nB<Q<foo\t>>\n") # without the mutor
  ne '<Document><Para><B><Q>foo </Q></B></Para></Document>'
  # make sure it DOESN'T pass thru the Q<...> when not accepted
);
ok( $x->_out( \&accept_Q,  "=pod\n\nB<pieF<zorch>Q<foo>I<pling>>\n"),
  '<Document><Para><B>pie<F>zorch</F><Q>foo</Q><I>pling</I></B></Para></Document>'
);

print "# Tests of nonacceptance...\n";

sub starts_with {
  my($large, $small) = @_;
  print("# supahstring is undef\n"),
   return '' unless defined $large;
  print("# supahstring $large is smaller than target-starter $small\n"),
   return '' if length($large) < length($small);
  if( substr($large, 0, length($small)) eq $small ) {
    #print "# Supahstring $large\n#  indeed starts with $small\n";
    return 1;
  } else {
    print "# Supahstring $large\n#  !starts w/ $small\n";
    return '';
  }
}


ok( starts_with( $x->_out( "=pod\n\nB<Q<foo\t>>\n"), # without the mutor
  '<Document><Para><B>foo </B></Para>'
  # make sure it DOESN'T pass thru the Q<...>, when not accepted
));

ok( starts_with( $x->_out( "=pod\n\nB<pieF<zorch>Q<foo>I<pling>>\n"), # !mutor
  '<Document><Para><B>pie<F>zorch</F>foo<I>pling</I></B></Para>'
  # make sure it DOESN'T pass thru the Q<...>, when not accepted
));

ok( starts_with( $x->_out( "=pod\n\nB<pieF<zorch>Q<C<foo>>I<pling>>\n"), # !mutor
  '<Document><Para><B>pie<F>zorch</F><C>foo</C><I>pling</I></B></Para>'
  # make sure it DOESN'T pass thru the Q<...>, when not accepted
));




print "# Wrapping up... one for the road...\n";
ok 1;
print "# --- Done with ", __FILE__, " --- \n";

