package TemplateM::Galore; # $Id: Galore.pm 2 2013-04-02 10:51:49Z abalama $
use strict;

use base qw/Exporter/;
use vars qw($VERSION);
our $VERSION = 2.21;

use TemplateM::Util;
use Carp;

our @EXPORT = qw/html/;

sub start {
    my $self = shift;
    my $label = shift;
    croak("[start] Incorrect call of method \"start\"") unless (defined($label));

    my $tpl = '';
    my $wrk = '';
    my $stk = '';
    
    $tpl = $2 if $self->{work} =~ m/<!--\s*do:\s*($label)\s*-->(.*?)<!--\s*loop:\s*\1\s*-->/s;

    return bless {
        template => $tpl,
        work     => $wrk,
        stackout => $stk,
        label    => $label,
        pobj     => $self,
        tf       => 1
    };
}
sub loop {
    my $self = shift;
    my $hr  = $_[0];
    
    croak("[loop] Incorrect call of method \"loop\"") unless (defined($hr));
    
    if (defined($hr) && (ref($hr) ne "HASH")) {
        if (ref($hr) eq "ARRAY") {
            $hr = {@$hr};
        } else {
            $hr = {@_};
        }
    }

    $self->{stackout} .= $self->{work};
  
    my $wrk = $self->{template};
   
    $wrk =~ s/<!--\s*val:\s*(\S+?)\s*-->/_exec_directive($hr,$1,'val')/ieg if defined($hr);
   
    $self->{work} = $wrk
}
sub finish {
    my $self = shift;

    $self->{stackout} .= $self->{work};
   
    $self->{work} = '';
   
    my $label = $self->{label};
    my $stack = $self->{stackout};
   
    if ($self->{pobj}->{tf}) {
        $self->{pobj}->{work} =~ s/<!--\s*do:\s*($label)\s*-->(.*?)<!--\s*loop:\s*\1\s*-->/$stack/s
    } else {
        $self->{pobj}->{looparr}->{$self->{label}} = $stack
    }
}
sub finalize { goto &finish }
sub cast {
    my $self = shift;
    my $hr   = $_[0];
    
    croak("[cast] Incorrect call of method \"cast\"") unless (defined $hr);

    unless (ref($hr) eq "HASH") {
        $hr = {@_};
    }
    
    $self->{work} =~ s/<!--\s*cgi:\s*(\S+?)\s*-->/_exec_directive($hr, $1, 'cgi')/ieg;
}
sub stash { goto &cast }
sub ifelse {
    my $self = shift;
    my $label = shift || '';
    my $predicate = shift || 0;

    croak("[efelse] Incorrect call of method \"ifelse\"") unless (defined($label));
    
    if ($predicate) {
       $self->{work} =~ s/<!--\s*if:\s*($label)\s*-->(.*?)<!--\s*end_?if:\s*\1\s*-->/$2/igs;
       $self->{work} =~ s/<!--\s*else:\s*($label)\s*-->.*?<!--\s*end_?else:\s*\1\s*-->//igs;
    } else { 
       $self->{work} =~ s/<!--\s*else:\s*($label)\s*-->(.*?)<!--\s*end_?else:\s*\1\s*-->/$2/igs;
       $self->{work} =~ s/<!--\s*if:\s*($label)\s*-->.*?<!--\s*end_?if:\s*\1\s*-->//igs;
    }
}
sub cast_if { goto &ifelse }
sub output {
    my $self = shift;
    my $property = shift || 'stackout';

    if (! $self->{tf} and $property eq 'stackout') {
        $self->{work} =~ s/<!--\s*do:\s*(\S+?)\s*-->(.*?)<!--\s*loop:\s*\1\s*-->/_analize($self->{looparr},$1)/egs;
        $self->{stackout} = $self->{work};
    }
    return defined($self->{$property}) ? $self->{$property} : ''
}
sub html {
    my $self = shift;
    my $header = $self->{header} || '';
    ($header) = read_attributes([['HEAD','HEADER']],@_) if (defined $_[0]);

    return $header . $self->output()
}
sub _exec_directive {
    my ($hr, $directive, $sig) = @_;
    
    if (defined($hr->{$directive})) {
        return $hr->{$directive};
    } else {
        return $sig?('<!-- '.$sig.': '.$directive.' -->'):'';
    }
}
sub _analize {
    my ($hr, $directive) = @_;
    if (defined($hr->{$directive})) {
        return $hr->{$directive}
    } 
    return ''
    
}
1;

