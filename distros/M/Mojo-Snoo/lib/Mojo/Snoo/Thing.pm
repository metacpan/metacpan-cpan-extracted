package Mojo::Snoo::Thing;
use Moo;

use Carp qw(croak);
use Mojo::Snoo::Comment;
use Mojo::Snoo::Link;
use Mojo::Snoo::Subreddit;

my %REDDIT_TYPE_MAP = (
    t1 => 'Mojo::Snoo::Comment',
    t2 => undef,
    t3 => 'Mojo::Snoo::Link',
    t4 => undef,
    t5 => 'Mojo::Snoo::Subreddit',
    t6 => undef,
    t7 => undef,
    t8 => undef,
);

sub get_instance {
    shift if $_[0] eq __PACKAGE__; # allow calling as class method or object method
    my ($type_prefix, $data) = split(/_/, shift);
    croak "Missing type prefix before '$data' expected: " . join(', ', keys %REDDIT_TYPE_MAP) 
        unless $type_prefix;

    my $reddit_data_object = $REDDIT_TYPE_MAP{$type_prefix};
    croak "Unsupported type prefix '$type_prefix'"
        unless $reddit_data_object;

    return $reddit_data_object->new($data);
}

1;
