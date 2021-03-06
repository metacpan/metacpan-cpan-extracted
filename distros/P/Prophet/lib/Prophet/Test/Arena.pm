package Prophet::Test::Arena;
{
  $Prophet::Test::Arena::VERSION = '0.751';
}
use Any::Moose;

has chickens => (
    is         => 'rw',
    isa        => 'ArrayRef',
    default    => sub { [] },
    auto_deref => 1,
);

has record_callback => (
    is  => 'rw',
    isa => 'CodeRef',
);

has history => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

sub add_history {
    my $self = shift;
    push @{ $self->history }, @_;
}

use Prophet::Test::Participant;
use Prophet::Test;

sub setup {
    my $self  = shift;
    my $count = shift;
    my @names =
      ref $count ? @$count : ( map { "person" . $_ } ( 1 .. $count ) );

    my @chickens =
      map { Prophet::Test::Participant->new( { name => $_, arena => $self } ) }
      @names;

    for my $c (@chickens) {

        as_user(
            $c->name => sub {
                my $p = Prophet::CLI->new();
                diag( $c => $p->handle->display_name_for_replica );
            }
        );
    }

    $self->chickens( \@chickens );
}

sub run_from_yaml {
    my $self = shift;
    my @c    = caller(0);
    no strict 'refs';
    my $fh = *{ $c[0] . '::DATA' };

    return $self->run_from_yamlfile(@ARGV) unless fileno($fh);

    local $/;
    eval { require YAML::Syck; }
      || Test::More::plan( skip_all => 'YAML::Syck required for these tests' );
    $self->run_from_data( YAML::Syck::Load(<$fh>) );

}

sub run_from_yamlfile {
    my ( $self, $file ) = @_;
    eval { require YAML::Syck; }
      || Test::More::plan( skip_all => 'YAML::Syck required for these tests' );
    $self->run_from_data( YAML::Syck::LoadFile($file) );
}

sub run_from_data {
    my ( $self, $data ) = @_;

    Test::More::plan(
        tests => scalar @{ $data->{recipe} } + scalar @{ $data->{chickens} } );
    my $arena = Prophet::Test::Arena->new(
        {
            record_callback => sub {
                my ( $name, $action, $args ) = @_;
                return;
            },
        }
    );
    $arena->setup( $data->{chickens} );

    my $record_map;

    for ( @{ $data->{recipe} } ) {
        my ( $name, $action, $args ) = @$_;
        my ($chicken) = grep { $_->name eq $name } $arena->chickens;
        if ( $args->{record} ) {
            $args->{record} = $record_map->{ $args->{record} };
        }
        my $next_result = $args->{result};

        as_user(
            $chicken->name,
            sub {
                @_ = ( $chicken, $action, $args );
                goto $chicken->can('take_one_step');
            }
        );

        if ( $args->{result} ) {
            $record_map->{$next_result} = $args->{result};
        }
    }

    #    my $third = $arena->dump_state;
    #    $arena->sync_all_pairs;
    #    my $fourth = $arena->dump_state;
    #    is_deeply($third,$fourth);

}

my $TB = Test::Builder->new();

sub step {
    my $self         = shift;
    my $step_name    = shift || undef;
    my $step_display = defined($step_name) ? $step_name : "(undef)";

    for my $chicken ( $self->chickens ) {

        diag( " as " . $chicken->name . ": $step_display" );

        # walk the arena, noting the type of each value
        as_user( $chicken->name, sub { $chicken->take_one_step($step_name) } );
        die "We failed some tests; aborting" if grep { !$_ } $TB->summary;

    }

    # for x rounds, have each participant execute a random action
}

sub dump_state {
    my $self = shift;
    my %state;
    for my $chicken ( $self->chickens ) {
        $state{ $chicken->name } =
          as_user( $chicken->name, sub { $chicken->dump_state } );
    }
    return \%state;
}

use List::Util qw/shuffle/;

sub sync_all_pairs {
    my $self = shift;

    diag("now syncing all pairs");

    my @chickens_a = shuffle $self->chickens;
    my @chickens_b = shuffle $self->chickens;

    for my $a (@chickens_a) {
        for my $b (@chickens_b) {
            next if $a->name eq $b->name;
            diag( $a->name, $b->name );
            as_user( $a->name,
                sub { $a->sync_from_peer( { from => $b->name } ) } );
            die if ( grep { !$_ } $TB->summary );
        }

    }
    return 1;
}

sub record {
    my ( $self, $name, $action, $args ) = @_;
    my $stored = {%$args};
    if ( my $record = $stored->{record} ) {
        $stored->{record} = $self->{record_map}{$record};
    } elsif ( my $result = $stored->{result} ) {
        $stored->{result} = $self->{record_map}{$result} =
          ++$self->{record_cnt};
    }
    return $self->record_callback->( $name, $action, $args )
      if $self->record_callback;

    # XXX: move to some kind of recorder class and make use of callback
    $self->add_history( [ $name, $action, $stored ] );
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::Test::Arena

=head1 VERSION

version 0.751

=head1 AUTHORS

=over 4

=item *

Jesse Vincent <jesse@bestpractical.com>

=item *

Chia-Liang Kao <clkao@bestpractical.com>

=item *

Christine Spang <christine@spang.cc>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Best Practical Solutions.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Prophet>.

=head1 CONTRIBUTORS

=over 4

=item *

Alex Vandiver <alexmv@bestpractical.com>

=item *

Casey West <casey@geeknest.com>

=item *

Cyril Brulebois <kibi@debian.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Jonas Smedegaard <dr@jones.dk>

=item *

Kevin Falcone <falcone@bestpractical.com>

=item *

Lance Wicks <lw@judocoach.com>

=item *

Nelson Elhage <nelhage@mit.edu>

=item *

Pedro Melo <melo@simplicidade.org>

=item *

Rob Hoelz <rob@hoelz.ro>

=item *

Ruslan Zakirov <ruz@bestpractical.com>

=item *

Shawn M Moore <sartak@bestpractical.com>

=item *

Simon Wistow <simon@thegestalt.org>

=item *

Stephane Alnet <stephane@shimaore.net>

=item *

Unknown user <nobody@localhost>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=item *

franck cuny <franck@lumberjaph.net>

=item *

robertkrimen <robertkrimen@gmail.com>

=item *

sunnavy <sunnavy@bestpractical.com>

=back

=cut
