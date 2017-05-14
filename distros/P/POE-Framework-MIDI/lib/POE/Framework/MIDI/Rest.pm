# $Id: Rest.pm,v 1.1.1.1 2004/11/22 17:52:11 root Exp $

package POE::Framework::MIDI::Rest;

use strict;
use vars '$VERSION'; $VERSION = '0.02';
use POE::Framework::MIDI::Utility;

sub new {
    my ($self, $class) = ({}, shift);
    bless $self, $class;
  	my %params = @_;
  	$self->{cfg} = \%params;
    return $self;    
}

sub duration {
    my ($self, $new_duration) = @_;
    $new_duration 
        ? $self->{cfg}->{duration} = $new_duration 
        : return $self->{cfg}->{duration}        
}

sub name {
    return 'rest';    
}

1;

__END__

=head1 NAME

POE::Framework::MIDI::Rest - A rest event

=head1 ABSTRACT

=head1 DESCRIPTION

A rest event

=head1 SYNOPSIS

  my $rest = new POE::Framework::MIDI::Rest({
      duration => 'qn'  # a quarternote rest
  });

=head1 SEE ALSO

L<POE>

L<POE::Framework::MIDI::Utility>

L<http://justsomeguy.com/code/POE/POE-Framework-MIDI>

=head1 AUTHOR

Primary: Steve McNabb E<lt>steve@justsomeguy.comE<gt>

CPAN ID: SMCNABB

Secondary: Gene Boggs E<lt>cpan@ology.netE<gt>

CPAN ID: GENE

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2004 Steve McNabb. All rights reserved.
This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file 
included with this module.

=cut
