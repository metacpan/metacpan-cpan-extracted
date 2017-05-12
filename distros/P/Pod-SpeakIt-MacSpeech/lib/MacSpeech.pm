# $Id$
package Pod::SpeakIt::MacSpeech;
use strict;
use base qw(Pod::PseudoPod);

use warnings;
no warnings;

use subs qw();
use vars qw($VERSION);

use Mac::Files;
use Mac::Speech;

my $voice   = $Mac::Speech::Voice{Victoria};
my $channel = NewSpeechChannel($voice);
SetSpeechPitch($channel, 0.9*GetSpeechPitch($channel) );
SetSpeechRate( $channel, 0.7*GetSpeechRate($channel) );

$VERSION = '0.11';

=head1 NAME

Pod::SpeakIt::MacSpeech - This is the description

=head1 SYNOPSIS

	use Pod::SpeakIt::MacSpeech;

=head1 DESCRIPTION

***THIS IS ALPHA SOFTWARE. MAJOR PARTS WILL CHANGE***

This module overrides and extends C<Pod::PsuedoPod> to read
Pod aloud.

=cut

sub DESTROY
	{
	$_[0]->SUPER::DESTROY;
	DisposeSpeechChannel($channel)
	}
	
sub handle_text { $_[0]{'scratch'} .= $_[1] }

sub speak_it 
	{	
	SpeakText( $channel, $_[0]->{'scratch'} );
	sleep 1 while SpeechBusy();
	$_[0]->{'scratch'} = '';
	sleep 1;
	
	return;
	}

sub document_header  
	{
	print STDERR "HERE I AM";
	}

sub start_head0 { }
sub start_head1 { }
sub start_head2 { }
sub start_head3 { }
sub start_head4 { }
	
sub end_head0 { $_[0]->speak_it }
sub end_head1 { $_[0]->speak_it }
sub end_head2 { $_[0]->speak_it }

sub end_Para  { $_[0]->speak_it }
	
sub end_Verbatim 
	{	
	sleep 1;
	$_[0]->{scratch} = "Code section (skipping)";
	$_[0]->speak_it;
	sleep 1;
	}

=head1 TO DO

=over 4

=item * handle item lists

=item * different voices for headings and paras and code

=item * configure voices, pitch, and rate

=back

=head1 SEE ALSO

L<Pod::InDesign::TaggedText>, L<Pod::Simple>

=head1 SOURCE AVAILABILITY

This source is part of a SourceForge project which always has the
latest sources in SVN, as well as all of the previous releases.

	http://sourceforge.net/projects/brian-d-foy/

If, for some reason, I disappear from the world, one of the other
members of the project can shepherd this module appropriately.

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007-2008, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;