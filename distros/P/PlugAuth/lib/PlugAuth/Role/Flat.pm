package PlugAuth::Role::Flat;

use strict;
use warnings;
use 5.010001;
use Log::Log4perl qw( :easy );
use File::stat qw( stat );
use Fcntl qw( :flock );
use Role::Tiny;
use File::Temp ();
use File::Spec;
use File::Touch qw( touch );

# ABSTRACT: private role used by L<FlatAuth|PlugAuth::Plugin::FlatAuth> and L<FlatAuthz|PlugAuth::Plugin::FlatAuthz>.
our $VERSION = '0.35'; # VERSION

my %MTimes;

sub has_changed {
  my $filename = shift;
  -e $filename or LOGDIE "File $filename does not exist";
  my $mtime = stat($filename)->mtime;
  return 0 if $MTimes{$filename} && $MTimes{$filename}==$mtime;
  $MTimes{$filename} = $mtime;
  return 1;
}

sub mark_changed {
  delete $MTimes{$_} for @_;
}

sub read_file { # TODO: cache w/ mtime
  my($class, $filename, %args) = @_;
  $args{nest} ||= 0;
  #
  # _read_file:
  #  x : y
  #  z : q
  # returns ( x => y, z => q )
  #
  # _read_file(nest => 1):
  #  a : b,c
  #  d : e,f
  # returns ( x => { b => 1, c => 1 },
  #           d => { e => 1, f => 1 } )
  #
  # _read_file(nest => 2):
  #  a : (b) c,d
  #  a : (g) h,i
  #  d : (e) f,g
  # returns ( a => { b => { c => 1, d => 1 },
  #                { g => { h => 1, i => 1 },
  #           d => { e => { f => 1, g => 1 } );
  # Lines beginning with a # are ignored.
  # All spaces are silently squashed.
  #
  TRACE "reading $filename";
  my %h;
  open my $fh, '<', $filename;
  flock($fh, LOCK_SH) or WARN "Cannot lock $filename - $!\n";
  for my $line ($fh->getlines)
  {
    chomp $line;
    $line =~ s/\s//g;
    next if $line =~ /^#/ || !length($line);
    my ($k,$v) = split /:/, $line;
    my $p;
    # commenting this out because it puts the password salt in
    # the log file if TRACE is on
    #TRACE "parsing $v";
    ($k,$p) = ( $k =~ m/^(.*)\(([^)]*)\)$/) if $args{nest}==2;
    $k = lc $k if $args{lc_keys};
    $v = lc $v if $args{lc_values};
    my %m = ( map { $_ => 1 } split /,/, $v ) if $args{nest};
    if ($args{nest}==0)
    {
      $h{$k} = $v;
    }
    elsif ($args{nest}==1)
    {
      $h{$k} ||= {};
      @{ $h{$k} }{keys %m} = values %m;
    }
    elsif ($args{nest}==2)
    {
      $h{$k} ||= {};
      $h{$k}{$p} ||= {};
      @{ $h{$k}{$p} }{keys %m} = values %m;
    }
  }
  return %h;
}

sub temp_dir
{
  state $dir;
  unless(defined $dir)
  {
    $dir = File::Temp::tempdir( CLEANUP => 1);
  }
  return $dir;
}

sub flat_init
{
  my($self) = @_;
  my $config = $self->global_config;
    
  foreach my $file (qw( group_file resource_file user_file ))
  {
    $config->{$file} //= do {
      my $fn = File::Spec->catfile($self->temp_dir, $file);
      WARN "$file not defined in configuration, using temp $fn, modifiations will be lost on exit";
      touch $fn;
      $fn;
    };
  }
}

sub lock_and_update_file
{
  use autodie;
  my($self, $filename, $cb) = @_;

  my $buffer; 
  
  eval {
    open my $fh, '+<', $filename;
    eval { flock $fh, LOCK_EX };
    WARN "cannot lock $filename - $@" if $@;
  
    $buffer = $cb->($fh);
    
    if(defined $buffer)
    {
      TRACE "updating $filename";
      seek $fh, 0, 0;
      truncate $fh, 0;
      print $fh $buffer;
    }
    
    mark_changed($filename);
    close $fh;
  };

  if(my $error = $@)
  {
    ERROR "update $filename: $error";
  }

  return defined $buffer;
}

sub lock_and_read_file
{
  my($self, $filename, $cb) = @_;
  
  use autodie;
  
  my $ok = eval {
  
    open my $fh, '<', $filename;
    eval { flock $fh, LOCK_SH };
    WARN "cannot lock $filename - $@" if $@;
  
    my $ret  = $cb->($fh);
    
    close $fh;
    
    $ret;
  };
  
  if(my $error = $@)
  {
    ERROR "reading $filename: $error";
  }
  
  $ok;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PlugAuth::Role::Flat - private role used by L<FlatAuth|PlugAuth::Plugin::FlatAuth> and L<FlatAuthz|PlugAuth::Plugin::FlatAuthz>.

=head1 VERSION

version 0.35

=head1 SEE ALSO

L<PlugAuth>,
L<PlugAuth::Plugin::FlatAuth>,
L<PlugAuth::Plugin::FlatAuthz>,
L<PlugAuth::Guide::Plugin>

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
