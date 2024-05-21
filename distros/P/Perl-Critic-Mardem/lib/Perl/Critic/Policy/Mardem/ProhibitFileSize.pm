package Perl::Critic::Policy::Mardem::ProhibitFileSize;

use utf8;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.05';

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
        {   'name'            => 'size_count_limit',
            'description'     => 'The maximum bytes (or chars) allowed.',
            'default_string'  => '102400',                                  # 100 KB
            'behavior'        => 'integer',
            'integer_minimum' => 1,
        },
    );
}

sub violates
{
    my ( $self, $elem, undef ) = @_;

    my $filename = undef;

    {
        local $@;
        eval { $filename = $elem->filename() || undef; };
        if ( $@ ) {
            # Note: warn ?
        }
    }

    my $count = 0;
    my $mode  = '';

    if ( defined $filename && q{} ne $filename && -e -f -r $filename ) {
        $mode = 'byte';

        # if file available use byte size
        $count = -s _;

    }
    else {
        $filename = '__UNKNOWN__';
        $mode     = 'char';

        # no file = use char length
        my $s = $elem->serialize();

        # error ?
        if ( !defined $s ) {
            return;
        }

        $count = length $s;
    }

    # empty
    if ( 0 >= $count ) {
        return;
    }

    if ( $count <= $self->{ '_size_count_limit' } ) {
        return;
    }

    my $desc = qq<File "$filename" with high $mode count ($count)>;
    return $self->violation( $desc, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

Perl::Critic::Policy::Mardem::ProhibitFileSize

=head1 DESCRIPTION

This Policy checks the Perl-File Size in Bytes or the Content-Length (string)
if no file given. (more precise the PPI::Document's)

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
