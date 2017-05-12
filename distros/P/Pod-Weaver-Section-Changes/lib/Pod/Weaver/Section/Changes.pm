package Pod::Weaver::Section::Changes;

our $DATE = '2015-04-01'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::Section';

use Config::INI::Reader;
use CPAN::Changes;
use Pod::Elemental;
use Pod::Elemental::Element::Nested;

# regex
has exclude_modules => (
    is => 'rw',
    isa => 'Str',
);
has exclude_files => (
    is => 'rw',
    isa => 'Str',
);

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename} || 'file';

    # try to find main package name, from dist.ini. there should be a better
    # way.
    my $ini = Config::INI::Reader->read_file('dist.ini');
    my $main_package = $ini->{_}{name};
    $main_package =~ s/-/::/g;

    # guess package name from filename
    my $package;
    if ($filename =~ m!^lib/(.+)\.(?:pm|pod)$!) {
        $package = $1;
        $package =~ s!/!::!g;
    } else {
        $self->log_debug(["skipped file %s (not a Perl module)", $filename]);
        return;
    }

    if ($package ne $main_package) {
        $self->log_debug(["skipped file %s (not main module)", $filename]);
        return;
    }

    if (defined $self->exclude_files) {
        my $re = $self->exclude_files;
        eval { $re = qr/$re/ };
        $@ and die "Invalid regex in exclude_files: $re";
        if ($filename =~ $re) {
            $self->log_debug(["skipped file %s (matched exclude_files)", $filename]);
            return;
        }
    }
    if (defined $self->exclude_modules) {
        my $re = $self->exclude_modules;
        eval { $re = qr/$re/ };
        $@ and die "Invalid regex in exclude_modules: $re";
        if ($package =~ $re) {
            $self->log_debug(["skipped package %s (matched exclude_modules)", $package]);
            return;
        }
    }

    my $changes;
    for my $f (qw/Changes CHANGES ChangeLog CHANGELOG/) {
        if (-f $f) {
            $changes = CPAN::Changes->load($f);
            last;
        }
    }

    unless ($changes) {
        $self->log_debug(["skipped adding CHANGES section to %s (no valid Changes file)", $filename]);
        return;
    }

    my @content;
    for my $rel (reverse $changes->releases) {
        my @rel_changes;
        my $rchanges = $rel->changes;
        for my $cgrp (sort keys %$rchanges) {
            push @rel_changes, Pod::Elemental::Element::Pod5::Command->new({
                command => 'over',
                content => '4',
            });
            for my $c (@{ $rchanges->{$cgrp} }) {
                push @rel_changes, Pod::Elemental::Element::Nested->new({
                    command => 'item',
                    content => '*',
                    children => [Pod::Elemental::Element::Pod5::Ordinary->new({
                        content => ($cgrp ? "[$cgrp] " : "") . $c,
                    })]
                });
            }
            push @rel_changes, Pod::Elemental::Element::Pod5::Command->new({
                command => 'back',
                content => '',
            });
        }

        push @content, Pod::Elemental::Element::Nested->new({
            command => 'head2',
            content => "Version " . $rel->version . " (". $rel->date . ")",
            children => \@rel_changes,
        });
    }

    push @{ $document->children },
        Pod::Elemental::Element::Nested->new({
            command  => 'head1',
            content  => 'CHANGES',
            children => \@content,
        });

    $self->log(["added CHANGES section to %s", $filename]);
}

1;
# ABSTRACT: Add a CHANGES POD section

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Changes - Add a CHANGES POD section

=head1 VERSION

This document describes version 0.04 of Pod::Weaver::Section::Changes (from Perl distribution Pod-Weaver-Section-Changes), released on 2015-04-01.

=head1 SYNOPSIS

In your C<weaver.ini>:

 [Changes]

=head1 DESCRIPTION

This plugin inserts C<Changes> entries to POD section CHANGES. I used to think
this is a good idea because I can look at the module's Changes history right
from the POD. I've since repented :-)

Changes is parsed using L<CPAN::Changes> and markup in text entries are
currently assumed to be POD too.

=for Pod::Coverage weave_section

=head1 SEE ALSO

L<Pod::Weaver>

L<CPAN::Changes>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Section-Changes>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Section-Changes>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Section-Changes>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CHANGES

=head2 Version 0.04 (2015-04-01)

=over 4

=item *

Use the weaver plugin to self, for testing.

=item *

Remove Moose::Autobox and Log::Any.

=back

=head2 Version 0.03 (2014-04-01)

=over 4

=item *

No functional changes.

=item *

[build] Fix incomplete list of dependencies [RT#103181].

=back

=head2 Version 0.02 (2012-07-31)

=over 4

=item *

Add config: exclude_files & exclude_modules.

=back

=head2 Version 0.01 (2012-07-31)

=over 4

=item *

First release.

=back

=cut
