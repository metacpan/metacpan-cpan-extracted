package Perl::Critic::Policy::Subroutines::ProhibitExportingUndeclaredSubs;

use strict;
use warnings;
use Carp qw(croak);
use English qw(-no_match_vars);
use base 'Perl::Critic::Policy';

use Perl::Critic::Utils qw(
    :severities
    &hashify
    &policy_short_name
);

use Perl::Critic::StricterSubs::Utils qw(
    &find_declared_constant_names
    &find_declared_subroutine_names
    &find_exported_subroutine_names
);

#-----------------------------------------------------------------------------

our $VERSION = 0.06;

#-----------------------------------------------------------------------------

sub supported_parameters { return }
sub default_severity     { return $SEVERITY_HIGH          }
sub default_themes       { return qw( strictersubs bugs ) }
sub applies_to           { return 'PPI::Document'         }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;

    my @exported_sub_names = ();
    eval {
        @exported_sub_names = find_exported_subroutine_names( $doc );
        1;
    } or do {

        if ( $EVAL_ERROR =~ m/Found \s multiple/mxs ) {
            my $pname = policy_short_name(__PACKAGE__);
            my $fname = $doc->filename() || 'unknown';
            warn qq{$pname: $EVAL_ERROR in file "$fname"\n};
            return;
        }

    };

    my @declared_sub_names = find_declared_subroutine_names( $doc );
    my @declared_constants = find_declared_constant_names( $doc );
    my %declared_sub_names = hashify( @declared_sub_names,
                                      @declared_constants );

    my @violations = ();
    for my $sub_name ( @exported_sub_names ) {
        if ( not exists $declared_sub_names{ $sub_name } ){
            my $desc = qq{Subroutine "$sub_name" is exported but not declared};
            my $expl = qq{Perhaps you forgot to define "$sub_name"};
            push @violations, $self->violation( $desc, $expl, $doc );
        }
    }

    return @violations;
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitExportingUndeclaredSubs

=head1 AFFILIATION

This policy is part of L<Perl::Critic::StricterSubs|Perl::Critic::StricterSubs>.

=head1 DESCRIPTION

This Policy checks that any subroutine listed in C<@EXPORT> or C<@EXPORT_OK>
is actually defined in the current file.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  The full text of this license can be found in
the LICENSE file included with this module.

=cut


##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
