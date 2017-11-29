package Syntax::Kamelon::Wx::PluggableTextCtrl;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.01";

use Wx qw( :textctrl :font :colour );
use Wx::DND;
use Wx qw( wxTheClipboard );
use base qw( Wx::TextCtrl );
use Wx::Event qw( EVT_CHAR );

require Syntax::Kamelon::Wx::PluggableTextCtrl::KeyEchoes;
require Syntax::Kamelon::Wx::PluggableTextCtrl::UndoRedo;
require Syntax::Kamelon::Wx::PluggableTextCtrl::Highlighter;

my $defaultfont = [10, wxFONTFAMILY_MODERN, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL, 0];

my $debug = 0;

if ($debug) {
   use Data::Dumper;
}

sub new {
   my $class = shift;
   my $self = $class->SUPER::new(@_);

   $self->{CALLBACK} = sub {};
   $self->{COMMANDS} = {
      'doremove' => \&DoRemove,
      'doreplace' => \&DoReplace,
      'dowrite' => \&DoWrite,
   };
   $self->{LISTENING} = 0;
   
   $self->{OVRMODE} = 0;
   $self->{PLUGINS} = [];

   $self->SetFont( Wx::Font->new(@$defaultfont) );
   EVT_CHAR($self, \&OnChar);

   return $self;
}

sub AppendText {
   my $self = shift;
   unless ($self->Broadcast('append', @_)) {
      $self->SUPER::Append(@_);
   }
}

sub Broadcast {
   my $self = shift;
   my $plugs = $self->{PLUGINS};
   my $flag = 0;
   foreach (@$plugs) {
      if ($_->Receive(@_)) {
         $flag = 1;
      }
   }
   return $flag;
}



1;
__END__
