package Perl::Critic::Policy::ClassHierarchies::ProhibitExplicitISA;

use 5.010001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use parent 'Perl::Critic::Policy';

our $VERSION = '1.156';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{@ISA used instead of "use parent"}; ## no critic (RequireInterpolation)
Readonly::Scalar my $EXPL => [ 360 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core maintenance pbp certrec ) }
sub applies_to           { return 'PPI::Token::Symbol'       }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    if( $elem eq q{@ISA} ) {  ## no critic (RequireInterpolation)
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return; #ok!
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::ClassHierarchies::ProhibitExplicitISA - Employ C<use parent> instead of C<@ISA>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Conway recommends employing C<use parent qw(Foo)> instead of the usual
C<our @ISA = qw(Foo)> because the former happens at compile time and
the latter at runtime.  The L<parent|parent> pragma also automatically loads
C<Foo> for you so you save a line of easily-forgotten code.

The original version of this policy recommended L<base|base> instead of
L<parent|parent>, which is now obsolete.

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2006-2022 Chris Dolan.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
