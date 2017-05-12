package Perl::Achievements;
BEGIN {
  $Perl::Achievements::AUTHORITY = 'cpan:YANICK';
}
{
  $Perl::Achievements::VERSION = '0.4.0';
}
# ABSTRACT: whoever die()s with the most badges win


use 5.10.0;

use strict;
use warnings;

no warnings qw/ uninitialized /;

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::ClassAttribute;

use Perl::Achievements::User;

use Module::Pluggable
  search_path => ['Perl::Achievements::Achievement'],
  require     => 1;

use YAML::Any qw/ LoadFile Load Dump /;
use PPI;
use File::HomeDir;
use Path::Class qw/ file dir /;
use Method::Signatures;
use DateTime::Functions;
use Data::Printer;
use Digest::SHA qw/ sha1_hex /;
use File::Touch;

extends 'MooseX::App::Cmd';

with qw/ 
    MooseX::Role::Loggable
    MooseX::ConfigFromFile
/;

with 'MooseX::Role::BuildInstanceOf' => {
    target => 'Perl::Achievements::User',
    prefix => 'user',
};

sub get_config_from_file {
    my ( undef, $file ) = @_;

    return {} if not -f $file; 

    my $config = LoadFile( $file );

    # massage the config a wee bit
    if ( $config->{user} ) {
        $_ = [ %$_ ] for $config->{user_args} = delete $config->{user};
    }

    return $config;
}

my $configfile = ''.file(
    $ENV{PERL_ACHIEVEMENTS_HOME} 
        || dir( File::HomeDir->my_home, '.perl-achievements' ),
    'config'
);

has '+configfile' => (
    default => $configfile,
);

class_has rc => (
    is => 'ro',
    default => sub {
        $ENV{PERL_ACHIEVEMENTS_HOME} 
            || dir( File::HomeDir->my_home, '.perl-achievements' );
    },
    lazy => 1,
);

sub rc_file_path {
    my ( $self, @path ) = @_;

    return file( $self->rc, @path );
}


has _achievements => (
    traits => [ 'Array' ], 
    is      => 'ro',
    builder => '_achievements_builder',
    handles => {
        achievements => 'elements',
        add_achievements => 'push',
    },
);

has ppi => (
    is => 'rw',
);

# will change
has history => (
    is => 'ro',
    default => sub {
        my $file = $_[0]->rc_file_path( 'history' );
        return [] unless -f $file;

        return [ map { Load( $_ ) } split /^---\n/, scalar $file->slurp ];
    },
);

has interactive => (
    is => 'ro',
    isa => 'Bool',
    default => 1,
);

has dry_run => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

method scan ($file) {
    $self->set_ppi( PPI::Document->new( $file ) );

    my $digest = sha1_hex($self->ppi->serialize);
    my $digest_file = $self->rc_file_path( 'scanned', $digest );

    if ( -f $digest_file ) {
        $self->log_debug( "file '$file' already has been scanned" );
        return;
    }

    $_->scan for $self->achievements;

    $digest_file->touch;
}

sub _achievements_builder {
    my $self = shift;

    my @checks;

    push @checks, $_->load_or_new( app => $self ) for $self->plugins;

    return \@checks;
}

method initialize_environment {
    my $dir = $self->rc;

    die "'$dir' already exist, aborting" if -e $dir;

    mkdir $dir;
    mkdir dir( $dir, 'achievements' );
    mkdir dir( $dir, 'scanned' );

    my $config = file( $dir, 'config' )->openw;

    print $config <<'END_CONFIG';
# user: 
#   name: Your Name Here
#   url: http://yoursite.org/

END_CONFIG

}

sub unlock_achievement {
    my ( $self, %info ) = @_;

    $self->log_debug( "achievement unlocked:\n" 
        . p( %info, colored => 0 )
    );

    $self->add_to_history( %info ) unless $self->dry_run;
}

sub add_to_history {
    my $self = shift;
    my %info = @_;
    my $file = $self->rc_file_path( 'history' );
    open my $fh, '>>', $file;
    print {$fh} Dump \%info;
}

after unlock_achievement => sub {
    my( $self, %info ) = @_;

    return unless $self->interactive;

    say 'Congrats! You have unlocked a new achievement!';

    say '*' x 60;
    say '*** ', $info{achievement};
    say '*** level ', $info{level} if $info{level};
    say '';
    say $info{details} if $info{details};
    say '*' x 60;
};

method generate_report( $format ) {
    my $class = 'Perl::Achievements::Report::'. ucfirst $format;

    eval "use $class; 1" 
        or die "could not use format '$format': $@\n";

    my $report = $class->new(
        who => $self->user->name,
        history => $self->history,
    );

    return $report->generate;
}

1;

__END__
=pod

=head1 NAME

Perl::Achievements - whoever die()s with the most badges win

=head1 VERSION

version 0.4.0

=head1 SYNOPSIS

    use Perl::Achievements;

    my $pa = Perl::Achievements->new;

    $pa->scan( $file );

=head1 DESCRIPTION

If you want to use C<perl-achievement>, look 
at L<perlachievements>.

If you want to implement a new achievement,
look at L<Perl::Achievements::Achievement>.

WARNING: C<Perl::Achievements> is young, rough,
and subject to change. You've been warned.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

