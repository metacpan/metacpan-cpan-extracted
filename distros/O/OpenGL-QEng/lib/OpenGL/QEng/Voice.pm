#$Id: Voice.pm 434 2008-11-06 21:14:40Z overmars $

####------------------------------------------
##@file
# Define Voice class

#--------------------
## @class Voice
# Base class for voice-like user interface
package OpenGL::QEng::Voice;

use strict;
use warnings;
#use Audio::Ao;

use base qw/OpenGL::QEng::OUtil/;

#-------------   Class Methods    -------------------------------

## @cmethod CLASS new($class)>
#Constructor
sub new { die join ':', caller;
  my ($class) = @_;
  my $self = {};
  bless($self,$class);
}

#--Instance Methods -----------------------------------

{my $class_is_ready = 0;

 sub init_class {
   return if ($class_is_ready);
   $class_is_ready = 1;
   return;

   #Audio::Ao::initialize_ao();

   my $is_be;# = Audio::Ao::is_big_endian();
   my $id;# = Audio::Ao::driver_id('oss');
   my $info;# = Audio::Ao::driver_info($id);
   for my $k (keys %$info) {
     print STDOUT "driver info{$k} = $info->{$k}\n";
   }
   my $i = 0;
   print STDOUT map { "\t".$i++.": $_ \n" } @{$info->{options}};
#  $Voice::ao = Audio::Ao::open_live($id,
#				    8,    #bits
#				    11127, #rate,
#				    1,     #channels,
#				    $is_be,
#				    {})
#    or die "error: couldn't open device oss($id)\n";
   my $infile;
   my $sound = '/usr/share/sounds/KDE_Beep_Honk.wav';
   open($infile,'<',$sound)
     or die "error: couldn't open [$sound]\n";
   $Voice::sound_buffer = join('',<$infile>);
   close $infile;
   $Voice::sound_buffer;
 }
}

## @method message()
#print messages
sub message {
  my $self = shift @_;
  print @_;
}

#---------------------------------------------------------------------

## @method my_bellRing()
#Ring/beep the bell
sub bellRing {
  $_[0]->init_class();
  $_[0]->message("Ding!!!\n");
#  Audio::Ao::play($Voice::ao,$Voice::sound_buffer,length($Voice::sound_buffer));
}

#==================================================================
###
### Test Driver for Voice Object
###

if (not defined caller()) {
  package main;

  # Create a voice object
  my $v = new Voice;

  $v->message("Hello World\n");
  $v->bellRing();
}
#---------------------------------------------------------------------
1;

__END__

=head1 NAME

Voice -  Base class for voice-like user interface

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

