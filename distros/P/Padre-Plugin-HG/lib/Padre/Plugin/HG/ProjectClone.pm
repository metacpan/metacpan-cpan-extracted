package Padre::Plugin::HG::ProjectClone;






=pod

=head1 NAME

package Padre::Plugin::HG::ProjectClone 
Displays the prompts for making a project clone.

=head1 SYNOPSIS

  my $object = Padre::Plugin::HG::ProjectClone->new();
  
  thats it will display the prompts and call the clone method. 

=head1 DESCRIPTION



=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

use Wx qw[:everything];
use base 'Wx::Panel';

=pod

=head2 new

 create a new ProjectClone object. 
 

=cut

sub new
{
    my ($class, $hg) = @_; 
    my $self       = $class->SUPER::new( Padre::Current->main);
    $self->{hg} = $hg;
    return $self;
}



sub enter_repository
{
 my ($self) = @_;
 my $main = Padre->ide->wx->main;
 my $message = $main->prompt("Clone Project", "Enter the Project URL to clone", 'http://');    
 $self->{project_url} = $message ; 
 return $message;
}

sub choose_destination
{
    my ($self) = @_;
    my $dialog = Wx::DirDialog->new($self, 'Choose a Destination Directory');
    my $choice = $dialog->ShowModal();
    if ($choice == Wx::wxID_CANCEL)
    {   
        $self->{destination_dir} = undef();
        return;
    }
    else
    {
        $self->{destination_dir} = $dialog->GetPath();
        return $self->{destination_dir};
    }
}

sub project_url
{
       my($self) =@_;
       return $self->{project_url};
}

sub destination_dir
{
        my($self) =@_;
        return $self->{destination_dir};
}


1;

=pod

=head1 SUPPORT

No support is available

=head1 AUTHOR

Copyright 2009 Michael Mueller

=cut
