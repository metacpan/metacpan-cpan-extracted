use Test::Requires {
    'Test::Pod::Coverage' => 1.08,
};
eval {
    require 'Test::Pod::Coverage';  # a bad know-how: to pass Test::Kwalitee
};

all_pod_coverage_ok(
    {
        also_private => [qw(
            BUILDARGS
            BUILD
            DEMOLISH
        )],
    },
);

__END__

=pod

=head1 NAME

pod_coverage.t - testing coverage of a test

=head1 NOTE

Is L<Test::Pod::Coverage|Test::Pod::Coverage> incompatible with
L<Devel::Cover|Devel::Cover> and L<Attribute::Protected|Attribute::Protected> ?

=cut
