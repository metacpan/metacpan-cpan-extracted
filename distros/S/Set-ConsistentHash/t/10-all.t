#!/usr/bin/perl

use Test::More tests => 1;

use Set::ConsistentHash;
use Digest::SHA1 qw(sha1);
use Data::Dumper;

my $set = Set::ConsistentHash->new;
$set->modify_targets(
                     A => 1,
                     B => 1,
                     C => 2,
                     );

my $set2 = Set::ConsistentHash->new;
$set2->modify_targets(
                      A => 1,
                      B => 1,
                      C => 1,
                      );


print Dumper($set->t_bucket_counts);
print Dumper($set2->t_bucket_counts);


if (1) {
    my %matched;
    my $total_trials = 100_000;
    for my $n (1..$total_trials) {
        my $rand = unpack("N", sha1("trial$n"));
        my $server = $set->target_of_point($rand);
        #print "matched $rand = $server\n";
        $matched{$server}++;
    }

    foreach my $s ($set->targets) {
        printf("$s: expected=%0.02f%%  actual=%0.02f%%\n", #  space=%0.02f%%\n",
               $set->percent_weight($s),
               100 * $matched{$s} / $total_trials,
               #($space{$s} / 2**32) * 100,
               );
    }
}

if (1) {
    my $total_trials = 100_000;
    my %tran;
    for my $n (1..$total_trials) {
        my $rand = unpack("N", sha1("trial$n"));
        #my $s1 = $set->target_of_point($rand);
        #my $s2 = $set2->target_of_point($rand);

        my $s1 = $set->t_target_of_bucket($rand);
        my $s2 = $set2->t_target_of_bucket($rand);
        $tran{"$s1-$s2"}++;
        $tran{"$s1-"}++;
        $tran{"-$s2"}++;
    }

    print Dumper(\%tran);
}

pass("dummy test");


package Set::ConsistentHash;
# mix-ins....

# returns hashref of $target -> $number of occurences in 1024 buckets
sub t_bucket_counts {
    my $self = shift;
    my $ct = {};
    foreach my $t (@{ $self->buckets }) {
        $ct->{$t}++;
    }
    return $ct;
}

# given an integer, returns $target (after modding on 1024 buckets)
sub t_target_of_bucket {
    my ($self, $bucketpos) = @_;
    return ($self->{buckets} || $self->buckets)->[$bucketpos % 1024];
}
