package DeadBeef::Site;

use strict;
use warnings;

use base qw(Spike);

use HTTP::Status qw(:constants);

sub stash { shift->{stash} ||= {} }

sub startup {
    my $self = shift;

    $self->route
        ->prepare(sub {
            my ($req, $res, $error) = @_;
            # place code here
        })
        ->finalize(sub {
            my ($req, $res, $error) = @_;
            # place code here
        })
        ->error(HTTP_NOT_FOUND() => sub {
            my ($req, $res, $error) = @_;
            # place code here
        })
        ->error(HTTP_INTERNAL_SERVER_ERROR() => sub {
            my ($req, $res, $error) = @_;
            # place code here
        })
        ->get('/' => sub {
            my ($req, $res, $error) = @_;
            # place code here
        })
        ->post('/' => sub {
            my ($req, $res, $error) = @_;
            # place code here
        });
}

sub clean {
    my $self = shift;
    delete $self->{$_} for qw(stash);
    $self->SUPER::clean;
}

1;
