package Perl::Metrics::Lite::Analysis::File;
use strict;
use warnings;

use Carp qw(cluck confess);
use Perl::Metrics::Lite::Analysis;
use Perl::Metrics::Lite::Analysis::Util;
use Perl::Metrics::Lite::Analysis::DocumentFactory;

our $VERSION = '0.05';

use Module::Pluggable
    require     => 1,
    search_path => 'Perl::Metrics::Lite::Analysis::File::Plugin',
    sub_name    => 'file_plugins';

use Module::Pluggable
    require     => 1,
    search_path => 'Perl::Metrics::Lite::Analysis::Sub::Plugin',
    sub_name    => 'sub_plugins';

# Private instance variables:
my %_PATH       = ();
my %_MAIN_STATS = ();
my %_SUBS       = ();
my %_PACKAGES   = ();
my %_LINES      = ();

sub new {
    my ( $class, %parameters ) = @_;
    my $self = {};
    bless $self, $class;
    $self->_init(%parameters);
    return $self;
}

sub _init {
    my ( $self, %parameters ) = @_;
    $_PATH{$self} = $parameters{'path'};

    my $path = $self->path();

    my $document = Perl::Metrics::Lite::Analysis::DocumentFactory
        ->create_normalized_document($path);
    if ( !defined $document ) {
        cluck "Could not make a PPI document from '$path'";
        return;
    }

    my $packages
        = Perl::Metrics::Lite::Analysis::Util::get_packages($document);

    my @sub_analysis = ();
    my $sub_elements = $document->find('PPI::Statement::Sub');
    @sub_analysis = @{ $self->analyze_subs($sub_elements) };

    $_MAIN_STATS{$self} = $self->analyze_file($document);
    $_SUBS{$self}       = \@sub_analysis;
    $_PACKAGES{$self}   = $packages;
    $_LINES{$self}
        = Perl::Metrics::Lite::Analysis::Util::get_node_length($document);

    return $self;
}

sub all_counts {
    my $self       = shift;
    my $stats_hash = {
        path       => $self->path,
        lines      => $self->lines,
        main_stats => $self->main_stats,
        subs       => $self->subs,
        packages   => $self->packages,
    };
    return $stats_hash;
}

sub analyze_file {
    my ($self, $document) = @_;

    if ( !$document->isa('PPI::Document') ) {
        Carp::confess('Did not supply a PPI::Document');
    }

    my $metrics = $self->measure_file_metrics($document);
    $metrics->{path} = $self->path;
    return $metrics;
}

sub measure_file_metrics {
    my ( $self, $file ) = @_;
    my $metrics = {};
    foreach my $plugin ( $self->file_plugins ) {
        $plugin->init;
        next unless $plugin->can('init');
        next unless $plugin->can('measure');
        my $metric = $plugin->measure( $self, $file );
        my $metric_name = $self->metric_name($plugin);
        $metrics->{$metric_name} = $metric;
    }
    return $metrics;
}

sub metric_name {
    my ( $self, $plugin ) = @_;
    my $metric_name = $plugin;
    $metric_name =~ s/.*::(.*)$/$1/;
    $metric_name = _decamelize($metric_name);
    $metric_name;
}

sub _decamelize {
    my $s = shift;
    $s =~ s{([^a-zA-Z]?)([A-Z]*)([A-Z])([a-z]?)}{
        my $fc = pos($s)==0;
        my ($p0,$p1,$p2,$p3) = ($1,lc$2,lc$3,$4);
        my $t = $p0 || $fc ? $p0 : '_';
        $t .= $p3 ? $p1 ? "${p1}_$p2$p3" : "$p2$p3" : "$p1$p2";
        $t;
    }ge;
    $s;
}

sub path {
    my ($self) = @_;
    return $_PATH{$self};
}

sub main_stats {
    my ($self) = @_;
    return $_MAIN_STATS{$self};
}

sub subs {
    my ($self) = @_;
    return $_SUBS{$self};
}

sub packages {
    my ($self) = @_;
    return $_PACKAGES{$self};
}

sub lines {
    my ($self) = @_;
    return $_LINES{$self};
}

sub analyze_subs {
    my $self       = shift;
    my $found_subs = shift;

    return []
        if (
        !Perl::Metrics::Lite::Analysis::Util::is_ref( $found_subs, 'ARRAY' )
        );

    my @subs = ();
    foreach my $sub ( @{$found_subs} ) {
        my $metrics = $self->measure_sub_metrics($sub);
        $self->add_basic_sub_info( $sub, $metrics );
        push @subs, $metrics;
    }
    return \@subs;
}

sub measure_sub_metrics {
    my ( $self, $sub ) = @_;
    my $metrics = {};
    foreach my $plugin ( $self->sub_plugins ) {
        $plugin->init;
        next unless $plugin->can('init');
        next unless $plugin->can('measure');
        my $metric = $plugin->measure( $self, $sub );
        my $metric_name = $self->metric_name($plugin);
        $metrics->{$metric_name} = $metric;
    }
    return $metrics;
}

sub add_basic_sub_info {
    my ( $self, $sub, $metrics ) = @_;
    $metrics->{path} = $self->path;
    $metrics->{name} = $sub->name;
}

1;

__END__

