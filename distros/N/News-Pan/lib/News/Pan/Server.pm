package News::Pan::Server;
use strict;
use Carp;
use warnings;
use Cwd;
use LEOCHARRE::DEBUG;
use News::Pan::Server::Group;
our $VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;

sub new {
   my ($class,$self) = @_; 
   $self||={};
   bless $self, $class;
   return $self;   
}

sub set_abs_path {
   my ($self,$arg) = @_;
   defined $arg or confess('missing arg');
   
   $self->_reset; # reset everything
   my $resolved =  Cwd::abs_path($arg) or warn("cannot resolve $arg") and return 0;
   -d $resolved or warn($resolved." is not a dir") and return 0;     
   
   $self->{_data_} ||={};
   $self->{_data_}->{abs_path} = $resolved;
   $self->{abs_path} = undef; # so it wont stay with original value if the object is used multiple times for diff servers
   return 1; 
}

sub abs_path {
   my $self = shift;
   unless( defined $self->{_data_}->{abs_path} ){   
      
      defined $self->{abs_path} or confess('missing abs_path argument to constructor');
      $self->set_abs_path( $self->{abs_path} ) or confess("can't set abs path to $$self{abs_path}");  
   }
   return $self->{_data_}->{abs_path};
}

sub groups_subscribed {
   my $self = shift;
   return $self->_groups;
}


sub groups_subscribed_binaries {
   my $self = shift;
   my @g = grep { /\.binaries\./i } @{$self->groups_subscribed};
   return \@g;
}


# reset all data
sub _reset {
   my $self = shift;
   $self->{_data_} = undef;
   return 1;
}


sub _groups {
   my $self = shift;

   unless( $self->{_data_}->{subscribed_groups} ){

      opendir(DIR,$self->abs_path) or confess($!);   
      my @files = grep { -f $self->abs_path.'/'.$_ } readdir DIR;
      closedir DIR or confess($!);
      
      $self->{_data_}->{subscribed_groups} = \@files;
   }      
   return $self->{_data_}->{subscribed_groups};
}


sub group {
   my ($self,$name) = @_;
   defined $name or confess('misssing arg');
   $self->{_data}->{group_objects} ||={};
   unless($self->{_data}->{group_objects}->{$name}){

      $self->{_data}->{group_objects}->{$name} = new News::Pan::Server::Group;
      $self->{_data}->{group_objects}->{$name}->set_abs_path( $self->abs_path.'/'.$name ) or warn("cant set $name group");      

   }

   return $self->{_data}->{group_objects}->{$name};
}




1;

__END__

=pod

=head1 NAME

News::Pan::Server - abstraction to a collection of pan server cache files

=head1 DESCRIPTION

There are two ways to set the abs_path of the news server cache, this is where your group files reside.
Either through set_asb_path(), which returns boolean, or through argument to constructor.
If you set it through argument to constructor, it will throw an exception if this is not a directory.

=head2 new()

   my $server = new News::Pan::Server({ abs_path => '/home/myself/.pan/astraweb' }); 

   my $server = new News::Pan::Server;    
   $server->set_asb_path( '/home/myself/.pan/astraweb' ) or warn('not a dir');
   

=head2 set_abs_path()

set the abs path for this news server cache dir.

=head2 abs_path

returns abs patht to server cache dir

=head2 groups_subscribed()

takes no argument
returns array ref list of groups subscribed to
(this is by what is read in abs_path files)
cached in object instance, returns the names 'alt.binaries.group,etc' etc

=head2 groups_subscribed_binaries()

returns array ref of groups that are binaries




=head2 group()

argument is group name, returns News::Pan::Server::Group object.
returns undef and warns on fail

=cut

