package Test::Against::Dev::Sort;
use strict;
use 5.14.0;
our $VERSION = '0.12';
use Carp;
use Data::Dump ( qw| dd pp | );

=head1 NAME

Test::Against::Dev::Sort - Sort Perl 5 development and RC releases in logical order

=head1 SYNOPSIS

    use Test::Against::Dev::Sort;

    my $minor_version = 27;
    $self = Test::Against::Dev::Sort->new($minor_version);

    my @versions = ( qw|
        perl-5.27.10
        perl-5.28.0-RC4
        perl-5.27.0
        perl-5.27.9
        perl-5.28.0-RC1
        perl-5.27.11
    | );
    my $sorted_versions_ref = $self->sort_dev_and_rc_versions(\@versions);

    my $non_matches_ref = $self->get_non_matches();

    $self->dump_non_matches();

=head1 DESCRIPTION

Given a list of strings representing Perl 5 releases in a I<specific development cycle>, ...

    perl-5.27.10
    perl-5.28.0-RC4
    perl-5.27.0
    perl-5.27.9
    perl-5.28.0-RC1
    perl-5.27.11

... sort the list in I<logical> order.

By B<specific development cycle> is meant a series of development releases
like C<perl-5.27.0>, C<perl-5.27.1>, ... C<perl-5.27.11> (or perhaps
C<perl-5.27.12>) followed by RC (Release Candidate) releases beginning with
C<perl-5.28.0-RC1>, C<perl-5.28.0-RC2>, ..., but B<not> including production
releases (C<perl-5.28.0>), maintenance releases (C<perl-5.28.1>) or RCs for
maintainance releases (C<perl-5.28.1-RC1>).

By B<logical order> is meant:

=over 4

=item * Development releases:

                        5.27.1
    major version:      5
    minor version:        27
    patch version:           1

=over 4

=item * Have an odd minor version number greater than or equal to C<7>.

=item * Have a one- or two-digit patch version number starting at C<0>.

=back

=item * RC (Release Candidate) releases:

                        5.28.0-RC4
    major version:      5
    minor version:        28
    patch version:           0
    RC version:                  4

=over 4

=item * Have a minor version number which is even and one greater than the dev version number.

=item * Have a patch version number of C<0> (as we are not concerned with maintenance releases).

=item * Have a string in the format C<-RCx> following the patch version number, where C<x> is a one-digit number starting with C<1>.

=back

=back

For the example above, the desired result would be:

    perl-5.27.0
    perl-5.27.9
    perl-5.27.10
    perl-5.27.11
    perl-5.28.0-RC1
    perl-5.28.0-RC4

=head1 METHODS

=head2 c<new()>

=over 4

=item * Purpose

Test::Against::Dev::Sort constructor.

=item * Arguments

    my $minor_version = 27;
    $self = Test::Against::Dev::Sort->new($minor_version);

Odd-numbered integer, >= C<7>, representing the minor version for a Perl 5
monthly development release.

=item * Return Value

Test::Against::Dev::Sort object.

=back

=cut

sub new {
    my ($class, $minor_dev) = @_;
    croak "Minor version must be integer"
        unless (defined($minor_dev) and ($minor_dev =~ m/^\d+$/));
    croak "Minor version must be odd" unless $minor_dev % 2;
    croak "Minor version must be >= 7" unless $minor_dev >= 7;

    my $minor_rc = $minor_dev + 1;
    my $dev_pattern = qr/perl-5\.($minor_dev)\.(\d{1,2})/;
    my $rc_pattern  = qr/perl-5\.($minor_rc)\.(0)-RC(\d)/;
    my $data = {
        minor_dev   => $minor_dev,
        minor_rc    => $minor_rc,
        dev_pattern => $dev_pattern,
        rc_pattern  => $rc_pattern,
    };
    return bless $data, $class;
}

=head2 C<sort_dev_and_rc_versions()>

=over 4

=item * Purpose

=item * Arguments

    my @versions = ( qw|
        perl-5.27.10
        perl-5.28.0-RC4
        perl-5.27.0
        perl-5.27.9
        perl-5.28.0-RC1
        perl-5.27.11
    | );
    my $sorted_versions_ref = $self->sort_dev_and_rc_versions(\@versions);

Reference to an array holding a list of Perl version strings for development
or RC releases for a single annual development cycle (as denoted by the minor
version number passed to C<new()>).

=item * Return Value

Reference to an array holding that list sorted in logical order (as defined above).

=item * Comment

Any element in the arrayref passed as the argument which does not qualify is silently added to a list accessible via the C<get_non_matches()> and C<get_dump_matches()> methods.
=back

=cut

sub sort_dev_and_rc_versions {
    my ($self, $linesref) = @_;
    $self->{non_matches} = [];
    my %lines;
    for my $l (@$linesref) {
        my $rv = $self->_match($l);
        if (defined($rv)) {
           $lines{$l} = $rv;
        }
    }
    #dd(\%lines);
    my @sorted = sort {
        $lines{$a}{minor} <=> $lines{$b}{minor} ||
        $lines{$a}{patch} <=> $lines{$b}{patch} ||
        $lines{$a}{rc}    cmp $lines{$b}{rc}
    } keys %lines;
    return [ @sorted ];
}

sub _match {
    my ($self, $str) = @_;
    my ($minor, $patch, $rc) = ('') x 3;
    if ($str =~ m/^$self->{dev_pattern}$/) {
        ($minor, $patch) = ($1,$2);
    }
    elsif ($str =~ m/^$self->{rc_pattern}$/) {
        ($minor, $patch, $rc) = ($1,$2,$3);
    }
    else {
        push @{$self->{non_matches}}, $str;
        return;
    }
    return { minor => $minor, patch => $patch, rc => $rc };
}

=back

=head2 C<get_non_matches()>

=over 4

=item * Purpose

Identify those elements of the arrayref passed to
C<sort_dev_and_rc_versions()> which do not qualify as being the Perl version
string for a development or RC release in the annual development cycle passed
as an argument C<new()>.

=item * Arguments

    my $non_matches_ref = $self->get_non_matches();

None; all data needed is already inside the object.

=item * Return Value

Reference to an array holding a list of elements in the arrayref passed to
C<sort_dev_and_rc_versions()> which do not qualify as being the Perl version
string for a development or RC release in the annual development cycle passed
as an argument C<new()>.

=item * Comment

Not meaningful except when called after C<sort_dev_and_rc_versions()>.

=back

=cut

sub get_non_matches {
    my $self = shift;
    return $self->{non_matches} // [];
}

=head2 C<dump_non_matches()>

=over 4

=item * Purpose

Pretty-print to STDOUT the list returned by C<get_non_matches()>.

=item * Arguments

    my $non_matches_ref = $self->get_non_matches();

None; all data needed is already inside the object.

=item * Return Value

Perl true value.

=item * Comment

Not meaningful except when called after C<sort_dev_and_rc_versions()>.

=back

=cut

sub dump_non_matches {
    my $self = shift;
    dd($self->{non_matches});
    return 1;
}

1;
