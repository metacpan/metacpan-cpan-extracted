package SqlBatch::Engine;

# ABSTRACT: Class for engine object

use v5.16;
use strict;
use warnings;

use Carp;
use Getopt::Long qw(GetOptionsFromArray);
use Data::Dumper;
use SqlBatch::Configuration;
use SqlBatch::PlanTagFilter;
use SqlBatch::PlanReader;
use SqlBatch::Plan;

sub new {
    my ($class, @argv)=@_;

    my $configfile    = ""; # No configfile is default
    my $directory     = ".";
    my $datasource;
    my $username;
    my $password;
    my $tags          = "";
    my $from_file;
    my $to_file;
    my $exclude_files = "";
    my $fileextension = "sb";
    my $verbosity     = 1;

    GetOptionsFromArray (
	\@argv,
	"configfile:s"      => \$configfile,
	"directory:s"       => \$directory,
	"datasource:s"      => \$datasource,
	"username:s"        => \$username,
	"password:s"        => \$password,
	"tags:s"            => \$tags,
	"from_file:s"       => \$from_file,
	"to_file:s"         => \$to_file,
	"exclude_files:s"   => \$exclude_files,	    
	"fileextension:s"   => \$fileextension,	    
	"verbosity:i"       => \$verbosity,
# Future features
#	"dryrun"            => \$dryrun,
#	"from_id:s"         => \$from_id,
#	"to_id:s"           => \$to_id,
	) if (scalar(@argv));

    my %overrides;
    $overrides{directory}       = $directory  if defined $directory;
    $overrides{datasource}      = $datasource if defined $datasource;
    $overrides{username}        = $username   if defined $username;
    $overrides{password}        = $password   if defined $password;
    my @tags                    = split /,/,$tags;
    $overrides{tags}            = \@tags      if scalar (@tags);
    $overrides{from_file}       = $from_file  if defined $from_file;
    $overrides{to_file}         = $to_file    if defined $to_file;
    my @exclude_files           = split /,/,$exclude_files;
    $overrides{exclude_files}   = \@exclude_files if scalar (@exclude_files);
    $overrides{fileextension}   = $fileextension if defined $fileextension;
    $overrides{verbosity}       = $verbosity if defined $verbosity;

    if ( $configfile eq '-') {
	if (-e './sb.conf') {
	    $configfile = './sb.conf'
	} 
	elsif (-e "$directory/sb.conf") {
	    $configfile = "$directory/sb.conf";
	}
    }

    my $config = SqlBatch::Configuration->new(
	$configfile,
	%overrides,
	);

    my $self   = {
	config => $config,
    };

    return bless $self, $class;
}

sub config {
    my $self = shift;
    my $new  = shift;
    
    $self->{config} = $new 
	if defined $new;

    return $self->{config};
}

sub plan {
    my $self = shift;
    unless (defined $self->{plan}) {
	$self->{plan} = SqlBatch::Plan->new($self->config());
    }
    return $self->{plan};
}

sub run {
    my $self = shift;

    my $config = $self->config();
    my $dir    = $config->item('directory');
    my $plan   = $self->plan;

    my $filter = SqlBatch::PlanTagFilter->new(@{$config->item('tags') // []});    
    $plan->add_filter($filter);

    my $reader = SqlBatch::PlanReader->new(
	$dir,
	$plan,
	$config,
	);
    $reader->load;
#    say Dumper($plan);
    $plan->run();
}

1;

__END__

=head1 NAME

SqlBatch::Engine

=head1 DESCRIPTION

This class is the engine for running  L<sqlbatch>

=head1 AUTHOR

Sascha Dibbern (sascha at dibbern.info)

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
