#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Utils::Preserve;

# Begin element helper.
sub begin_helper {
        my ($pr, $tag) = @_;
        print "TAG: $tag ";
        my ($pre, $pre_pre) = $pr->begin($tag);
        print "PRESERVED: $pre PREVIOUS PRESERVED: $pre_pre\n";
}

# End element helper.
sub end_helper {
        my ($pr, $tag) = @_;
        print "ENDTAG: $tag ";
        my ($pre, $pre_pre) = $pr->end($tag);
        print "PRESERVED: $pre PREVIOUS PRESERVED: $pre_pre\n";

}

# Object.
my $pr = Tags::Utils::Preserve->new(
        'preserved' => ['tag']
);

# Process.
begin_helper($pr, 'foo');
begin_helper($pr, 'tag');
begin_helper($pr, 'foo');
end_helper($pr, 'foo');
end_helper($pr, 'tag');
end_helper($pr, 'foo');

# Output:
# TAG: foo PRESERVED: 0 PREVIOUS PRESERVED: 0
# TAG: tag PRESERVED: 1 PREVIOUS PRESERVED: 0
# TAG: foo PRESERVED: 1 PREVIOUS PRESERVED: 1
# ENDTAG: foo PRESERVED: 1 PREVIOUS PRESERVED: 1
# ENDTAG: tag PRESERVED: 0 PREVIOUS PRESERVED: 1
# ENDTAG: foo PRESERVED: 0 PREVIOUS PRESERVED: 0