package Ovid::Dependency;

use strict;

use Ovid::Common;
use Ovid::Error;

@Ovid::Dependency::ISA = qw(Ovid::Common Ovid::Error);

sub init {
  my $self = shift;
  if (my $t = $self->dir){
    $self->find_builder($t);
  }
}

sub accessors
{
  return { scalar => [qw(builder dir)], array => [qw()]};
}

sub find_builder
  {
    my ($self, $dir) = @_;
    
    $dir ||= $self->dir;
    
    fatal "missing builder directory" unless $dir;
    
    my @builders = qw(Makefile.PL);
    my $builder;
    
    for my $f (@builders)
      {
        my $p = qq[$dir/$f];
        if ( -f $p ){
          $builder = $p;
          last;
        }
      }
    
    if ($builder){
      debug "got builder file. $builder";
    }
    else {
      fatal "cannot find builder file @builders";
    }
    
    $self->builder($builder);
  }

sub dependencies
  {
    my ($self, $dir ) = @_;
    
    my $builder = $self->find_builder;
    
    my $pid = open(D, "-|");
    my $prefix='ovid-dependency:::'; 
    if ($pid == -1){
      fatal "cannot fork";
    }
    elsif ($pid) {   # parent
       my @deps;
       while (defined ($_ = <D>)) {
         chomp;
         if (/^$prefix(\S+)\s+(\S+)/){
           push @deps, { name => $1, version => $2 };
         }
       }
       close(D) || warning "child process failed $?";
       return @deps;
    } else {      # child

        my @deps;
        close STDIN;
        my $outhandle = \*STDOUT;

        eval {
                     no warnings;
                     no strict;
                     local *CORE::exit = *CORE::return;
                     my $orig_method = \&ExtUtils::MakeMaker::WriteMakefile;
                     local *ExtUtils::MakeMaker::WriteMakefile =
                             sub {
                                   my %deps = @_;
                                   push @deps, $deps{PREREQ_PM};
                                   goto $orig_method;
                              };
                     chdir ($dir) or fatal "cannot chdir to $dir. $!"; 
                     do $builder;
             };

        if ($@)
        {
          fatal "cannot get dependencies. $@";
        }
        else
        {
          for my $r (@deps){
            while (my ($k, $v) = each %$r){
              print $outhandle qq[${prefix}$k\t$v\n];
            }
          }
        }
        close $outhandle;
        exit;
    }
  }

1;

