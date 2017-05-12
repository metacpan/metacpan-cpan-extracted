package Silki::Role::Web::CombinedStaticFiles;
{
  $Silki::Role::Web::CombinedStaticFiles::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use autodie;
use DateTime;
use File::Copy qw( move );
use File::Slurp qw( read_file );
use File::Temp qw( tempfile );
use JSAN::ServerSide 0.04;
use List::AllUtils qw( all );
use Path::Class;
use Silki::Config;
use Silki::Util qw( string_is_empty );
use Time::HiRes;

use Moose::Role;

has files => (
    is      => 'ro',
    isa     => 'ArrayRef[Path::Class::File]',
    lazy    => 1,
    builder => '_build_files',
);

has target_file => (
    is      => 'ro',
    isa     => 'Path::Class::File',
    lazy    => 1,
    builder => '_build_target_file',
);

has header => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_build_header',
);

requires qw( _squish );

sub _build_header {
    return q{};
}

sub create_single_file {
    my $self = shift;

    my $target = $self->target_file();

    my $target_mod = -f $target ? $target->stat()->mtime() : 0;

    return
        unless grep { $_->stat()->mtime() >= $target_mod }
            @{ $self->files() };

    my ( $fh, $tempfile ) = tempfile( UNLINK => 0 );

    print {$fh} $self->create_content();

    move( $tempfile => $target )
        or die "Cannot move $tempfile => $target: $!";
}

sub create_content {
    my $self = shift;

    my $now = DateTime->now(
        time_zone => 'local',
    )->strftime('%Y-%m-%d %H:%M:%S.%{nanosecond} %{time_zone_long_name}');

    my $content = "/* Generated at $now */\n\n";

    my $header = $self->header();
    $content .= $header
        unless string_is_empty($header);

    for my $file ( @{ $self->files() } ) {
        $content .= "\n\n/* $file */\n\n";
        $content .= $self->_squish( $self->_process($file) );
    }

    return $content;
}

sub _process {
    my $self = shift;
    my $file = shift;

    return scalar read_file( $file->stringify() );
}

1;

# ABSTRACT: Provides common behavior for combining and minifying JS or CSS

__END__
=pod

=head1 NAME

Silki::Role::Web::CombinedStaticFiles - Provides common behavior for combining and minifying JS or CSS

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

