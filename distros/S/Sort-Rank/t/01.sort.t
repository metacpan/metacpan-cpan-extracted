use Test::More tests => 6;

BEGIN {
    use_ok('Sort::Rank', qw(rank_sort rank_group));
}

my @simple = (
    {   score   => 80,  name    => 'Andy'       },
    {   score   => 70,  name    => 'Chrissie'   },
    {   score   => 90,  name    => 'Alex'       },
    {   score   => 90,  name    => 'Rosie'      },
    {   score   => 80,  name    => 'Therese'    },
    {   score   => 10,  name    => 'Mac'        },
    {   score   => 10,  name    => 'Horton'     },
);

my $ref = [                                            
    [   1, '=', { 'name' => 'Alex',     'score' => 90   } ],
    [   1, '=', { 'name' => 'Rosie',    'score' => 90   } ],
    [   3, '=', { 'name' => 'Andy',     'score' => 80   } ],
    [   3, '=', { 'name' => 'Therese',  'score' => 80   } ],
    [   5, '',  { 'name' => 'Chrissie', 'score' => 70   } ],
    [   6, '=', { 'name' => 'Mac',      'score' => 10   } ],
    [   6, '=', { 'name' => 'Horton',   'score' => 10   } ]
];

my $got = rank_sort(\@simple);

is_deeply($got, $ref, 'simple rank sort');

srand(1);

my %new_ar = ( );   # New score, records are arrays
my %old_ar = ( );   # Old score, records are arrays
my %new_ha = ( );   # New score, records are hashes
my %old_ha = ( );   # Old score, records are hashes
my @rec_ar = ( );
my @rec_ha = ( );

# Make some test data and a few reference structures
for (1 .. 1000) {
    my $new_score = int(rand(100));
    my $old_score = rand(10) * rand(10);
    my $name      = "Item $_";
    my $ar_rec    = [ $new_score, $old_score, $name ];
    my $ha_rec    = { 
        score       => $new_score, 
        old_score   => $old_score, 
        name        => $name 
    };

    push @{$new_ar{$new_score}}, $ar_rec;
    push @{$old_ar{$old_score}}, $ar_rec;
    push @{$new_ha{$new_score}}, $ha_rec;
    push @{$old_ha{$old_score}}, $ha_rec;
    
    push @rec_ar, $ar_rec;
    push @rec_ha, $ha_rec;
}

$got = rank_group(\@rec_ha);     # Sorted by score
is_deeply($got, make_ref_groups(\%new_ha), 'score field of hash');

$got = rank_group(\@rec_ha, sub {
    my $item = shift;
    return $item->{old_score};
});

is_deeply($got, make_ref_groups(\%old_ha), 'old_score field of hash');

$got = rank_group(\@rec_ar, sub {
    my $item = shift;
    return $item->[0];
});

is_deeply($got, make_ref_groups(\%new_ar), 'score in array');

$got = rank_group(\@rec_ar, sub {
    my $item = shift;
    return $item->[1];
});

is_deeply($got, make_ref_groups(\%old_ar), 'old score in array');

sub make_ref_groups {
    my $hr   = shift;
    my @r    = ( );
    my $rank = 1;
    for (sort { $b <=> $a } keys %$hr) {
        my @els = @{$hr->{$_}};
        push @r, [ $rank, @els ];
        $rank += scalar(@els);
    }
    return \@r;
}
