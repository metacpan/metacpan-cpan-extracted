# $Id: Rule.pm,v 1.1.1.1 2004/11/22 17:52:11 root Exp $

package POE::Framework::MIDI::Rule;
use strict;
use vars qw($VERSION); $VERSION = '0.02';

sub new {
    my ($self, $class) = ({}, shift);
    bless $self, $class;
    my %params = @_;

    $self->{cfg} = \%params or die __PACKAGE__ . ' needs some config info';

    die "no context set" unless $self->{cfg}{context};
    die "invalid context $self->{cfg}->{context}" 
    	unless ($self->{cfg}->{context} eq 'bar' or $self->{cfg}->{context} eq 'event'); 

    $self->{params} = $self->{cfg}{params};

    return $self;
}

sub usage {
    return 'Oh dear. TODO: What does usage look like?';
}

# just in case we want to support on the fly context changes...
sub context {
    my ($self, $new_context) = @_;

    $new_context
        ? $self->{cfg}{context} = $new_context
        : return $self->{cfg}{context};
}

sub type {
    my ($self, $new_type) = @_;

    $new_type
        ? $self->{cfg}{type} = $new_type
        : return $self->{cfg}{type};
}

sub params {
    my $self = shift;
    return $self->{cfg}{params};
}

1;

__END__

=head1 NAME

POE::Framework::MIDI::Rule - A rule object to compare events

=head1 ABSTRACT

=head1 DESCRIPTION

A rule object to compare events.

=head1 SYNOPSIS

  $rule = new POE::Framework::MIDI::Rule({
      package => 'POE::Framework::MIDI::Rule::MyRule'
  });

  # it matches, or doesn't, or partially does
  $matchvalue = $rule->test(@events);

=head1 PUBLIC METHODS

=head2 new()

=head2 usage()

=head2 context()

=head2 params()

=head1 TO DO

Oh my.  What does usage() look like?

=head1 SEE ALSO

L<POE>

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
