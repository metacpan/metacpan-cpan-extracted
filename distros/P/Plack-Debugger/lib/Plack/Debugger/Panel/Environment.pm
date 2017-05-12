package Plack::Debugger::Panel::Environment;

# ABSTRACT: Debug panel for inspecting $ENV

use strict;
use warnings;

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

use parent 'Plack::Debugger::Panel';

sub new {
    my $class = shift;
    my %args  = @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    $args{'title'}     ||= 'Environment';
    $args{'formatter'} ||= 'ordered_key_value_pairs';

    $args{'before'} = sub {
        my ($self, $env) = @_;
        # sorting keys creates predictable ordering ...
        $self->set_result([ map { $_ => $ENV{ $_ } } sort keys %ENV ]);
    };

    $class->SUPER::new( \%args );
}

1;

__END__

=pod

=head1 NAME

Plack::Debugger::Panel::Environment - Debug panel for inspecting $ENV

=head1 VERSION

version 0.03

=head1 DESCRIPTION

This is a L<Plack::Debugger::Panel> subclass that will display the 
state of the C<%ENV> for a given request.

=head1 ACKNOWLEDGMENT

This module was originally developed for Booking.com. With approval 
from Booking.com, this module was generalized and published on CPAN, 
for which the authors would like to express their gratitude.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
