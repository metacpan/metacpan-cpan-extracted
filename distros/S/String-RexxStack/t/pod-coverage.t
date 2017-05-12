use Test::More  qw(no_plan);
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for POD coverage" if $@;

#all_pod_coverage_ok();
my $trustme = { trustme => [ qr/^init$/  , qr/^FETCH$/, qr/^SPLICE$/ ]  };
pod_coverage_ok( 'String::TieStack' , $trustme);


$trustme = { trustme => [ qr/^Push$/  , qr/^qstack$/, qr/^total_bytes$/ ]  };
pod_coverage_ok( 'String::RexxStack::Named', $trustme );
