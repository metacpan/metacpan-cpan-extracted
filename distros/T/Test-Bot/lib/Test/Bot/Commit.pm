# This class represents a single commit

package Test::Bot::Commit;

use Any::Moose;
use DateTime;

# e.g. "Mischa Spiegelmock <revmischa@cpan.org>"
has 'author' => (
    is => 'rw',
    isa => 'Str',
);

# e.g. git sha1
has 'id' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

# commit message
has 'message' => (
    is => 'rw',
    isa => 'Str',
);

# list of modified files in this commit
has 'files' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
);

# commit datetime
has 'timestamp' => (
    is => 'rw',
    isa => 'DateTime',
);

has 'test_success' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

has 'test_output' => (
    is => 'rw',
    isa => 'Str',
    default => 'No test output',
);


has 'passed' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);

has 'failed' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);

has 'exited' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);

# timestamp, formatted for humans
sub display_date {
    my ($self) = @_;

    my $dt = $self->timestamp or return '';

    my $day = $dt->strftime("%m/%d/%y");
    my $today = DateTime->today;

    my $pretty;
    if ($day eq DateTime->today->subtract(days => 1)->strftime("%m/%d/%y")) {
        $pretty = 'yesterday';
    } else {
        $pretty = $dt->strftime("%F %r");
    }

    return $pretty;
}

__PACKAGE__->meta->make_immutable;
