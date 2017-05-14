# $Id: MinimumNoteCount.pm,v 1.1.1.1 2004/11/22 17:52:11 root Exp $

package POE::Framework::MIDI::Rule::MinimumNoteCount;

use strict;
use vars '$VERSION'; $VERSION = '0.02';
use vars '@ISA';
@ISA = 'POE::Framework::MIDI::Rule';
use POE::Framework::MIDI::Rule;

# test whatever we're passed  
sub test {
    my ($self, $thing_to_test) = @_;
    die 'usage: $result = $rule->test(\@a_bar)'
        unless ref($thing_to_test) eq 'ARRAY';
    $self->{notecount} = undef;
    for (@$thing_to_test) {
        $_->{note} ? ++$self->{notecount} : next;    
    }
    print "saw $self->{notecount} notes in $thing_to_test\n"
        if $self->{params}->{verbose};
    $self->{notecount} >= $self->min_notes ? return 1 : return;
}        

sub min_notes {
    my $self = shift;
    die 'no min_notes set in ' .__PACKAGE__.'  params'
        unless $self->{params}->{min_notes};
    return $self->{params}->{min_notes};    
}

sub notecount {
    my $self = shift;
    $self->{notecount} = '0' unless $self->{notecount};
    return $self->{notecount};
}

1;

__END__

=head1 NAME

POE::Framework::MIDI::Rule::MinimumNoteCount - 

=head1 ABSTRACT

=head1 DESCRIPTION

This is a rather uninteresting rule to test the rules mechanimsm.
It's boolean:  it either matches, or doesn't.
Eventually we'll have ternary rules that can match, not match or 
partially match

=head1 SYNOPSIS

=head1 SEE ALSO

L<POE>

L<POE::Framework::MIDI::Rule>

L<http://justsomeguy.com/code/POE/POE-Framework-MIDI>

=head1 AUTHOR

Primary: Steve McNabb E<lt>steve@justsomeguy.comE<gt>

CPAN ID: SMCNABB

Secondary: Gene Boggs E<lt>cpan@ology.netE<gt>

CPAN ID: GENE

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2002 Steve McNabb. All rights reserved.
This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file 
included with this module.

=cut
