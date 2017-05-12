package NetStumbler::Speech;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

#
# We all for several exports
#
our $VERSION = '0.01';
use Win32::OLE qw(in with);
use Win32::OLE::Const;
our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
#
# Exported Functions by request
#
@EXPORT_OK = qw(
hasLibrary
initializeSpeech 
speak
setVoice
getVoices
getVoiceDesc
);  # symbols to export on request

=head1 Object Methods

=head2 new()

Returns a new Wap object. NOTE: this method may take some time to execute
as it loads the list into memory at construction time

=cut

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    $Win32::OLE::Warn = 3; # die on errors...
    $self->{hasSpeech} = 1;
    $self->{speech} = undef;
    $self->{initialized} = 0;
    bless ($self, $class);
    eval
    {
        use Win32::OLE::Const 'Microsoft Speech Object Library';
    };
    if($@)
    {
        $self->{hasSpeech} = 0;
    }
    return $self;
}

=head2 hasLibrary

Params:
        none
Returns:
	true if speech library could be loaded
Example:
	if($obj->hasLibrary)
	{
		# do something here
	}

=cut


sub hasLibrary
{
    my $self = shift;
    return $self->{hasSpeech};
}

=head2 initializeSpeech

Params:
        none
Returns:
	true if speech library could be initialized
Example:
	if($obj->initializeSpeech)
	{
		# do something here
	}

=cut

sub initializeSpeech
{
    my $self = shift;
    if($self->{hasSpeech})
    {
	$self->{speech} = Win32::OLE->new('Sapi.SpVoice');	
	$self->{initialized} = 1;
    }
    return $self->{initialized};
}

=head2 speak(string)

Params:
	-string The string to speak
Returns:
        none
Example:
        $obj->speak("Hello world");

=cut

sub speak
{
    my $self = shift;
    if($self->{hasSpeech})
    {
	unless($self->{initialized})
        {
            $self->initializeSpeech();
        }
	my $words = shift;
	$self->{speech}->Speak($words,1);
    }
}

=head2 setVoice(number)

Params:
	-number The voice number to use
Returns:
        none
Example:
        $obj->setVoice(1);

=cut

sub setVoice
{
    my $self = shift;
    if($self->{hasSpeech})
    { 
	unless($self->{initialized})
        {
            $self->initializeSpeech();
        }
	my $voice = shift;
	$self->{speech}->{Voice} = $self->{speech}->GetVoices()->Item($voice);
    }
}

=head2 getVoiceDesc(number)

Params:
	-number The voice number you want to get the description for
Returns:
        string description of the voice
Example:
        print "Voice 1 ",$obj->getVoiceDesc(1),"\n";

=cut

sub getVoiceDesc
{
    my $self = shift;
    if($self->{hasSpeech})
    { 
	unless($self->{initialized})
        {
            $self->initializeSpeech();
        }
	my $voice = shift;
	return $self->{speech}->GetVoices()->Item($voice)->GetDescription();
    }
}

=head2 getVoices()

Params:
	none
Returns:
        hash of voices keyed by voice number
Example:
        my %hash = $obj->getVoices;
        foreach my $key (keys(%hash))
        {
            print "Voice $key ",$hash{$key};
        }

=cut

sub getVoices
{
    my $self = shift;
    if($self->{hasSpeech})
    {
	unless($self->{initialized})
        {
            $self->initializeSpeech();
        }
	my $vg = $self->{speech}->GetVoices();
	my $cnt = $vg->{Count};
	my %voices;
	for(my $i=0;$i<$cnt;$i++)
	{
		$voices{$i} = $vg->Item($i)->GetDescription();
	}
	return %voices;
    }
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

NetStumbler::Speech - Speech tools for NetStumbler

=head1 SYNOPSIS

  use NetStumbler::Speech;
  my $speechlib = NetStumbler::Speech->new();
  $speechlib->speak("Hello world!");

=head1 DESCRIPTION

 This module handles interaction with Microsoft speech libraries
 as I find a speech library for use on linux/mac I will add support for those
 
=head2 EXPORT

These functions avaibale for export
hasLibrary
initializeSpeech 
speak
setVoice
getVoices
getVoiceDesc

=head1 SEE ALSO

Win32API and MSDN For Speech API examples

=head1 AUTHOR

Salvatore E. ScottoDiLuzio<lt>washu@olypmus.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Salvatore ScottoDiLuzio

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
