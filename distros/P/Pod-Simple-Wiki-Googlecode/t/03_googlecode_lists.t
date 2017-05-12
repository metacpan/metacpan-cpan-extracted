#!/usr/bin/perl -w

###############################################################################
#
# A test for Pod::Simple::Wiki.
#
# Tests for =over ... =back regions.
#
# copied from Pod::Simple::Wiki
# reverse('©'), March 2005, John McNamara, jmcnamara@cpan.org
#


use strict;

use Pod::Simple::Wiki;
use Test::More tests => 10;

my $style = 'googlecode';

# Output the tests for visual testing in the wiki.
# END{output_tests()};

my @tests;

#
# Extract tests embedded in _DATA_ section.
#
my $test_no = 1;
my $pod;
my $test = '';
my $todo = '';;
my $name;

while (<DATA>) {
    if (/^#/) {
        $name = $1 if /NAME: (.*)/;
        $todo = $1 if /TODO: (.*)/;

        if ($test) {
            if ($test_no % 2) {
                $pod = $test;
            }
            else {
                push @tests, [$pod, $test, $name, $todo];
                $name = '';
                $todo = '';
            }

            $test = '';
            $test_no++;
        }
        next;
    }
    s/\r//;     # Remove any \r chars that slip in.
    s/\\t/\t/g; # Sub back in any escaped tabs.
    s/\\#/#/g;  # Sub back in any escaped comments.
    $test .= $_;
}


###############################################################################
#
#  Run the tests.
#
for my $test_ref (@tests) {

    my $parser  = Pod::Simple::Wiki->new($style);
    my $pod     = $test_ref->[0];
    my $target  = $test_ref->[1];
    my $name    = $test_ref->[2];
    my $todo    = $test_ref->[3];
    my $wiki;

    $parser->output_string(\$wiki);
    $parser->parse_string_document($pod);

    local $TODO = $todo;
    is($wiki, $target, " \t" . $name);
}


###############################################################################
#
# Output the tests for visual testing in the wiki.
#
sub output_tests {

    my $test = 1;

    print "\n----\n\n";

    for my $test_ref (@tests) {

        my $parser  =  Pod::Simple::Wiki->new($style);
        my $pod     =  $test_ref->[0];
        my $name    =  $test_ref->[2];

        print "Test ", $test++, ":\t", $name, "\n";
        $parser->parse_string_document($pod);
        print "\n----\n\n";
    }
}

__DATA__
################################################################################
#
# Test data.
#
################################################################################
#
# NAME: Test for single unordered (bullet) item.
#
=pod

=over

=item *

Bullet item

=back

=cut
#
#
# Expected output.
#
#
  * Bullet item

################################################################################
#
# NAME: Test for unordered (bullet) list, <ul>.
#
=pod

=over

=item *

Bullet item 1.0

=item *

Bullet item 2.0

=item *

Bullet item 3.0

=back

=cut
#
#
# Expected output.
#
#
  * Bullet item 1.0
  * Bullet item 2.0
  * Bullet item 3.0

###############################################################################
#
# NAME: Test for nested unordered (bullet) list, <ul>.
#
=pod

=over

=item *

Bullet item 1.0

=over

=item *

Bullet item 1.1

=over

=item *

Bullet item 1.2

=item *

Bullet item 2.2

=back


=item *

Bullet item 2.1

=back

=item *

Bullet item 2.0

=back

=cut
#
#
# Expected output.
#
#
  * Bullet item 1.0
    * Bullet item 1.1
      * Bullet item 1.2
      * Bullet item 2.2
    * Bullet item 2.1
  * Bullet item 2.0

################################################################################
#
# NAME: Test for single ordered (number) item.
#
=pod

=over

=item 1

Number item

=back

=cut
#
#
# Expected output.
#
#
  # Number item

###############################################################################
#
# NAME: Test for ordered (number) list, <ol>.
#
=pod

=over

=item 1

Number item 1.0

=item 2

Number item 2.0

=item 3

Number item 3.0

=back

=cut
#
#
# Expected output.
#
#
  # Number item 1.0
  # Number item 2.0
  # Number item 3.0

###############################################################################
#
# NAME: Test for nested ordered (number) list, <ol>.
#
=pod

=over

=item 1

Number item 1.0

=over

=item 1

Number item 1.1

=over

=item 1

Number item 1.2

=item 2

Number item 2.2

=back

=item 2

Number item 2.1

=back

=item 2

Number item 2.0

=back

=cut
#
#
# Expected output.
#
#
  # Number item 1.0
    # Number item 1.1
      # Number item 1.2
      # Number item 2.2
    # Number item 2.1
  # Number item 2.0

################################################################################
#
# NAME: Test for single definition list item.
#
=pod

=over

=item Foo

Definition item

=back

=cut
#
#
# Expected output.
#
#
=== Foo ===
Definition item

###############################################################################
#
# NAME: Test for definition list, <dl>.
#
=pod

=over

=item Foo

Definition item 1.0

=item Bar

Definition item 2.0

=item Baz

Definition item 3.0

=back

=cut
#
#
# Expected output.
#
#
=== Foo ===
Definition item 1.0
=== Bar ===
Definition item 2.0
=== Baz ===
Definition item 3.0

###############################################################################
#
# NAME: Test for nested definition list, <dl>.
#
=pod

=over

=item Foo

Definition item 1.0

=over

=item Foo

Definition item 1.1

=over

=item Foo

Definition item 1.2

=item Bar

Definition item 2.2

=back

=item Bar

Definition item 2.1

=back

=item Bar

Definition item 2.0

=back

=cut
#
#
# Expected output.
#
#
=== Foo ===
Definition item 1.0
==== Foo ====
Definition item 1.1
===== Foo =====
Definition item 1.2
===== Bar =====
Definition item 2.2
==== Bar ====
Definition item 2.1
=== Bar ===
Definition item 2.0

###############################################################################
#
# NAME: Test for varied nested list.
#
=pod

=over

=item *

Bullet item 1.0

=over

=item 1

Number item 1.1

=over

=item Foo

Definition item 1.2

=item Bar

Definition item 2.2

=back

=item 2

Number item 2.1

=back

=item *

Bullet item 2.0

=back

=cut
#
#
# Expected output.
#
#
  * Bullet item 1.0
    # Number item 1.1
===== Foo =====
Definition item 1.2
===== Bar =====
Definition item 2.2
    # Number item 2.1
  * Bullet item 2.0

###############################################################################
#
# End
#
###############################################################################
