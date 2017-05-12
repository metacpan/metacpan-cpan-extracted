package Parse::YALALR::Common;

# API:
# use Parse::YALALR::Common;
# print "Normal: $x Escaped: $E{$x}\n"; # (XML escaping)
# print "You are holding $n $P{'ball',$n}\n"; # (pluralization)

use strict;
no strict 'refs';

sub import {
    &Parse::YALALR::Common::XMLEscape::import;
    &Parse::YALALR::Common::XMLUnescape::import;
    &Parse::YALALR::Common::Identity::import;
    &Parse::YALALR::Common::Plural::import;
}


###################### XMLEscape, XMLUnescape ########################

package Parse::YALALR::Common::XMLEscape;
sub escape ($) {
    my $x = shift;
    $x =~ s/\&/\&amp;/g; # Must come first!
    $x =~ s/<-/\&larrow;/g;
    $x =~ s/->/\&arrow;/g;
    $x =~ s/<=/\&dlarrow;/g;
    $x =~ s/=>/\&darrow;/g;
    $x =~ s/</\&lt;/g;
    $x =~ s/>/\&gt;/g;
    $x;
}

sub FETCH { escape($_[1]) }
sub TIEHASH { bless {}, __PACKAGE__ }

sub import {
    my $p = caller(1); # caller(0) eq Parse::Vipar::Common
    tie %{"${p}::E"}, __PACKAGE__;
    *{"${p}::E"} = \%{"${p}::E"}; # use vars '%E' for caller
}

package Parse::YALALR::Common::XMLUnescape;

sub unescape ($) {
    my $x = shift;
    $x =~ s/\&lt;/</g;
    $x =~ s/\&gt;/>/g;
    $x =~ s/\&arrow;/->/g;
    $x =~ s/\&larrow;/<-/g;
    $x =~ s/\&darrow;/=>/g;
    $x =~ s/\&dlarrow;/<=/g;
    $x =~ s/\&ldarrow;/<=/g;
    $x;
}

sub FETCH { unescape($_[1]) }
sub TIEHASH { bless {}, __PACKAGE__ }

sub import {
    my $p = caller(1);
    tie %{"${p}::U"}, __PACKAGE__;
    *{"${p}::U"} = \%{"${p}::U"}; # use vars '%U' for caller
}

###################### Plural ########################

package Parse::YALALR::Common::Plural;
sub pluralize ($) {
    my ($word, $n) = split(/$;/, shift(), 2);
    return ($n == 1) ? $word : "${word}s";
}
sub FETCH { pluralize($_[1]) }
sub TIEHASH { bless {}, __PACKAGE__ }

sub import {
    my $p = caller(1);
    tie %{"${p}::P"}, __PACKAGE__;
    *{"${p}::P"} = \%{"${p}::P"}; # use vars '%E' for caller
}

###################### Identity ########################

package Parse::YALALR::Common::Identity;
sub FETCH { $_[1] }
sub TIEHASH { bless {}, __PACKAGE__ }

sub import {
    my $p = caller(1);
    tie %{"${p}::ID"}, __PACKAGE__;
    *{"${p}::ID"} = \%{"${p}::ID"}; # use vars '%ID' for caller
}

1;
