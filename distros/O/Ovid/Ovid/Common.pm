use strict;
package Ovid::Common;
use Ovid::Error;
@Ovid::Common::ISA = qw(Ovid::Error);

sub new {
  my $self = shift;
  $self = bless { args => { @_ } }, ref($self) || $self;
  
  if ($self->can('accessors')){
    $self->make_accessors(%{$self->accessors});
  }
  
  
  my $defaults;
  
  if ($self->can('defaults')){
    $defaults = $self->defaults;
  }
  
  for my $r ($defaults, $self->{args})
    {
      while (my ($k, $v) = each %$r){
        if ($self->can($k)){
          $self->$k($v);
        }
      }
    }
  
  if ($self->can('init')){
    $self->init(@_);
  }
  
  return $self;
}

#  $self->make_accessors(scalar => [qw()], array => [qw()]);

sub make_accessors
{
  my ($self, %accessors) = @_;
  
  my $package_name = __PACKAGE__;
  
  no strict;
  
  #simple accessors
  while (my ($type, $list) = each %accessors){
    if ($type eq 'scalar'){
      for my $accessor (@$list)
        {
          my $t = qq[${package_name}::${accessor}];
          *$t = 
            sub {
              my $self = shift;
              my $argc = scalar (@_);
              if ($argc == 0){
                return $self->{$accessor};
              }
              elsif ($argc == 1) {
                $self->{$accessor} = $_[0];
              }
              else {
                fatal "accessor [$accessor] called with too many arguments ($argc); @_";
              }
            };
        }
    }
    elsif ($type eq 'array')
    {
      #array based accessors
      for my $accessor (@$list)
        {
          my $t = qq[${package_name}::${accessor}];
          *$t = 
            sub {
              my $self = shift;
              my $argc = scalar (@_);
              my @caller = caller(1);
   
              #warning "array accessor [$accessor] called by caller [@caller] with $argc args [@_]";
              
              if ($argc == 0){
                if (wantarray){
                  #warning "accessor [$accessor] returning list: @{$self->{$accessor}}";
                    return @{$self->{$accessor}};
                }
                else {
                  #warning "accessor [$accessor] returning scalar: $self->{$accessor}";
                  return $self->{$accessor};
                }
              }
              else {
                for my $r (@_){
                  if (ref($r) eq 'ARRAY'){
                    push @{$self->{$accessor}}, @$r;
                  }
                  else {
                    push @{$self->{$accessor}}, $r;
                  }
                }
              }
           };
      }
    }
    else {
      fatal "unknown accessor type: $type";
    }
  }
}

sub do_system 
{
  my ($self, $cmd) = @_;
  my $rv = system($cmd);
  return ($rv >> 8);
}

sub find_exec
{
  my ($self, $bin) = @_;
  my $file;
  for my $path (split /:/, $ENV{PATH}){
    my $f = qq[${path}/$bin];
    if (-f $f && -x _){
      $file = $f;
      last;
    }
  }
  return $file;
}

1;

