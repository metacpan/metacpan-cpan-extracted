package MusicRoom::Context;

=head1 NAME

MusicRoom::Context - Bind variables to values for MusicRoom processes

=head1 DESCRIPTION

This package tracks the values that variables have for MusicRoom processes.  The key 
action here is to maintain values so that running processes can keep track, to 
serialise them into the database so we can store them between runs and to extract 
them from the database.

=cut

use strict;
use warnings;
use Carp;

sub new
  {
    my $class = shift;
    my $self = bless 
      {
        # UNIX time of last save/restore
        timestamp => -1,
        parent => undef,
        vars => {},
      },$class;

    $self->{needs_saving} = 0;

    return $self;
  }

sub get
  {
    my($self,$name) = @_;

    return $self->{vars}->{$name}
                 if(defined $self->{vars}->{$name});

    my $val;

    $val = $self->{parent}->get($name)
                 if(defined $self->{parent});
    if(!defined $val)
      {
        carp("Undefined var $name in context $self->{id}");
        return undef;
      }
    return $val;
  }

sub set
  {
    my($self,$name,$val) = @_;
    
    if(!defined $self->{vars}->{$name})
      {
        # Do we complain about setting an as yet undefined value?
        $self->{vars}->{$name} = "";
      }
    $self->{vars}->{$name} = $val;
    $self->{needs_saving} = 1;
  }

sub DESTROY
  {
    my($self) = @_;

    if($self->{needs_saving})
      {
        carp("Destroying modified context");
      }
  }

sub save
  {
    my($self) = @_;

    # Write the current value of the context into the database

    # Note that the current settings have been saved
    $self->{needs_saving} = 0;
  }

sub restore
  {
    my($self) = @_;

    # Note that the current settings have been saved
    $self->{needs_saving} = 0;
  }

1;

