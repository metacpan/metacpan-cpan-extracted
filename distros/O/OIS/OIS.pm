package OIS;

use 5.006;
use strict;
use warnings;

# use all files under OIS/ - probably not a good idea
use OIS::Axis;
use OIS::EventArg;
use OIS::Exception;
use OIS::InputManager;
use OIS::JoyStick;
use OIS::JoyStickEvent;
use OIS::JoyStickListener;
use OIS::JoyStickState;
use OIS::Keyboard;
use OIS::KeyEvent;
use OIS::KeyListener;
use OIS::Mouse;
use OIS::MouseEvent;
use OIS::MouseListener;
use OIS::MouseState;
use OIS::Object;


require Exporter;
require DynaLoader;
our @ISA = qw(Exporter DynaLoader);

our $VERSION = '0.10';

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

__PACKAGE__->bootstrap($VERSION);


our %EXPORT_TAGS = (
    'Type' => [
        qw(
           OISUnknown
           OISKeyboard
           OISMouse
           OISJoyStick
           OISTablet
       )
    ],
    'ComponentType' => [
        qw(
           OIS_Unknown
           OIS_Button
           OIS_Axis
           OIS_Slider
           OIS_POV
       )
    ],
);

$EXPORT_TAGS{'all'} = [ map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS ];

our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = ();


1;

__END__


=head1 NAME

OIS - Perl binding for the OIS C++ input framework

=head1 SYNOPSIS

  use OIS;
  # ...

=head1 DESCRIPTION

For now, see README.txt.

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

=cut
