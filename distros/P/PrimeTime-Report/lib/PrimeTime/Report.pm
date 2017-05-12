package PrimeTime::Report;

use 5.008005;
use strict;
use warnings;

use Yorkit;
use Text::Table;
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PrimeTime::Report ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

PrimeTime::Report - Parser for PrimeTime report.

=head1 SYNOPSIS

  use PrimeTime::Report;
  my $pt = new PrimeTime::Report;

  my $file = shift;
  $pt->read_file($file);

  $pt->print_summary();

  $pt->print_path(5);

=head1 DESCRIPTION

PrimeTime::Report help you extract useful information from PrimeTime report.

=cut

=head1 BASIC FUNTIONS

=cut
# new
# {{{

=head2 new

To new a PrimeTime::Report object.

=cut
sub new {
  my $self=shift;
  my $class=ref($self) || $self;
  my %h;
  return bless {%h}, $class;
}
# }}}
# read_file
# {{{

=head2 read_file

Read and parse the PrimeTime report.

 $pt->read_file($file);

=cut
sub read_file {
  my $self=shift;
  my $infile=shift;

  open FIN, "<$infile" or die "$!";
  undef $/;
  my $file = <FIN>;
  $/='\n';
  close FIN;

  my @path = $file =~ m/(Startpoint.*?slack.*?)$/gsm;
  my $count = 0;
  my $startpoint;
  my $endpoint;
  my $path_group;
  my $path_type;
  my $uncertainty;
  my $slack;
  my $clock_domain;
  my @part;
  my $clock_source_rise_time;
  my $clock_hit_source_FF;
  my $clock_hit_capture_FF;
  my $clock_capture_rise_time;
  my $clock_period;
  my $clock_latency_source;
  my $clock_latency_capture;
  my $skew;
  my @part_source;
  my $clock_path_capture;

  foreach my $eachpath (@path){
    $startpoint   = "N/A" if(!(($startpoint) = $eachpath =~ m/Startpoint: (.*?)$/m));
    $endpoint     = "N/A" if(!(($endpoint) = $eachpath =~ m/Endpoint: (.*?)$/m));
    $path_group   = "N/A" if(!(($path_group) = $eachpath =~ m/Path Group: (.*?)$/m));
    $path_type    = "N/A" if(!(($path_type) = $eachpath =~ m/Path Type: (.*?)$/m));
    $uncertainty  = "N/A" if(!(($uncertainty) = $eachpath =~ m/inter-clock uncertainty[ ]+(\S*?) /m));
    $slack        = "N/A" if(!(($slack) = $eachpath =~ m/^[ ]+slack \(\w+\)[ ]+(\S*?)$/sm));
    $clock_domain = "N/A" if(!(($clock_domain) = $eachpath =~ m/ clock (\S*?) \(rise edge\)/m));
    @part = split(/^\s*$/sm,$eachpath);
    @part_source = split(m/($startpoint.*)/sm, $part[1]);
    ($clock_path_capture) = $part[2] =~ m/(.*$endpoint.*? [rf])/sm;
    $clock_source_rise_time = "0" if(!(($clock_source_rise_time) = $part[1] =~ m/ clock \S*? \(rise edge\)[ ]+(\S*?) /m));
    $clock_hit_source_FF    = "0" if(!(($clock_hit_source_FF) = $part[1] =~ m/$startpoint.*?(\S*?) [rf]/sm));
    $clock_capture_rise_time= "0" if(!(($clock_capture_rise_time) = $part[2] =~ m/ clock \S*? \(rise edge\)[ ]+(\S*?) /m));
    $clock_period           = $clock_capture_rise_time - $clock_source_rise_time;
    $clock_hit_capture_FF    = "0" if(!(($clock_hit_capture_FF) = $part[2] =~ m/$endpoint.*?(\S*?) [rf]/sm));

    if(!(($clock_latency_source) = $part[1] =~ m/ clock network delay \(\w+\)[ ]+(\S*?) /m)){
      $clock_latency_source = $clock_hit_source_FF - $clock_source_rise_time;
    }
    if(!(($clock_latency_capture) = $part[2] =~ m/ clock network delay \(\w+\)[ ]+(\S*?) /m)){
      $clock_latency_capture = $clock_hit_capture_FF - $clock_capture_rise_time;
    }
    $skew = sprintf("%.4f",$clock_latency_capture - $clock_latency_source);

    $self->{paths}->{$count} = {
      raw=> $eachpath,
      startpoint => $startpoint,
      endpoint => $endpoint,
      path_group => $path_group,
      path_type => $path_type,
      clock_domain => $clock_domain,
      clock_period => $clock_period,
      uncertainty => $uncertainty,
      clock_path_source => $part_source[0],
      clock_path_capture => $clock_path_capture,
      clock_source_rise_time => $clock_source_rise_time,
      clock_hit_source_FF => $clock_hit_source_FF,
      clock_latency_source => $clock_latency_source,
      clock_latency_capture => $clock_latency_capture,
      skew => $skew,
      slack => $slack,
      start_part => $part_source[1],
      end_part=>$part[2],
    };
    $count++;
  }
  $self->{size}=$count+1;
}
# }}}
# print_summary
# {{{

=head2 print_summary

 available input option: startpoint, endpoint, path_group, path_type, clock_domain, clock_period, uncertainty
                         clock_latency_capture, clock_latency_source
 $pt->print_summary("slack", "startpoint", "endpoint");

=cut
sub print_summary {
  my $self=shift;
  my @column=@_;
  my $size = $self->{size} - 1;
  my $i;
  my $tb = Text::Table->new();
  my @a=();

  for($i=0;$i<$size;$i=$i+1){
    push @a, $i+1;
    foreach (@column){
      push @a, $self->{paths}->{$i}->{$_};
    }
    $tb->load([@a]);
    @a=();
  }
  print $tb;
}
# }}}
# print_path
# {{{

=head2 print_path

 Input1: Path number
 Input2: Path length you want to show. Default is 110.
 $pt->print_path(3);

=cut
sub print_path {
  my $self=shift;
  my $number = shift;
  my $length = shift;
  $length = 110 if (!defined $length);
  my $tb = Text::Table->new();
  my $path_no = $number-1;
  my $start_part = $self->{paths}->{$path_no}->{start_part};
  my @p_ref = $self->path_extract($start_part, $length, "splited");

  for (@p_ref) {
    $tb->load([@$_]);
  }

  print sprintf("%23s %s", "Path Number: ", $number),"\n";
  print sprintf("%23s %s", "Path Type: ",$self->{paths}->{$path_no}->{path_type}),"\n";
  print sprintf("%23s %s", "Path Group: ",$self->{paths}->{$path_no}->{path_group}),"\n";
  print sprintf("%23s %s", "Uncertanty: ",$self->{paths}->{$path_no}->{uncertainty}),"\n";
  print sprintf("%23s %s", "Clock Source Latency: ",$self->{paths}->{$path_no}->{clock_latency_source}),"\n";
  print sprintf("%23s %s", "Clock Capture Latency: ",$self->{paths}->{$path_no}->{clock_latency_capture}),"\n";
  print sprintf("%23s %s", "Skew: ",$self->{paths}->{$path_no}->{skew}),"\n";
  print sprintf("%23s %s", "Clock Period: ",$self->{paths}->{$path_no}->{clock_period}),"\n";
  print sprintf("%23s %s", "Slack: ",$self->{paths}->{$path_no}->{slack}),"\n";
  if($self->{paths}->{$path_no}->{path_type} eq "max") {
    my $speed = 1/($self->{paths}->{$path_no}->{clock_period} - $self->{paths}->{$path_no}->{slack})*1000;
    print sprintf("%23s %d", "Speed: ",$speed),"\n";
  }
  print $tb;
}
# }}}
# print_path_raw
# {{{

=head2 print_path_raw

Print the specified path in orignal format.

 Input: path number
 Ex:
 $pt->print_path_raw(3);

=cut
sub print_path_raw {
  my $self=shift;
  my $number = shift;
  my $path_no = $number-1;
  print $self->{paths}->{$path_no}->{raw};
}
# }}}
# path_extract
# {{{

=head2 path_extract

Split each line by space and create a 2D array.

 Input1: text which contants path information
 Input2: the path length you want to show
 Ex:
 $pt->path_extract($path, $length);

=cut
sub path_extract {
  my $self=shift;
  my $path = shift;
  my $length = shift;
  #my $splited = shift;
  my @a;
  my @path_line;

  my $p;
  #if($splited eq "splited"){
    while($path =~ m'(^\s+[\-0-9a-zA-Z./_]+/[\-0-9a-zA-Z./_]+.*? [fr])'gsm){
      $p = $1;
      $p =~ s/\n//;
  #    if($p !~ /0\.0000/){
        push @a, $p;
  #    }
    };
  #}else{
  #  @path_line = split(/\n/,$path);
  #  @a = grep m'^\s+[\-0-9a-zA-Z./_]+/[\-0-9a-zA-Z./_]+', @path_line;
  #}

  # remove * in each path
  for (@a) {s/\*//};

  
  my @path_2D;
  @path_2D = map {[split]} @a;


  for my $aref (@path_2D){
    @$aref[0] = substr(@$aref[0], -$length);
  }

  return @path_2D;
}
# }}}
# clk_path
# {{{

=head2 clk_path

 Input1: text which contants clock path information
 Input2: "source" or "capture"
 Ex:
 $pt->clk_path($clock_path, "source");

=cut
sub clk_path {
  my $self=shift;
  my $path_no = shift;
  my $type = shift;
  $path_no--;

  my $tb = Text::Table->new();

  my @p_ref;
  if($type eq "source"){
    @p_ref = $self->path_extract($self->{paths}->{$path_no}->{clock_path_source}, 110);
  }
  elsif($type eq "capture"){
    @p_ref = $self->path_extract($self->{paths}->{$path_no}->{clock_path_capture}, 110);
  }

  for (@p_ref) {
    $tb->load([@$_]);
  }

  print $tb;
}
# }}}

=head1 Tools

Three tools provided as gedgets and also examples using PrimeTime::Report.

=head2 pr-summary.pl

=head2 pr-path.pl

=head2 pr-clk_path.pl

=head1 AUTHOR

yorkwu, E<lt>yorkwuo@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by yorkwu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
1;
# vim:fdm=marker
