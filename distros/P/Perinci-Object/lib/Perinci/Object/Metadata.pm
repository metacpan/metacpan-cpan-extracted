package Perinci::Object::Metadata;

our $DATE = '2021-01-02'; # DATE
our $VERSION = '0.311'; # VERSION

use 5.010;
use strict;
use warnings;

# BEGIN COPY-PASTE FROM String::Trim::More
sub __trim_blank_lines {
    local $_ = shift;
    return $_ unless defined;
    s/\A(?:\n\s*)+//;
    s/(?:\n\s*){2,}\z/\n/;
    $_;
}
# END COPY-PASTE

sub new {
    my ($class, $meta) = @_;
    $meta //= {};
    my $obj = \$meta;
    bless $obj, $class;
}

sub v {
    my $self = shift;
    ${$self}->{v} // 1.0;
}

sub type {
    die "BUG: type() must be subclassed";
}

sub as_struct {
    my $self = shift;
    ${$self};
}

sub langprop {
    my $self = shift;
    my $opts;
    if (ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    my $prop = shift;

    my $deflang = ${$self}->{default_lang} // "en_US";
    my $olang   = $opts->{lang} || $ENV{LANGUAGE} || $ENV{LANG} || $deflang;
    $olang =~ s/\W.+//; # change "en_US.UTF-8" to "en_US"
    $olang = "en_US" if $olang eq 'C';
    (my $olang2 = $olang) =~ s/\A([a-z]{2})_[A-Z]{2}\z/$1/; # change "en_US" to "en"
    my $mark    = $opts->{mark_different_lang} // 1;
    #print "deflang=$deflang, olang=$olang, mark_different_lang=$mark\n";

    my @k;
    if ($olang eq $deflang) {
        @k = ([$olang, $prop, 0]);
    } else {
        @k = (
            [$olang, "$prop.alt.lang.$olang", 0],
            ([$olang2, "$prop.alt.lang.$olang2", 0]) x !!($olang2 ne $olang),
            [$deflang, $prop, $mark],
        );
    }

    my $v;
  GET:
    for my $k (@k) {
        #print "k=".join(", ", @$k)."\n";
        $v = ${$self}->{$k->[1]};
        if (defined $v) {
            if ($k->[2]) {
                my $has_nl = $v =~ s/\n\z//;
                $v = "{$olang|$k->[0] $v}" . ($has_nl ? "\n" : "");
            }
            $v = __trim_blank_lines($v);
            last GET;
        }
    }

    if (@_) {
        # set value
        ${$self}->{$k[0][1]} = $_[0];
    }

    $v;
}

sub name {
    my $self = shift;
    my $opts;
    if (@_ && ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    $self->langprop($opts, "name", @_);
}

sub caption {
    my $self = shift;
    my $opts;
    if (@_ && ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    $self->langprop($opts, "caption", @_);
}

sub summary {
    my $self = shift;
    my $opts;
    if (@_ && ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    $self->langprop($opts, "summary", @_);
}

sub description {
    my $self = shift;
    my $opts;
    if (@_ && ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    $self->langprop($opts, "description", @_);
}

1;
# ABSTRACT: Base class for Perinci::Object metadata classes

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Object::Metadata - Base class for Perinci::Object metadata classes

=head1 VERSION

This document describes version 0.311 of Perinci::Object::Metadata (from Perl distribution Perinci-Object), released on 2020-01-02.

=head1 METHODS

=head2 new => obj

Constructor.

=head2 v => float

Get version.

=head2 as_struct => hash

Get underlying data structure.

=head2 type => str

Return type (e.g. C<function>, C<package>).

=head2 langprop([ \%opts, ]$prop[, $new_value])

Get or set property value in the specified language (i.e., either in C<prop> or
C<prop.alt.lang.XXX> properties).

Known options:

=over 4

=item * lang => STR

Defaults to metadata's C<default_lang> (which in turns default to C<en_US> if
unspecified).

=item * mark_different_lang => BOOL (defaults to 1)

If set to true, text with different language than the language requested will be
marked, e.g. C<"I love you"> requested in Indonesian language where the value
for that language is unavailable will result in C<"{en_US I love you}"> being
returned.

=back

=head2 name([ $new_value ]) => $value

Get or set C<name> property. Will call C<langprop()>.

=head2 summary([ $new_value ]) => $value

Get or set C<summary> property. Will call C<langprop()>.

=head2 description([ $new_value ]) => $value

Get or set C<description> property. Will call C<langprop()>.

=head2 caption([ $new_value ]) => $value

Get or set C<caption> property. Will call C<langprop()>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Object>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Object>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Perinci-Object/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
