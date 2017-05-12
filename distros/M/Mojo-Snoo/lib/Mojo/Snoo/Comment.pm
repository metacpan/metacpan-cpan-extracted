package Mojo::Snoo::Comment;
use Moo;

extends 'Mojo::Snoo::Base';

use constant FIELD => 'id';

has id => (
    is  => 'ro',
    isa => sub {
        die "Comment needs ID!" unless $_[0];
    },
    required => 1
);

has [qw( author body )] => (is => 'ro');

has replies => (
    is     => 'rw',
    coerce => sub {
        my $replies = shift;

        # comments without replies contain " "
        my $children = ref($replies) ? $replies->{data}{children} : [];
        return Mojo::Collection->new(
            map {
                $_->{kind} eq 't1'    # unloaded comments have type 'more'
                  ? Mojo::Snoo::Comment->new(%{$_->{data}})
                  : ()
            } @$children
        );
    },
);

# let the user call the constructor using new($comment) or new(id => $comment)
sub BUILDARGS { shift->SUPER::BUILDARGS(@_ == 1 ? (id => shift) : @_) }

1;

__END__

=head1 NAME

Mojo::Snoo::Comment - Interact with comments via the Reddit API

=head1 SYNOPSIS

=head1 DESCRIPTION
