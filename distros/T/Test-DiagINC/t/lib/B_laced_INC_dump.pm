my %inc_copy = %INC;
delete $inc_copy{ +__FILE__ };

if ( keys %inc_copy ) {
    print STDERR "%INC can not be populated when loading @{[ __FILE__ ]}\n";
    exit 255;
}

require B;

print join "\0", sort grep { $_ ne __FILE__ } keys %INC;

exit 0;
