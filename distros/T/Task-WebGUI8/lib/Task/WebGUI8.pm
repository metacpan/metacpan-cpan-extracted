use strict;
use warnings;
package Task::WebGUI8;
{
  $Task::WebGUI8::VERSION = '2.0001';
}

1;

=head1 NAME

Task::WebGUI8 - Get all the prereqs for WebGUI

=head1 SYNOPSIS

 cpanm Task::WebGUI

=head1 DESCRIPTION

Installing Task::WebGUI8 will ensure that you have all the prereq modules needed to run WebGUI8 (L<http://www.webgui.org>).

L<Task::WebGUI8> is a fork of L<Task::WebGUI>; most notably, some graphs are now rendered with L<GD>, and the L<Image::Magick> depedency has been removed.
Prior to that change, L<Task::WebGUI> attempted to support versions both 7 and 8.


=head1 AUTHOR

JT Smith (jt at plainblack dot com) -- wrote L<Task::WebGUI>
Scott Walters (L<scott@slowass.net>) -- modified L<Task::WebGUI> into L<Task::WebGUI8>
