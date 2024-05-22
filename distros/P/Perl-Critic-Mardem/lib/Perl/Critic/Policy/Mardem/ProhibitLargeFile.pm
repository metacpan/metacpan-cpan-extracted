package Perl::Critic::Policy::Mardem::ProhibitLargeFile;

use utf8;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.06';

use Readonly;

use Perl::Critic::Utils qw{:severities :data_conversion :classification};

use base 'Perl::Critic::Policy';

Readonly::Scalar my $EXPL => q{Consider refactoring};

sub default_severity
{
    return $SEVERITY_LOW;
}

sub default_themes
{
    return qw(maintenance);
}

sub applies_to
{
    return 'PPI::Document';
}

sub supported_parameters
{
    return (
        {   'name'            => 'line_count_limit',
            'description'     => 'The maximum line count allowed.',
            'default_string'  => '999',
            'behavior'        => 'integer',
            'integer_minimum' => 1,
        },
    );
}

sub violates
{
    my ( $self, $elem, undef ) = @_;

    my $filename = '__UNKNOWN__';

    {
        local $@;
        eval { $filename = $elem->filename() || $filename; };
        if ( $@ ) {
            # Note: warn ?
        }
    }

    my $s = $elem->serialize();
    if ( !defined $s || q{} eq $s ) {
        return;
    }

    my @matches = $s =~ /\n/og;
    my $lines   = scalar @matches;

    if ( $lines <= $self->{ '_line_count_limit' } ) {
        return;
    }

    my $desc = qq<File "$filename" with high line count ($lines)>;
    return $self->violation( $desc, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

Perl::Critic::Policy::Mardem::ProhibitLargeFile - large files as line count

=head1 DESCRIPTION

This Policy counts the lines within a Perl-File
(more precise the PPI::Document's)

=head1 CONFIGURATION

The maximum acceptable lines can be set with the C<line_count_limit>
configuration item. Any file (or given string) with higher line count
will generate a policy violation. The default is 999.

An example section for a F<.perlcriticrc>:

  [Mardem::ProhibitLargeFile]
  line_count_limit = 1

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Mardem>.

=head1 AUTHOR

Markus Demml, mardem@cpan.com

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2024, Markus Demml

This library is free software; you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system itself.
The full text of this license can be found in the LICENSE file included
with this module.

=cut
