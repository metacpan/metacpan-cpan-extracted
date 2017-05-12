package OpenFrame::AppKit;

use OpenFrame::AppKit::App;
use OpenFrame::AppKit::Session;
use OpenFrame::AppKit::Segment::Images;
use OpenFrame::AppKit::Segment::LogFile;
use OpenFrame::AppKit::Segment::SessionLoader;
use OpenFrame::AppKit::Segment::TT2;

our $VERSION=3.03;

1;

__END__

=head1 NAME

OpenFrame::AppKit - The OpenFrame AppKit

=head1 SYNOPSIS

  use OpenFrame::AppKit;

=head1 DESCRIPTION

C<OpenFrame::AppKit> is a collection of classes to turn OpenFrame into an
application server.  All the classes included in the AppKit inherit from
C<Pipeline::Segment>, and thus are able to act as segments within an OpenFrame
pipeline.

=head1 CLASSES

=over 4

=item * OpenFrame::AppKit::App

Base application class for OpenFrame::AppKit

=item * OpenFrame::AppKit::Sesssion

Sessions for OpenFrame::AppKit

=item * OpenFrame::AppKit::Segment::Images

Static images handler for OpenFrame::AppKit

=item * OpenFrame::AppKit::Segment::LogFile

Simple logger for OpenFrame::AppKit

=item * OpenFrame::AppKit::Segment::SessionLoader

A session management segment for OpenFrame::AppKit

=item * OpenFrame::AppKit::Segment::TT2

A Template Toolkit template engine for OpenFrame::AppKit

=back

OpenFrame::AppKit also has some example applications in the form of
OpenFrame::AppKit::App::NameForm and OpenFrame::AppKit::Hangman.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2002 Fotango Ltd.  All Rights Reserved

This program is released under the same license as Perl itself.

http://opensource.fotango.com/

=cut
