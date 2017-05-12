package Parse::File::Metadata;
use strict;
our $VERSION = '0.07';
use Carp;
use Scalar::Util qw( reftype );

=head1 NAME

Parse::File::Metadata - For plain-text files that contain both metadata and data records, parse metadata first

=head1 SYNOPSIS

     use Parse::File::Metadata;

    $metaref = {};
    @rules = (
        {
            rule => sub { exists $metaref->{d}; },
            label => q{'d' key must exist},
        },
        {
            rule => sub { $metaref->{d} =~ /^\d+$/; },
            label => q{'d' key must be non-negative integer},
        },
        {
            rule => sub { exists $metaref->{f}; },
            label => q{'f' key must exist},
        },
    );

    $self = Parse::File::Metadata->new( {
        file            => 'path/to/myfile',
        header_split    => '\s*=\s*',
        metaref         => $metaref,
        rules           => \@rules,
    } );

    $dataprocess = sub { my @fields = split /,/, $_[0], -1; print "@fields\n"; };

    $self->process_metadata_and_proceed( $dataprocess );

    $self->process_metadata_only();

    $metadata_out = $self->get_metadata();

    $exception = $self->get_exception();

=head1 DESCRIPTION

This module is useful when you have to parse a plain-text file that meets the
following conditions:

=over 4

=item *

The file consists of two types of records:

=over 4

=item *

A I<header> section consisting of key-value pairs which constitute, in some
sense, I<metadata>.

=item *

A I<body> section consisting mainly or entirely of I<data> records, which may be either delimited or fixed-width.

=item *

The header and the body are separated by one or more empty records.

=back

=item *

Your program must parse the metadata first, then make a decision on the basis
of the metadata whether to proceed with parsing of the data.  The metadata may
or may not be used in the parsing of the data.

=back

=head2 Example

Below is a plain-text file in which the header consists of key-value pairs
delimited by C<=> signs.  The key is the to the left of the first delimiter.
Everything to the right is part of the value (including any additional
delimiter characters).

The body consists of comma-delimited strings.  Whether in the body or the
header, comments begin with a C<#> sign and are ignored.

    # comment
    a=alpha
    b=beta,charlie,delta
    c=epsilon	zeta	eta
    d=1234567890
    e=This is a string
    f=,
    
    some,body,loves,me
    I,wonder,wonder,who
    could,it,be,you

Suppose you are told that you should proceed to parse the body if and only if
the following conditions are met in the header:

=over 4

=item * There must be a metadata element keyed on C<d>.

=item * The value of metadata element C<d> must be a non-negative integer.

=item * There must be a metadata element keyed on C<f>.

=back

This file would meet all three criteria and the program would proceed to parse
the three data records.

If, however, metadata element C<f>
were commented out:

    #f=,

the file would no longer meet the criteria and the program would cease before
parsing the data records.

=head1 METHODS

=head2 C<new()>

=over 4

=item * Purpose

Parse::File::Metadata constructor.   Validates input.

=item * Arguments

    $self = Parse::File::Metadata->new( {
        file            => 'path/to/myfile',
        header_split    => '\s*=\s*',
        metaref         => $metaref,
        rules           => \@rules,
    } );

Single hash reference.  Hash has the following elements:

=over 4

=item * C<file>

Path, relative or absolute, to the file needing parsing.

=item * C<header_split>

Hard-quoted string holding a Perl 5 regex to be used for parsing metadata
records.

=item * C<metaref>

Empty hash-reference.

=item * C<rules>

Reference to an array of hashrefs.  Each such hashref has two elements:

=over 4

=item * C<rule>

Reference to a subroutine describing a criterion which the header must pass
before parsing of the body begins.  The subroutine returns a true value when
the criterion is met and an undefined value when the criterion is not met.

=item * C<label>

A human-friendly string which will be used to populate exceptions if the
criteria are not met.

=back

The rules are applied in the order specified in the array.

=back

=item * Return Value

Parse::File::Metadata object.

=back

=cut

sub new {
    my ($class, $args) = @_;
    croak "Metadata hash must start out empty: $!"
        unless ( reftype($args->{metaref}) eq 'HASH' and
            ! keys %{ $args->{metaref} } );
    croak "Rules must be in array ref: $!"
        unless ( reftype($args->{rules}) eq 'ARRAY' );

    my $self = bless $args, $class;

    return $self;
}

=head2 C<process_metadata_and_proceed()>

=over 4

=item * Purpose

Process metadata rows found in file header and test the resulting hash against
the criteria specified in the rules.  If all criteria are met, proceed to
parse the data rows with the subroutine specified as argument to this method.

=item * Arguments

    $dataprocess = sub { my @fields = split /,/, $_[0], -1; print "@fields\n"; };

    $self->process_metadata_and_proceed( $dataprocess );

=item * Return Values

None.  Use C<get_metadata()> and C<get_exception()> methods to obtain that
data.

=back

=cut

sub process_metadata_and_proceed {
    my ($self, $dataprocess) = @_;
    croak "Must define subroutine for processing data rows: $!"
        unless ( defined($dataprocess) and reftype($dataprocess) eq 'CODE' );

    $self->_process_metadata_engine($dataprocess);
}

sub _process_metadata_engine {
    my $self = shift;
    my $dataprocess = shift || undef;
    my $header_seen;
    my $exception = [];
    open my $FILE, '<', $self->{file}
        or croak "Unable to open file for reading";
    THISFILE: while (my $l = <$FILE>) {
        next if $l =~ /^#/;
        $l =~ s/[\r\n]+$//g;
        if (! $header_seen) {
            if ($l eq '') {
                $header_seen++;
            }
            else {
                next unless $l =~ /^(.+?)$self->{header_split}(.*)$/;
                my ($k, $v) = ($1, $2);
                $self->{metaref}->{$k} = $v;
            }
        }
        else {
            foreach my $r ( @{ $self->{rules} } ) {
                unless ( &{ $r->{rule} } ) {
                    push @{$exception}, $r->{label};
                }
            }
            last THISFILE if scalar @{$exception};
            &{ $dataprocess }($l)
                if defined $dataprocess;
        }
    }
    close $FILE or croak "Unable to close";
    $self->{exception} = $exception;
};

=head2 C<process_metadata_only()>

=over 4

=item * Purpose

Same as L<process_metadata_and_proceed>, except that it returns before
beginning any processing of the data records.

=item * Arguments

    $self->process_metadata_only();

=item * Return Values

None.

=back

=cut

sub process_metadata_only {
    my $self = shift;
    $self->_process_metadata_engine();
}

=head2 C<get_metadata()>

=over 4

=item * Purpose

Access metadata in file's header section.

=item * Arguments

    $metadata_out = $self->get_metadata()

None.

=item * Return Values

Hash of metadata found in file's header.

=back

=cut

sub get_metadata {
    my $self = shift;
    return $self->{metaref};
}

=head2 C<get_exception()>

=over 4

=item * Purpose

Access reasons, if any, why file failed to meet specified criteria.

=item * Arguments

    $exception = $self->get_exception()

None.

=item * Return Values

Reference to an array holding lists of C<label>s for rules on which the
metadata fails.

=back

=cut

sub get_exception {
    my $self = shift;
    return $self->{exception};
}

=head1 SUPPORT

L<https://rt.cpan.org>

=head1 AUTHOR

    James E Keenan
    CPAN ID: jkeenan
    Perl Seminar NY
    jkeenan@cpan.org
    http://thenceforward.net/perl/modules/Parse-File-Metadata

=head1 COPYRIGHT

Copyright 2010 James E Keenan

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut
