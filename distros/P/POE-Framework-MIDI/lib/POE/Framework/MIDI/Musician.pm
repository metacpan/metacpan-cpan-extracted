# $Id: Musician.pm,v 1.2 2002/09/17 21:14:01 ology Exp $

# non-POE musician functionality
package POE::Framework::MIDI::Musician;
use strict;
use vars qw/@ISA @EXPORT/;
use Exporter;  # i'm not sure if i should be exporting here, but it works for now.
@ISA = qw(Exporter);
@EXPORT = qw(new package name channel);
my $VERSION = '0.1a';

sub new
{
	my($self,$class) = ({},shift);
	bless($self,$class);
    $self->{cfg} = shift;
	die "no package provided to POE::Framework::MIDI::Musician....
	it needs a package to know what to play."
	unless $self->{cfg}->{package};
    return $self;
}

sub package
{
	my $self = shift;
	return $self->{cfg}->{package};
}

sub name
{
	my $self = shift;
	return $self->{cfg}->{name};	
}

sub channel
{
	my $self = shift;
	return $self->{cfg}->{channel};
}

1;

=head1 NAME

POE::Framework::MIDI::Musician

=head1 DESCRIPTION

Non-POE Musician functionality. This package takes a package name as a configuration
parameter, and uses that package to create musical events, and run them through rules
and transformations.

=head1 USAGE

This module is configured as per the 'musicians' array reference defined in 
the spawn method of POEConductor and coordinated by the POEConductor to procduce
a MIDI event stream.

=head1 BUGS

=head1 SUPPORT

=head1 AUTHOR

	Steve McNabb
	CPAN ID: JUSTSOMEGUY
	steve@justsomeguy.com
	http://justsomeguy.com/code/POE/POE-Framework-MIDI 

=head1 COPYRIGHT

Copyright (c) 2002 Steve McNabb. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1). POE.  Perl-MIDI

=cut
