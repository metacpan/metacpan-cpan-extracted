package Parse::Crontab::Entry::Env;
use 5.008_001;
use strict;
use warnings;
use Mouse;
extends 'Parse::Crontab::Entry';

has _pair => (
    is  => 'ro',
    isa => 'ArrayRef',
    default => sub {
        my $self = shift;
        [split /=/, $self->line, 2];
    },
    auto_deref => 1,
);

has key => (
    is  => 'ro',
    isa => 'Str',
    default => sub {
        my $self = shift;
        $self->_handle_kv($self->_pair->[0]);
    }
);

has value => (
    is  => 'ro',
    isa => 'Str',
    default => sub {
        my $self = shift;
        $self->_handle_kv($self->_pair->[1]);
    }
);

no Mouse;

sub _handle_kv {
    my ($self, $str) = @_;
    my $org_str = $str;

    $str =~ s/^\s+//;
    $str =~ s/\s+$//;

    if (my ($quote) = $str =~ /^(['"])/) {
        $str =~ s/^$quote(.*)$quote/$1/;

        if ($str =~ /$quote/) {
            $self->set_error("value: $org_str is not valid.");
            return '';
        }
    }
    $str;
}

__PACKAGE__->meta->make_immutable;
