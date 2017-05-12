use strict;
use warnings;

package Template::Pure::DataContext;
 
use Scalar::Util 'blessed';
use Template::Pure::UndefObject;
use Data::Dumper;

use overload
  q{""} => sub { shift->value },
  'fallback' => 1;

sub new {
  my ($proto, $data_proto, $root) = @_;
  my $class = ref($proto) || $proto;
  return bless +{
    value => $data_proto,
    root => ($root||$data_proto),
  }, $class;
}

sub value { shift->{value} }
 
sub at {
  my ($self, %at) = @_;
  my $current = $at{absolute} ? $self->{root} : $self->{value};
  foreach my $at(@{$at{path}}) {
    my $key = $at->{key} || die "missing key";
    if(blessed $current) {
      if($current->can($key)) {
        $current = $current->$key;
      } elsif($at->{optional}) {
        $current = undef;
      } else {
        if($current->isa('Template::Pure::DataProxy')) {
          eval "use Moose (); 1" || die "Missing path '$key' in data context ". Dumper($current);
          my @paths =  ("--THIS CLASS--", map { $_ ."\t(hashkey)"} sort keys %{$current->{extra}});
          if(ref $current->{data} eq 'HASH') {
            push @paths, map { "$_\t(hashkey)" } sort keys %{$current->{data}};
          } else {
            # Assume its an object
            my @methods =  Class::MOP::Class->initialize(ref $current->{data})->get_method_list;
            push @paths, map {
              $_ ."\t(". ref($current->{data}) . ")";
            } map {
              ref $_ ? $_->name : $_;
              } sort @methods;
          }
          my @all = Class::MOP::Class->initialize(ref $current->{data})->get_all_methods;
          push @paths, '---ALL CLASSES---' if @all;
          push @paths,
            map { $_->name ."\t(". $_->package_name .")" }
            grep { $_->package_name ne 'UNIVERSAL' }
            sort @all if @all;

          die "Missing path '$key' in object ". ref($current) .", available:\n".join '', map { "\t$_\n"} grep { $_ ne 'new' } @paths;        
        } else {
          eval "use Moose (); 1" || die "Missing path '$key' in data context ". Dumper($current);
          my @paths;
          my @methods =  Class::MOP::Class->initialize(ref $current)->get_method_list;
          push @paths, map { ref $_ ? $_->name : $_ } '---THIS CLASS---', @methods;
          my @all = Class::MOP::Class->initialize(ref $current)->get_all_method_names;
          push @paths, map { ref $_ ? $_->name : $_ } '---ALL CLASSES---', @all if @all;
          die "Missing path '$key' in object ". ref($current) .", available:\n".join ',', map { "\t$_\n"} grep { $_ ne 'new' } @paths;
        }
      }
    } elsif(ref $current eq 'HASH') {
      if(exists $current->{$key}) {
        $current = $current->{$key};
      } elsif($at->{optional}) {
        $current = undef;
      } else {
        my @paths =  keys %{$current};
         die "Missing path '$key' in Hashref, available:\n".join ',', map { "\t$_\n"} @paths;
      }
    } else {
      die "Can't find path '$key' in ". Dumper $current;
    }
    if($at->{maybe}) {
      $current = Template::Pure::UndefObject->maybe($current);
    }
  }
  return $self->new($current, $self->{root});
}

1;
