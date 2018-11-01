package Perl5::Build::Warnings;
use 5.14.0;
use warnings;
our $VERSION = '0.03';
use Carp;
use IO::File;
use IO::Zlib;

=encoding utf8

=head1 NAME

Perl5::Build::Warnings - Parse make output for build-time warnings

=head1 SYNOPSIS

    use Perl5::Build::Warnings;

    my $self = Perl5::Build::Warnings->new( { file => '/path/to/make.log' } );

    my $hashref = $self->get_warnings_groups;

    my $arrayref = $self->get_warnings;

    $self->report_warnings_groups;

    $arrayref = $self->get_warnings_for_group('Wunused-variable');

    $arrayref = $self->get_warnings_for_source('op.c');


=head1 DESCRIPTION

Perl5::Build::Warnings is a module for use in studying build-time warnings
emitted by F<make> when building the Perl 5 core distribution from source
code.

=head2 Prerequisites

CPAN module F<Capture::Tiny> is used in this library's test suite, but not in
the module itself.  There are currently no other prerequisites not found in
the Perl 5 core distribution.

=head2 Assumptions

=head3 Logging of F<make> Output

The module assumes that the user has logged the output of F<make> (or
F<make test_prep> -- but not F<make test> -- or Windows equivalents) to a
plain-text file.  Something like:

    make test_prep 2>&1 > /path/to/make.log

The build log may be gzipped-compressed, I<e.g.:>

    make test_prep 2>&1 | gzip -c > /path/to/make.log.gz

=head3 Format for Build-Time Warnings

The module assumes that within such a logfile, warnings are recorded in this
format:

    op.c:5468:34: warning: argument ‘o’ might be clobbered by ‘longjmp’ or ‘vfork’ [-Wclobbered]

That is,

    <filename>:<line_numbert>:<character_number>: warning: <warning_description> [-<Wwarning_class>]

Note that the first field recorded, C<filename> may be either the basename of
a file in the top-level of the source code or a relative path to a file
beneath the top-level.

Note further that the last field recorded, the class of warning, starts with
an open bracket (C<[>), followed by a hyphen and an upper-case 'W' (C<-W>),
followed by the warning class, followed by a close bracket (C<]>).  In this
module we will ignore the open and close brackets and the hyphen, but we will
capture and report the upper-case 'W'.  Hence, whereas the log will record

    [-Wclobbered]

... this module will store and report that information as:

    Wclobbered

This is done in part because we may wish to use this data on the command-line
and the hyphen is likely to be significant to the shell.

=head1 METHODS

=head2 C<new()>

=over 4

=item * Purpose

Perl5::Build::Warnings constructor.

=item * Arguments

    $file = "./t/data/make.g++-8-list-util-fallthrough.output.txt";
    $self = Perl5::Build::Warnings->new( { file => $file } );

Single hash reference with one required element, C<file>, whose value is a
path to a file holding a log of F<make>'s output.

=item * Return Value

Perl5::Build::Warnings object.

=back

=cut

sub new {
    my ($class, $params) = @_;
    croak "Argument to constructor must be hashref"
        unless (ref($params) && ref($params) eq "HASH");
    croak "Argument to constructor must contain 'file' element"
        unless exists $params->{file};
    croak "Cannot locate $params->{file}" unless -f $params->{file};

    my $data = {};
    while (my ($k,$v) = each %{$params}) {
        $data->{$k} = $params->{$k};
    }

    my $init = _parse_log_for_warnings($data);

    return bless $init, $class;
}

sub _parse_log_for_warnings {
    my $data = shift;
    my @warnings = ();
    my %warnings_groups = ();
    my $IN;
    if ($data->{file} =~ m/\.gz/) {
        $IN = IO::Zlib->new($data->{file}, "rb");
    }
    else {
        $IN = IO::File->new($data->{file}, "r");
    }
    croak "Could not open filehandle to $data->file" unless defined $IN;
    while (my $l = <$IN>) {
        chomp $l;
        # op.c:5468:34: warning: argument ‘o’ might be clobbered by ‘longjmp’ or ‘vfork’ [-Wclobbered]
        next unless $l =~ m{^
            ([^:]+):
            (\d+):
            (\d+):\s+warning:\s+
            (.*?)\s+\[-
            (W.*)]$
        }x;
        my ($source_file, $line, $char, $warning_text, $warnings_group) =
            ($1, $2, $3, $4, $5);
        $warnings_groups{$warnings_group}++;
        push @warnings, {
            source      => $source_file,
            line        => $line,
            char        => $char,
            text        => $warning_text,
            group       => $warnings_group,
        };
    }
    $IN->close or croak "Unable to close handle after reading";
    $data->{warnings_groups} = \%warnings_groups;
    $data->{warnings} = \@warnings;
    return $data;
}

=head2 C<get_warnings_groups()>

=over 4

=item * Purpose

Identify the types of build-time warnings found in the F<make> log and the number of each such type.

=item * Arguments

    $hashref = $self->get_warnings_groups();

None.

=item * Return Value

Reference to a hash whose elements are keyed on warnings classes (I<e.g.,>
C<Wclobbered>).  The value of each element is the number of times such class
appeared in the file.

=back

=cut

sub get_warnings_groups {
    my $self = shift;
    return $self->{warnings_groups};
}

=head2 C<report_warnings_groups()>

=over 4

=item * Purpose

Pretty-print to STDOUT the information returned by C<get_warnings_groups>.

=item * Arguments

    $self->report_warnings_groups;

None.

=item * Return Value

Implicitly returns a Perl-true value.

=item *  Comment

The information reported will appear as below (2 leading whitespaces), but may
change in the future.

      Wcast-function-type                        6
      Wclobbered                                 2
      Wformat-overflow=                          2
      Wignored-qualifiers                        4
      Wimplicit-fallthrough=                    32
      Wmultistatement-macros                     1
      Wpragmas                                   3

=back

=cut

sub report_warnings_groups {
    my $self = shift;
    for my $w (sort keys %{$self->{warnings_groups}}) {
        say sprintf "  %-40s %3s" => $w, $self->{warnings_groups}{$w};
    }
}

=head2 C<get_warnings()>

=over 4

=item * Purpose

Generate a list of all warnings.

=item * Arguments

    $arrayref = $self->get_warnings();

=item * Return Value

Array reference, each element of which is a reference to a hash holding a parsing
of the elements of an individual warning.

=back

=cut

sub get_warnings {
    my $self = shift;
    return $self->{warnings};
}

=head2 C<get_warnings_for_group()>

=over 4

=item * Purpose

Get a list of all the warnings for one specified warnings group.

=item * Arguments

    $arrayref = $self->get_warnings_for_group("Wduplicate-decl-specifier");

String holding name of one group of warnings.  Each such string must begin with an upper-case C<W>.  As mentioned above, we drop the leading hyphen to avoid confusing the shell.

=item * Return Value

Array reference, each element of which is a reference to a hash holding a parsing
of the elements of an individual warning of the specified warnings group.

=back

=cut

sub get_warnings_for_group {
    my ($self, $wg) = @_;
    croak "Name of warnings group must begin with 'W'" unless $wg =~ m/^W/;
    croak "Warnings group '$wg' not found"
        unless $self->{warnings_groups}->{$wg};

    return [ grep { $_->{group} eq $wg } @{$self->{warnings}} ];
}

=head2 C<get_warnings_for_source()>

=over 4

=item * Purpose

Get a list of all the warnings generated from one specified source file.

=item * Arguments

    $arrayref = $self->get_warnings_for_source('op.c');

String holding name of one source file.  Note that there may be some ambiguity here.  Use with caution.

=item * Return Value

Array reference, each element of which is a reference to a hash holding a parsing
of the elements of an individual warning of the specified warnings source.

=back

=cut

sub get_warnings_for_source {
    my ($self, $sf) = @_;

    return [ grep { $_->{source} eq $sf } @{$self->{warnings}} ];
}

1;

=head1 BUGS

None reported so far.   The author prefers patches filed at
L<http://rt.cpan.org> rather than pull requests at github.

=head1 AUTHOR

    James E Keenan
    CPAN ID: JKEENAN
    jkeenan@cpan.org
    http://thenceforward.net/perl/modules/Perl5-Parse-MakeLog-Warnings

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

