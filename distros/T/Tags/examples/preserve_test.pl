#!/usr/bin/env perl

use strict;
use warnings;

use Tags::Utils::Preserve;

# Begin element helper.
sub begin_helper {
        my ($pr, $element) = @_;
        print "ELEMENT: $element ";
        my ($pre, $pre_pre) = $pr->begin($element);
        print "PRESERVED: $pre PREVIOUS PRESERVED: $pre_pre\n";
}

# End element helper.
sub end_helper {
        my ($pr, $element) = @_;
        print "ENDELEMENT: $element ";
        my ($pre, $pre_pre) = $pr->end($element);
        print "PRESERVED: $pre PREVIOUS PRESERVED: $pre_pre\n";

}

# Object.
my $pr = Tags::Utils::Preserve->new(
        'preserved' => ['element']
);

# Process.
begin_helper($pr, 'foo');
begin_helper($pr, 'element');
begin_helper($pr, 'foo');
end_helper($pr, 'foo');
end_helper($pr, 'element');
end_helper($pr, 'foo');

# Output:
# ELEMENT: foo PRESERVED: 0 PREVIOUS PRESERVED: 0
# ELEMENT: element PRESERVED: 1 PREVIOUS PRESERVED: 0
# ELEMENT: foo PRESERVED: 1 PREVIOUS PRESERVED: 1
# ENDELEMENT: foo PRESERVED: 1 PREVIOUS PRESERVED: 1
# ENDELEMENT: element PRESERVED: 0 PREVIOUS PRESERVED: 1
# ENDELEMENT: foo PRESERVED: 0 PREVIOUS PRESERVED: 0