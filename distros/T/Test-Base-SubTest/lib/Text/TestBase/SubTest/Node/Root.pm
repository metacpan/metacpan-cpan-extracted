package Text::TestBase::SubTest::Node::Root;
use strict;
use warnings;
use Carp qw(croak);
use parent qw(Text::TestBase::SubTest::Node::SubTest);

sub new {
    my ($class, %args) = @_;
    $class->SUPER::new(
        name => $args{name} || 'root',
        depth => 0,
    );
}

sub is_root { 1 }

sub last_subtest {
    my ($self, %args) = @_;
    my $target_depth = $args{depth};

    croak '$self->depth is required'  unless defined $self->depth;
    croak q|args 'depth' is required| unless defined $target_depth;

    my $current_subtest = $self;
    while (1) {
        last if $current_subtest->depth == $target_depth;
        my $subtests = $current_subtest->child_subtests;
        unless (@$subtests) {
            return if $current_subtest->depth < $target_depth;
            last;
        }
        # depth++
        $current_subtest =  $subtests->[-1];
    }
    return $current_subtest;
}

1;
