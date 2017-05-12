sub run_tests {
    my $tests = shift;
    
    while ( @$tests ) {
        my $module = shift @$tests;
        next if @ARGV && !grep /$module/, @ARGV;
    
        my $subsort  = $module =~ /Serial/   ? sub { $a <=> $b }
                     :                         sub { $a cmp $b }
                     ;
    
        my @data     = @{ shift @$tests };
    
        # Execute custom code if it's there
        my $code = shift @data;
        $code->() if $code;
    
        # Range::Object::Interval specific data
        my $interval;
        $interval = shift @data if $module =~ /Interval/;
    
        # Fetch invalid input data
        my @invalid_input = @{ shift @data };
    
        #
        # Invalid input test
        #
        SKIP: {
            skip "No invalid input tests for Range::Object::String", 4
                if $module =~ /Range::Object::String/;
    
            my $i = 0;
            for ( @invalid_input ) {
                $i++;
                my $range = $module =~ /Interval/
                          ? eval { $module->new($interval, $_) }
                          : eval { $module->new($_) }
                          ;
    
                fail "Didn't die on $module invalid input $i" unless $@;
                like $@, qr/Invalid input/, "$module invalid input $i";
            }
        }
    
        # Declare variables for consistency
        my ($range1,               $range2              );
        my (@range1_not_in_output, @empty               );
        my (@range1_list_output,   @range2_list_output  );
        my ($range1_string_output, $range2_string_output);
        my (@range1_short_output,  @range2_short_output );
        my ($range1_short_string,  $range2_short_string );
        my ($range1_stringify,     $range2_stringify    );
        my ($range1_size,          $range2_size         );
    
        for my $test ( qw( new add remove ) ) {
            # Fetch test data
            my @input         = @{ shift @data };
            my @in_list       = @{ shift @data };
            my @not_in_input  = sort $subsort @{ shift @data };
            my @not_in_output = sort $subsort @{ shift @data };
            my @range_output  = @{ shift @data };  # List   range() output
            my $range_output  =    shift @data  ;  # Scalar range() output
            my @short_output  = @{ shift @data };  # List   collapsed() output
            my $short_output  =    shift @data  ;  # Scalar collapsed() output
            my $size          =    shift @data  ;
    
            #
            # Test input
            #
            if ( $test eq 'new' ) {
                $range1 = $module =~ /Interval/
                        ? eval { $module->new($interval, @input) }
                        : eval { $module->new(@input) }
                        ;
    
                is     $@, '',          "$module $test eval $@";
                ok     defined $range1, "$module object created";
                isa_ok $range1,         $module;
            }
            else {
                eval { $range1->$test(@input) };
    
                is     $@, '', "$module $test eval $@";
            };
    
            #
            # scalar in() checks
            #
            ok $range1->in($_), "scalar $module->in($_) after $test()"
                for @in_list;
    
            #
            # list in() checks
            #
            @empty = $range1->in(@in_list);        # Should be empty
    
            is  scalar @empty, 0,  "list $module->in() after $test() no items";
            is_deeply \@empty, [], "list $module->in() after $test()    items";
    
            #
            # scalar not-in() checks
            #
            ok !$range1->in($_), "scalar not $module->in($_) after $test()"
                for @not_in_input;
    
            #
            # list not-in() checks
            #
            @range1_not_in_output = $range1->in(@not_in_input);
    
            is  scalar @range1_not_in_output, scalar @not_in_input,
                "list not $module->in() after $test() # items";
            is_deeply \@range1_not_in_output, \@not_in_input,
                "list not $module->in() after $test()   items";
    
            #
            # range() checks, list context
            #
            @range1_list_output = sort $subsort $range1->range();
            is_deeply \@range1_list_output, \@range_output,
                "list $module->range() after $test()";
    
            #
            # range() test, scalar context
            #
            $range1_string_output = $range1->range();
    
            is $range1_string_output, $range_output,
                "scalar $module->range() after $test()";
    
            #
            # collapse() test, list context
            #
            @range1_short_output = $range1->collapsed();
    
            is_deeply \@range1_short_output, \@short_output,
                "list $module->collapsed() after $test()";
    
            #
            # collapse() and stringify() tests, scalar context
            #
            $range1_short_string  = $range1->collapsed();
            $range1_stringify     = "$range1";
    
            is $range1_short_string, $short_output,
                "scalar $module->collapsed() after $test()";
            is $range1_short_string, $range1_stringify,
                "scalar $module->stringify() after $test()";
    
            #
            # size() tests
            #
            $range1_size = $range1->size();
            is $range1_size, $size, "$module->size() after $test()";
    
            #
            # trying to eat our own dog food
            #
            $range2 = $module =~ /Interval/
                    ? eval { $module->new($interval, $range1_string_output) }
                    : eval { $module->new($range1_string_output) }
                    ;
            is $@, '', "dog food $module->new() after $test() eval $@";
     
            @range2_list_output   = $range2->range();
            $range2_string_output = $range2->range();
            @range2_short_output  = $range2->collapsed();
            $range2_short_string  = $range2->collapsed();
            $range2_stringify     = "$range2";
            $range2_size          = $range2->size();
    
            is_deeply \@range2_list_output, \@range_output,
                "dog food $module->range() after $test() list   output";
            is $range2_string_output, $range_output,
                "dog food $module->range() after $test() string output";
            is_deeply \@range2_short_output, \@short_output,
                "dog food $module->collapsed() after $test() list output";
            is $range2_short_string, $short_output,
                "dog food $module->collapsed() after $test() string output";
            is $range2_stringify, $range2_short_string,
                "dog food $module->stringify_collapsed() after $test()";
            is $range2_size, $size,
                "dog food $module->size() after $test()";
    
            if ( $module eq 'Range::Object::Interval' ) {
                my @military_range = $range1->military();
                my @expected_mil   = @{ shift @data };
    
                is_deeply \@military_range, \@expected_mil,
                    "$module military() after $test() list context";
    
                my $military_str   = $range1->military();
                my $expected_str   = shift @data;
    
                is $military_str, $expected_str,
                    "$module military() after $test() scalar context";
            };
        };
    };
}

1;
