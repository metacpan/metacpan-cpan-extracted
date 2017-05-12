package Perl::Achievements::Achievement;
BEGIN {
  $Perl::Achievements::Achievement::AUTHORITY = 'cpan:YANICK';
}
{
  $Perl::Achievements::Achievement::VERSION = '0.4.0';
}
# ABSTRACT: base role for achievements


use strict;
use warnings;

use Moose::Role;

no warnings qw/ uninitialized /;

use MooseX::SemiAffordanceAccessor;

use YAML::Any qw/ LoadFile DumpFile /;
use DateTime::Functions qw/ now /;

with 'MooseX::ConfigFromFile';

requires qw/ scan /;


has 'app' => (
    required => 1,
    is => 'ro',
    handles => [ qw/ ppi log log_debug dry_run / ],
);




has level => (
    traits => [ 'Perl::Achievements::Role::ConfigItem', 'Counter' ],
    isa => 'Num',
    is => 'rw',
    default => 0,
    handles => {
        inc_level => 'inc'
    },
);

sub get_config_from_file {
    my ( undef, $file ) = @_;

    return -f $file ? LoadFile( $file ) : {};
}

sub storage_file {
    my $class = shift;

    # if object, turn to class name
    $class = ref $class if ref $class;

    $class =~ s/^Perl::Achievements::Achievement:://;
    $class =~ s/::/__/g;
    $class .= '.yaml';

    return $class;
}

sub load_or_new {
    my ( $class, %args ) = @_;

    my $file = $args{app}->rc_file_path( 'achievements', $class->storage_file );

    return $class->new_with_config( configfile => $file, %args );
}


sub unlock {
    my ($self, $details ) = @_;

    $self->app->unlock_achievement( 
        achievement => ref($self),
        timestamp => ''.now(),
        ( level => $self->level ) x ( $self->level > 0 ) ,
        ( details => $details ) x !!$details,
    );
}

before unlock => sub {
    my $self = shift;

    $self->set_level(0) unless defined $self->level;
};

before scan => sub {
    my $self = shift;
    $self->log_debug( "scanning for achievement " . ref $self );
};

after scan => sub {
    my $self = shift;

    $self->log_debug( 'storing state of ' . ref $self );

    $self->store( "".$self->app->rc_file_path( 
        'achievements', $self->storage_file ) ) unless $self->dry_run;
};

sub pack {
    my $self = shift;

    my %data;

    for my $attr ( map { $self->meta->get_attribute($_) } 
                       $self->meta->get_attribute_list ) {
        next unless $attr->does('Perl::Achievements::Role::ConfigItem');

        my $name = $attr->name;
        $data{$name} = $self->$name;
    }

    return %data;
}

sub store {
    my $self = shift;

    my %data = $self->pack;
    DumpFile( shift, \%data );
}

1;

__END__
=pod

=head1 NAME

Perl::Achievements::Achievement - base role for achievements

=head1 VERSION

version 0.4.0

=head1 SYNOPSIS

    package Perl::Achievements::Achievement::PerlAchiever;

    use strict;
    use warnings;

    use Moose;
    use MooseX::SemiAffordanceAccessor;

    with 'Perl::Achievements::Achievement';

    has runs => (
        traits => [ qw/ Counter Perl::Achievements::Role::ConfigItem / ],
        isa     => 'Num',
        is      => 'rw',
        default => 0,
        handles => {
            inc_runs => 'inc',
        },
    );

    sub scan {
        my $self = shift;

        $self->inc_runs;

        return unless $self->runs >= 2** $self->level;

        $self->inc_level;

        $self->unlock( 
            sprintf "ran perl-achievements against %d scripts/modules",
                    2 ** ( $self->level - 1 ) 
        );
    }

    1;

=head1 DESCRIPTION

Each type of achievement is a module consuming the
L<Perl::Achievements::Achievement> role.

To be able to preserve counters and states across runs,
all attributes of the class having the L<Perl::Achievements::Role::ConfigItem>
trait will be serialized and saved in a yaml file in the 
C<$PERL_ACHIEVEMENTS_HOME/achievements> directory.

=head1 REQUIRED METHODS

=head2 scan()

C<scan> is the only required method by the role. It is typically invoked
by the main C<scan()> method of the main L<Perl::Achievements> object,
and is expected to inspect the current Perl file (available via C<ppi()>)
and unlock the achievement when the right conditions are met.

=head1 METHODS

=head2 app()

Returns the L<Perl::Achievements> object to which this achievement
object belongs to.

=head2 ppi()

Returns the L<PPI::Document> object corresponding to the Perl script
currently under study.

=head2 log( $message )

Logs the I<$message>.

=head2 log_debug( $message )

Debug-level logging.

=head2 level()

Returns the current achieved level. A level of I<undef> means that the 
achievement has not been reached yet, whereas a level of 0 is used for 
achievements that don't have multiple levels.

=head2 set_level( $level )

Sets the level to I<$level>.

=head2 inc_level( $increment )

Increments the level by the I<$increment>. If the increment
is not given, increment by 1.

=head2 unlock( $details )

Unlocks the achievement. An optional message can be passed, providing
specific on the deed.

If not set manually beforehand, unlocking the achievement would automatically
set the level to 0.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

