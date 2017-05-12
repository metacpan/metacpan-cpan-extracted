package Parse::Crontab::Entry;
use strict;
use warnings;
use utf8;

use Mouse;

has line => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has line_number => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has is_error => (
    is      => 'rw',
    isa     => 'Bool',
    default => undef,
);

has errors => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub {[]},
    auto_deref => 1,
);

has warnings => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub {[]},
    auto_deref => 1,
);

no Mouse;

sub set_error {
    my ($self, $error_msg) = @_;

    push @{$self->errors}, $error_msg;
    $self->is_error(1);
}

sub error_message {
    my $self = shift;

    sprintf 'line: %d: %s | %s', $self->line_number, $self->line, join(' ', $self->errors);
}

sub set_warning {
    my ($self, $warn_msg) = @_;

    push @{$self->warnings}, $warn_msg;
}

sub warning_message {
    my $self = shift;

    sprintf 'line: %d: %s | %s', $self->line_number, $self->line, join(' ', $self->warnings);
}

sub has_warnings {
    my $self = shift;

    scalar @{$self->warnings} ? 1 : ();
}

__PACKAGE__->meta->make_immutable;
