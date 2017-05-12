package Padre::Plugin::HG::UserPassPrompt;

=pod

=head1 NAME

Padre::Plugin::HG::UserPassPrompt 
provides the username and password prompts for Padre::Plugin::HG

=head1 SYNOPSIS

  my $object = Padre::Plugin::HG::UserPassPrompt->new(
      title => 'project X',
      default_username => 'fred',
      default_password => 'XXXX',
      
  );
  
  $password = $object->{password};
  $username = $object->{username};

=head1 DESCRIPTION

This module diplays a username and password prompt for actions like
pushing in Padre::Plugin::HG

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;
use Wx qw[:everything];
use Wx::Event qw( EVT_BUTTON );
use base 'Wx::Panel';
our $VERSION = '0.01';

=pod

=head2 new

  my $object = adre::Plugin::HG::UserPassPrompt->new(
      title => 'project X',
      default_username => 'fred',
      default_password => 'XXXX',
      
  );

The C<new> constructor is the only method. 
it will display the username and password prompts  

Access the results via
$object->{username} and $object->{password}

=cut

sub new
{
    my ($class, %params) = @_; 
    my $self       = $class->SUPER::new( Padre::Current->main);
    
    my $user_name = Wx::TextEntryDialog->new(undef, 'Enter your User Name',$params{title},$params{default_username});
    $user_name->ShowModal();
    $self->{username} =  $user_name->GetValue();
    
    my $user_pass = Wx::PasswordEntryDialog->new(undef, 'Enter your Password',$params{title},$params{default_password},wxOK|wxCANCEL);
    $user_pass->ShowModal();
    $self->{password} =  $user_pass->GetValue();
    
    return $self;
}



1;

=pod

=head1 SUPPORT

http://bitbucket.org/code4pay/padre-plugin-hg/

=head1 AUTHOR

Copyright 2008 Michael Mueller .

=cut
