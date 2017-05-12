package News::Pan::Server::Group;
use strict;
use warnings;
use Carp;
use base 'News::Pan::Server::Group::_Search';
use LEOCHARRE::DEBUG;

sub new {
   my ($class,$self) = @_; 
   $self||={};
   bless $self, $class;
   return $self;   
}

sub name {
   my $self = shift;
   my $abs = $self->abs_path;
   $abs=~/([^\/]+)$/ or confess('cant get group name');
   return $1;
}

sub set_abs_path {
   my ($self,$arg) = @_;
   defined $arg or confess('missing arg');
   
   $self->_reset; # reset everything
   my $resolved =  Cwd::abs_path($arg) or warn("cannot resolve $arg") and return 0;
   -f $resolved or warn($resolved." is not a file") and return 0;     
   
   $self->{_data_} ||={};
   $self->{_data_}->{abs_path} = $resolved;
   $self->{abs_path} = undef; # so it wont stay with original value if the object is used multiple times for diff groups
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


sub subjects {
   my $self = shift;
   return $self->_subjects;
}






sub _subjects {
   my $self = shift;
   
   unless( defined $self->{_data_}->{subjects} ){
      my $abs = $self->abs_path;
      my $subjects=[];
      
      open(INF,"< $abs") or confess($!);
      
      my $lastline;
   
      while(<INF>){
         my $line = $_;      
         if ($line=~/^\s+$/){ #article ended
         
         # then last line was subject
         push @$subjects, $lastline;
         }
         $line=~s/^\s|\s$//g;
         $lastline = $line;      
      }
      close INF or confess($!); 
   
      $self->{_data_}->{subjects} = $subjects;   
   }

   return $self->{_data_}->{subjects};
}

sub subjects_count {
   my $self = shift;
   my $count = scalar @{$self->subjects};
   return $count;
}

sub _reset {
   my $self = shift;
   $self->{_data_} = undef;
   return 1;
}


1;

__END__

=pod

=head1 NAME

News::Pan::Server::Group - abstraction to a pan news group cache file

=head1 DESCRIPTION

There are two ways to set the abs_path of the news group cache file.
Either through set_asb_path(), which returns boolean, or through argument to constructor.
If you set it through argument to constructor, it will throw an exception if this is not a file.

=head2 new()

   my $server = new News::Pan::Server::Group({ abs_path => '/home/myself/.pan/astraweb/alt.binaries.sounds.mp3' }); 

   my $server = new News::Pan::Server::Group;
   $server->set_asb_path( '/home/myself/.pan/astraweb/alt.binaries.sounds.mp3' ) or warn('not a file');
   

=head2 set_abs_path()

set the abs path for this news group cache file

=head2 abs_path

returns abs path to file

