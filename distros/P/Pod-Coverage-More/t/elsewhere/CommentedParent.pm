package CommentedParent;

# A parent class from outside the tree of its child, as an installed distribution is, which nothing wove with Blurbs:
# the comment above its sub is no blurb, and its POD does not document the sub.

use 5.036;
use warnings FATAL => q{all};

=head1 NAME

CommentedParent - a parent class whose subs have comments and no POD

=cut

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

# The release goes into the history, so record it.
sub after_release {
    my ($self) = @_;
    return;
}

1;
