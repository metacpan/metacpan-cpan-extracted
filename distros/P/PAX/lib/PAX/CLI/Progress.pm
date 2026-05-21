package PAX::CLI::Progress;

our $VERSION = '0.031';

use strict;
use warnings;

sub new {
    my ( $class, %args ) = @_;
    my $tasks = $args{tasks} || [];
    die 'Progress tasks must be an array reference' if ref($tasks) ne 'ARRAY';
    my @order = map { $_->{id} } @{$tasks};
    my %task_lookup = map {
        my $task = $_;
        my $id   = $task->{id} || die 'Progress task missing id';
        $id => {
            id     => $id,
            label  => $task->{label} || $id,
            status => 'pending',
        };
    } @{$tasks};
    my $stream = $args{stream} || \*STDERR;
    my $self = bless {
        title    => $args{title} || 'pax progress',
        order    => \@order,
        tasks    => \%task_lookup,
        stream   => $stream,
        dynamic  => $args{dynamic} ? 1 : 0,
        color    => $args{color} ? 1 : 0,
        rendered => 0,
    }, $class;
    $self->render;
    return $self;
}

sub callback {
    my ($self) = @_;
    return sub {
        my ($event) = @_;
        $self->update($event);
    };
}

sub update {
    my ( $self, $event ) = @_;
    return 1 if !$event || ref($event) ne 'HASH';
    my $id = $event->{task_id} || return 1;
    my $task = $self->{tasks}{$id} || return 1;
    $task->{status} = $event->{status} if defined $event->{status} && $event->{status} ne '';
    $task->{label}  = $event->{label} if defined $event->{label} && $event->{label} ne '';
    $self->render;
    return 1;
}

sub finish {
    my ($self) = @_;
    return 1 if !$self->{dynamic} || !$self->{rendered};
    my $stream = $self->{stream};
    print {$stream} "\n";
    return 1;
}

sub render {
    my ($self) = @_;
    my $stream = $self->{stream};
    my $board = $self->render_text;
    if ( $self->{dynamic} && $self->{rendered} ) {
        my $line_count = scalar( split /\n/, $board );
        for ( 1 .. $line_count ) {
            print {$stream} "\e[1A\e[2K";
        }
    }
    print {$stream} $board;
    $self->{rendered} = 1;
    return 1;
}

sub render_text {
    my ($self) = @_;
    my @lines = ( $self->{title} );
    for my $id ( @{ $self->{order} } ) {
        my $task = $self->{tasks}{$id} || next;
        my $prefix = $self->_status_prefix( $task->{status} );
        push @lines, sprintf '%s %s', $self->_colorize( $prefix, $task->{status} ), $task->{label};
    }
    return join( "\n", @lines ) . "\n";
}

sub _status_prefix {
    my ( $self, $status ) = @_;
    return '[OK]' if defined $status && $status eq 'done';
    return '->' if defined $status && $status eq 'running';
    return '[X]' if defined $status && $status eq 'failed';
    return '[ ]';
}

sub _colorize {
    my ( $self, $text, $status ) = @_;
    return $text if !$self->{color};
    return "\e[32m$text\e[0m" if defined $status && $status eq 'done';
    return "\e[33m$text\e[0m" if defined $status && $status eq 'running';
    return "\e[31m$text\e[0m" if defined $status && $status eq 'failed';
    return $text;
}

1;

__END__

=head1 NAME

PAX::CLI::Progress - DD-style terminal task board for long-running PAX CLI work

=head1 SYNOPSIS

  my $progress = PAX::CLI::Progress->new(
      title => 'pax build progress',
      tasks => [
          { id => 'compile_code_units', label => 'Compile Perl code units' },
          { id => 'compile_launcher',   label => 'Compile standalone launcher' },
      ],
      stream  => \*STDERR,
      dynamic => 1,
      color   => 1,
  );

  my $callback = $progress->callback;
  $callback->({ task_id => 'compile_code_units', status => 'running' });
  $callback->({ task_id => 'compile_code_units', status => 'done' });
  $progress->finish;

=head1 DESCRIPTION

This module renders the same style of ordered task rundown used by Developer
Dashboard lifecycle and skill-install commands. PAX uses it for long-running
CLI work such as C<pax build> so operators can see phase-level progress on
C<stderr> while structured results stay on C<stdout>.

=head1 METHODS

=head2 new, callback, update, finish, render, render_text

Construct and drive one task board.

=head1 USE

Use this module when a public PAX CLI command takes long enough that operators
need visible phase progress without losing machine-readable command output.

=head1 PURPOSE

This module keeps build-progress rendering separate from command parsing and
build planning so long-running CLI work can report useful progress without
tangling presentation logic into the compiler and packaging code.

=head1 WHAT USES IT

The public C<pax build> flow uses this module for the DD-style progress rundown
shown on C<stderr>.

=cut
