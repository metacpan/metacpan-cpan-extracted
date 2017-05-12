# $Id: Rule.pm,v 1.2 2002/09/17 21:14:01 ology Exp $

# POE::Framework::MIDI::Rule - a baseclass for all rules to inherit from
package POE::Framework::MIDI::Rule;
use strict;
my $VERSION = '0.1a';

sub new
{
	my($self,$class) = ({},shift);
	bless $self,$class;
	$self->{cfg} = shift or die __PACKAGE__ . " needs a config hashref";	
	die $self->usage
	unless ($self->{cfg}->{context});
	$self->{params} = $self->{cfg}->{params};
	
	return $self;
}

sub usage
{
	return 'oh dear. TODO: what does useage look like?';
}

sub context
{
	my $self = shift;
	# just in case we want to support on the fly context changes....
	my $new_context = shift;
	$new_context ? $self->{cfg}->{context} = $new_context : return $self->{cfg}->{context};		
}

sub type
{
	my $self = shift;
	my $new_type = shift;
	$new_type ? $self->{cfg}->{type} = $new_type : return $self->{cfg}->{type};	
}

sub params
{
	my $self = shift;
	return $self->{cfg}->{params};	
}

1;

=head1 NAME

POE::Framework::MIDI::Rule

=head1 DESCRIPTION

A rule object to compare some events to. 

=head1 USAGE

my $rule = new POE::Framework::MIDI::Rule({ package => 'POE::Framework::MIDI::Rule::MyRule'});
my $matchvalue = $rule->test(@events); # it matches, or doesn't, or partially does


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
