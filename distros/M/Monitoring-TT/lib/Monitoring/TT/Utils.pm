package Monitoring::TT::Utils;

use strict;
use warnings;
use utf8;
use Carp;
use Data::Dumper;

#####################################################################

=head1 NAME

Monitoring::TT::Utils - Util Functions

=head1 DESCRIPTION

Utility functions used within Monitoring::TT

=head2 get_uniq_sorted

    get_uniq_sorted(list)

    returns list sorted and duplicates removed

=cut
sub get_uniq_sorted {
    my($list) = @_;
    my $hash  = list2hash($list);
    my $uniq;
    @{$uniq} = sort keys %{$hash};
    return $uniq;
}

#####################################################################

=head2 list2hash

    list2hash(list)

    returns list transformed to hash

=cut
sub list2hash {
    my($list) = @_;
    my $hash = {};
    for my $i (@{$list}) {
        if(!defined $i) {
            confess("undef:".Dumper($list));
        }
        $hash->{$i} = 1;
    }
    return $hash;
}

#####################################################################

=head2 parse_tags

    parse_tags(str)

    returns parsed tags list

=cut
sub parse_tags {
    my($str) = @_;
    my $tags = {};
    return $tags unless defined $str;
    for my $s (split(/\s*,\s*/mx, $str)) {
        my($key,$val) = split(/\s*=\s*/mx,$s,2);
        $key = lc $key;
        $val = '' unless defined $val;
        if(defined $tags->{$key}) {
            if(ref $tags->{$key} eq 'ARRAY') {
                $tags->{$key} = get_uniq_sorted([@{$tags->{$key}}, $val]);
            } else {
                $tags->{$key} = get_uniq_sorted([$tags->{$key}, $val]);
            }
        } else {
            $tags->{$key} = $val;
        }
    }
    return $tags;
}

#####################################################################

=head2 parse_groups

    parse_groups(str)

    returns parsed groups list

=cut
sub parse_groups {
    my($str) = @_;
    my $groups = [];
    return $groups unless defined $str;
    for my $s (split(/\s*,\s*/mx, $str)) {
        push @{$groups}, $s;
    }
    return $groups;
}


#####################################################################

=head1 AUTHOR

Sven Nierlein, 2013, <sven.nierlein@consol.de>

=cut

1;
