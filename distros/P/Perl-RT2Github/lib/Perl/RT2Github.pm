package Perl::RT2Github;
use 5.14.0;
use warnings;
our $VERSION = '0.04';
use Carp;
use HTTP::Tiny;

sub new {
    my ($class, $args) = @_;
    $args = {} unless defined $args;
    croak "Argument to new() must be hashref" unless ref($args) eq 'HASH';
    my %valid_args = map {$_ => 1} (qw| timeout |);
    my @bad_args = ();
    while (my ($k,$v) = each(%{$args})) {
        push @bad_args, $k unless $valid_args{$k};
    }
    croak "Bad arguments to new(): @bad_args" if (@bad_args);
    $args->{timeout} ||= 120;

    my %data = (
        rt_stem => 'https://rt.perl.org/Public/Bug/Display.html?id=',
        gh_stem => 'https://github.com/perl/perl5/issues/',
        field => 'location',
        results => {},
        ua => HTTP::Tiny->new(max_redirect => 0, timeout => $args->{timeout}),
    );
    my $self = bless \%data, $class;
    return $self;
}

sub get_github_url {
    my ($self, $rt) = @_;
    croak "RT IDs were numeric" unless $rt =~ m/^\d+$/;
    my $rt_url = $self->{rt_stem} . $rt;

    my $location = $self->{ua}->get($rt_url)->{headers}{$self->{field}} || '';

    if ($location =~ m{^$self->{gh_stem}\d+$}) {
        $self->{results}->{$rt}->{github_url} = $location;
    }
    else {
        $self->{results}->{$rt}->{github_url} = undef;
    };
    return $self->{results}->{$rt}->{github_url};
}

sub get_github_urls {
    my ($self, @rt_ids) = @_;
    my %urls = ();
    for my $rt (@rt_ids) {
        my $gh_url = $self->get_github_url($rt);
        $urls{$rt} = $gh_url;
    }
    return \%urls;
}

sub get_github_id {
    my ($self, $rt) = @_;
    croak "RT IDs were numeric" unless $rt =~ m/^\d+$/;
    my $gh_url = $self->get_github_url($rt);
    my $gh_id;
    if (defined $gh_url) {
        ($gh_id) = $gh_url =~ m{^.*/(.*)$};
        $self->{results}->{$rt}->{github_id} = $gh_id;
    }
    else {
        $self->{results}->{$rt}->{github_id} = undef;
    }
    return $self->{results}->{$rt}->{github_id};
}

sub get_github_ids {
    my ($self, @rt_ids) = @_;
    my %ids = ();
    for my $rt (@rt_ids) {
        my $gh_id = $self->get_github_id($rt);
        if (defined $gh_id) {
            $self->{results}->{$rt}->{github_id} = $gh_id;
        }
        else {
            $self->{results}->{$rt}->{github_id} = undef;
        }
        $ids{$rt} = $gh_id;
    }
    return \%ids;
}

1;

=encoding utf8

=head1 NAME

Perl::RT2Github - Given RT ticket number, find corresponding Github issue

=head1 SYNOPSIS

    use Perl::RT2Github;

    my $self = Perl::RT2Github->new();

    my $github_url      = $self->get_github_url( 125740 );
    my $github_urls_ref = $self->get_github_urls( 125740, 133776 );

    my $github_id       = $self->get_github_id( 125740 );
    my $github_ids_ref  = $self->get_github_ids( 125740, 133776 );

=head1 DESCRIPTION

With the recent move of Perl 5 issue tracking from rt.cpan.org to github.com,
we need to be able to take a list of RT ticket numbers and look up the
corresponding github issue IDs and URLs.  This module is a first attempt at
doing so.

=head1 METHODS

=head2 C<new()>

=over 4

=item * Purpose

Perl::RT2Github constructor.

=item * Arguments

    my $self = Perl::RT2Github->new({ timeout => 120});

Hash reference; optional.  Currently, the only possible element in this hashref is
C<timeout>, whose value defaults to 120 seconds.

=item * Return Value

Perl::RT2Github object.

=back

=head2 C<get_github_url()>

=over 4

=item * Purpose

Get github.com URL for old RT ticket number.

=item * Arguments

    my $github_url = $self->get_github_url( 125740 );

A single rt.perl.org ticket ID, which must be all-numeric.

=item * Return Value

String holding URL for corresponding github.com issue.

=back

=head2 C<get_github_urls()>

=over 4

=item * Purpose

Get github.com URLs for multiple old RT ticket numbers.

=item * Arguments

    my $got = $self->get_github_urls( 125740, 200895 );

List of rt.perl.org ticket IDs.

=item * Return Value

Hash reference.

=back

=head2 C<get_github_id()>

=over 4

=item * Purpose

Get github.com issue number for old RT ticket number.

=item * Arguments

    my $github_id = $self->get_github_id( 125740 );

A single rt.perl.org ticket ID, which must be all-numeric.

=item * Return Value

String holding github.com issue number.

=back

=head2 C<get_github_ids()>

=over 4

=item * Purpose

Get github.com ID numbers for multiple old RT ticket numbers.

=item * Arguments

    my $github_ids_ref  = $self->get_github_ids( 125740, 133776 );

List of RT ticket numbers, which must each be all numeric.

=item * Return Value

Hash reference.

=back

=head1 BUGS

None so far.

=head1 CONTRIBUTING

The author prefers patches over pull requests on github.com.  To report bugs or
otherwise contribute to the development of this module, please attach a patch
(e.g., output of C<git format-patch>) to either (a) an email sent to
C<bug-Perl-RT2Github@rt.cpan.org>or use the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Perl-RT2Github>.

=head1 AUTHOR

    James E Keenan
    CPAN ID: JKEENAN
    jkeenan@cpan.org
    http://thenceforward.net/perl

=head1 ACKNOWLEDGMENTS

Implementation suggestions from Dagfinn Ilmari Mannsåker and Dan Book.
Correction of error in Changes from Graham Knop.
Patch to Makefile.PL from Mohammad S Anwar.

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

