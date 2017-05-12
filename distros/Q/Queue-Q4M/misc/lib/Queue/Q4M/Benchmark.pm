# $Id: /mirror/coderepos/lang/perl/Queue-Q4M/trunk/misc/lib/Queue/Q4M/Benchmark.pm 65253 2008-07-08T02:20:49.109770Z daisuke  $

package Queue::Q4M::Benchmark;
use Moose;
use Moose::Util::TypeConstraints;

use Benchmark ();
use DBI;
use Queue::Q4M;

with 'MooseX::Getopt';

has 'dsn' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    trigger => sub { $_[0]->connect_info->[0] = $_[1] }
);

has 'username' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => sub { (getpwuid($>))[0] },
    trigger => sub { $_[0]->connect_info->[1] = $_[1] }
);

has 'password' => (
    is => 'rw',
    isa => 'Str',
    trigger => sub { $_[0]->connect_info->[2] = $_[1] }
);

has '__connect_info' => (
    accessor => 'connect_info',
    is => 'rw',
    isa => 'ArrayRef',
    auto_deref => 1,
    default => sub { +[ undef, undef, undef, { RaiseError => 1 } ] },
);

has '__dbh' => (
    accessor => 'dbh',
    is => 'rw',
    isa => 'Maybe[DBI::db]',
);

around 'dbh' => sub {
    my ($next, $self, @args) = @_;
    my $rv = $next->($self, @args);
    if (! @args) {
        if (! defined $rv || ! $rv->ping) {
            $rv = DBI->connect( $self->connect_info );
            $self->dbh($rv);
        }
    }
    return $rv;
};

role_type 'Queue::Q4M::Benchmark::Plugin';
subtype 'PluginList'
    => as 'ArrayRef[Queue::Q4M::Benchmark::Plugin]';
coerce 'PluginList'
    => from 'ArrayRef'
        => via {
            my @list;
            foreach my $class (@$_) {
                if ($class !~ s/^\+//) {
                    $class = "Queue::Q4M::Benchmark::Plugin::" . ucfirst $class;
                }
                Class::MOP::load_class($class);
                push @list, $class->new;
            }
            \@list;
        }
;

has 'plugins' => (
    is => 'rw',
    isa => 'PluginList',
    auto_deref => 1,
    coerce => 1,
    default => sub { +[] }
);

has '__tasks' => (
    accessor => 'tasks',
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{} }
);

has 'items' => (
    is => 'rw',
    isa => 'Int',
    default => 10_000
);

has 'iterations' => (
    is => 'rw',
    isa => 'Int',
    required => 1,
    default => 1,
);

has 'define' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{} }
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub run {
    my $self = shift;

    my $dbh = DBI->connect( $self->connect_info );

    $self->setup();
    $self->run_tasks();
}

sub setup {
    my $self = shift;

    foreach my $plugin ( $self->plugins ) {
        $plugin->setup( $self );
    }
}

sub add_task {
    my ($self, %args) = @_;

    $self->tasks->{$args{name}} = $args{coderef};
}

sub run_tasks {
    my $self = shift;

    while (my ($name, $coderef) = each %{ $self->tasks }) {
        print ">> executing $name\n";
        $coderef->();
    }
}

my @CHARS = ('a'..'z',0..9, 'A'..'Z');

sub random_string {
    my ($self, $length) = @_;
    join('', map { $CHARS[rand @CHARS] } 1..$length);
}

1;
