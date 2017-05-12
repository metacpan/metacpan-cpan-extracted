package Ogre::AL;

use 5.006;   # probably > 5.8 actually, I dunno
use strict;
use warnings;

require DynaLoader;
our @ISA = qw(DynaLoader);

our $VERSION = '0.03';


# use all files under lib/Ogre/AL/ here
use Ogre::AL::Listener;
use Ogre::AL::Sound;
use Ogre::AL::SoundManager;


sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

__PACKAGE__->bootstrap($VERSION);



# constants here


1;
__END__

=head1 NAME

Ogre::AL - Perl binding for the OgreAL C++ 3D audio library

=head1 SYNOPSIS

 ...

=head1 DESCRIPTION

F<README.txt>

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing info, see F<README.txt>.

=cut
