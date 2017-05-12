use Test2::Bundle::Extended -target => 'Scientist';

# This is a race to see under normal conditions whether the
# control() or the candidate() is run first.
#
# Ideally, they should each win half the time.

my $winner;
my $experiment = $CLASS->new(
    use => sub { $winner ||= 'control'   },
    try => sub { $winner ||= 'candidate' },
);

# Race 1000 times and record each winner.
my %results;
for (1..1000) {
    $experiment->run;
    $results{$winner}++;
    undef $winner;
}

note 'Control called first  :', $results{control};
note 'Candidate called first:', $results{candidate};

ok $results{control} > 450,   '>45% Control code run first';
ok $results{candidate} > 450, '>45% Candidate code run first';

done_testing;
