#
#   WE ARE DOING %INC EXAMS IN THIS TEST
# No Test::More loaded, all TAP output by hand
#

BEGIN {
    if ( keys %INC ) {
        print "1..0 # SKIP Your %INC is already populated, perhaps PERL5OPTS is set?\n";
        exit 0;
    }
}

# madness explanation at the top of Test::DiagInc
BEGIN {
    if ( $ENV{RELEASE_TESTING} ) {
        require warnings && warnings->import;
        require strict   && strict->import;
    }

    @::initial_INC = keys %INC;

    unless ( $] < 5.008 ) {
        @::B_inc = split /\0/, `$^X -Mt::lib::B_laced_INC_dump`;
    }
}

my $nongreat_success;

END {
    cmp_inc_contents( @::initial_INC, 'Test/DiagINC.pm', @::B_inc );
    print "1..4\n";
    $? ||= ( $nongreat_success || 0 );
}

sub cmp_inc_contents {
    my %current_inc = %INC;

    my ( $seen, @leftover_keys );
    for (@_) {
        next if $seen->{$_}++;
        if ( exists $current_inc{$_} ) {
            delete $current_inc{$_};
        }
        else {
            push @leftover_keys, $_;
        }
    }

    my $fail = 0;
    if ( my @mods = sort keys %current_inc ) {
        $_ =~ s|/|::|g  for @mods;
        $_ =~ s|\.pm$|| for @mods;
        print "not ok - the following modules were unexpectedly found in %INC: @mods\n";
        $fail++;
    }
    else {
        print "ok - %INC does not contain anything extra\n";
    }

    if (@leftover_keys) {
        $_ =~ s|/|::|g  for @leftover_keys;
        $_ =~ s|\.pm$|| for @leftover_keys;
        print
          "not ok - the following modules were expected but not found in %INC: @leftover_keys\n";
        $fail++;
    }
    else {
        print "ok - %INC contents as expected\n";
    }

    $nongreat_success += $fail;
}

use Test::DiagINC;

BEGIN { cmp_inc_contents( @::initial_INC, 'Test/DiagINC.pm' ) }
