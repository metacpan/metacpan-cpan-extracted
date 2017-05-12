package Sman::Man::Cache; # has two subclasses:

#$Id$

use fields qw( none );

sub new {
   my Sman::Man::Cache $self = shift;
   unless (ref $self) {
       $self = fields::new($self);
       #$self->{_Foo_private} = "this is Foo's secret";
   }
   #$self->{foo} = 10;
   #$self->{bar} = 20;
   return $self;
}

#sub new {
#   my $proto = shift;
#   my $class = ref($proto) || $proto;
#   my $self  = {};
#   bless ($self, $class);
#   return $self;
#}

sub get {
    die "Must use subclass of __PACKAGE__";
}
sub set {
    die "Must use subclass of __PACKAGE__";
}

#package Sman::Man::Cache::FileCache;
#use fields qw( filecache ); 
# not needed
# this uses Cache::FileCache

1;

=head1 NAME

Sman::Man::Cache - 'Virtual base class' for converted manpages cache

=head1 SYNOPSIS

  This module provides an interface for subclasses, namely,
  Sman::Man::Cache::DB_File and Sman::Man::Cache::FileCache
    
=head1 DESCRIPTION

  This module provides an interface for subclasses, namely,
  Sman::Man::Cache::DB_File and Sman::Man::Cache::FileCache
    
=head1 AUTHOR
    
Josh Rabinowitz <joshr>
    
=head1 SEE ALSO
            
L<sman-update>, L<Sman::Man::Convert>, L<Sman::Man::Cache::FileCache>, L<sman.conf>
        
=cut    

