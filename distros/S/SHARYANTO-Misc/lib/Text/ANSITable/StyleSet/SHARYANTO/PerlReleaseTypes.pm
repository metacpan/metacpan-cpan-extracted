package Text::ANSITable::StyleSet::SHARYANTO::PerlReleaseTypes;

# for use in my list-perl-releases script

use 5.010001;
use Moo;
use namespace::clean;

use List::MoreUtils ();

has cpan_bgcolor    => (is => 'rw');
has cpan_fgcolor    => (is => 'rw');
has noncpan_bgcolor => (is => 'rw', default=>sub { '003300' });
has noncpan_fgcolor => (is => 'rw');
has rename_bgcolor  => (is => 'rw', default=>sub { '330000' });
has rename_fgcolor  => (is => 'rw');

our $VERSION = '0.01'; # VERSION
our $DATE = '2014-04-23'; # DATE

sub summary {
    "Set foreground and/or background color for different Perl releases";
}

sub apply {
    my ($self, $table) = @_;

    $table->add_cond_row_style(
        sub {
            my ($t, %args) = @_;
            my %styles;

            my $r = $args{row_data};
            my $cols = $t->columns;

            my $repo_idx = List::MoreUtils::firstidx(
                sub {$_ eq 'repo'}, @$cols);
            my $oldname_idx = List::MoreUtils::firstidx(
                sub {$_ eq 'oldname'}, @$cols);

            if ($oldname_idx >= 0 && $r->[$oldname_idx]) {
                $styles{bgcolor} = $self->rename_bgcolor
                    if defined $self->rename_bgcolor;
                $styles{fgcolor} = $self->rename_fgcolor
                    if defined $self->rename_fgcolor;
                goto DONE;
            }

            if ($repo_idx >= 0 && $r->[$repo_idx] eq 'cpan') {
                $styles{bgcolor} = $self->cpan_bgcolor
                    if defined $self->cpan_bgcolor;
                $styles{fgcolor}=$self->cpan_fgcolor
                    if defined $self->cpan_fgcolor;
            } elsif ($repo_idx >= 0 && $r->[$repo_idx] ne 'cpan') {
                $styles{bgcolor} = $self->noncpan_bgcolor
                    if defined $self->noncpan_bgcolor;
                $styles{fgcolor} = $self->noncpan_fgcolor
                    if defined $self->noncpan_fgcolor;
            }

          DONE:
            \%styles;
        },
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::ANSITable::StyleSet::SHARYANTO::PerlReleaseTypes

=head1 VERSION

version 0.01

=head1 RELEASE DATE

2014-04-23

=for Pod::Coverage ^(summary|apply)$

=head1 ATTRIBUTES

=head2 cpan_bgcolor

=head2 cpan_fgcolor

=head2 noncpan_bgcolor

=head2 noncpan_fgcolor

=head2 rename_bgcolor

=head2 rename_fgcolor

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SHARYANTO-Misc>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-SHARYANTO-Misc>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SHARYANTO-Misc>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
