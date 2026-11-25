package CommentedChild;

# A subclass of CommentedParent, from another tree, which documents its override with a blurb.

use 5.036;
use warnings FATAL => q{all};

use parent 'CommentedParent';

# Write the release down.
# @param   self  CommentedChild  the plugin
# @returns nothing
# @example $child->after_release;
sub after_release {
    my ($self) = @_;
    $self->{released} = 1;
    return;
}

1;
