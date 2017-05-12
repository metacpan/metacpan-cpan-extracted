package Pod::Weaver::Plugin::Eval;

our $DATE = '2016-10-14'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::Section';

use List::Util qw(first);

# regex
has include_modules => (
    is => 'rw',
    isa => 'Str',
);
has include_files => (
    is => 'rw',
    isa => 'Str',
);
has code => (
    is => 'rw',
    isa => 'Str',
);
#has _compiled_code => (
#    is => 'rw',
#);

sub weave_section {
    my ($self, $document, $input) = @_;

    # only compile code once
    if (!$self->{_compiled_code}) {
        my $code = $self->code;
        die "Please specify code" unless $code;
        $self->log(["compiling code ..."]);
        $code = "sub { $code }" unless $code =~ /^\s*sub\s*\{/s;
        $self->log(["code is: %s", $code]);
        eval "\$self->{_compiled_code} = $code";
        die "Can't compile code '$code': $@" if $@;
    }

    my $filename = $input->{filename} || 'file';

    # select file
    my ($package, $ext);
    if ($filename =~ m!^lib/(.+)\.(pod|pm)$!) {
        $package = $1;
        $ext = $2;
        $package =~ s!/!::!g;

    } else {
        $self->log(["skipped file %s (not a Perl module)", $filename]);
        return;
    }
    if (defined $self->include_files) {
        my $re = $self->include_files;
        eval { $re = qr/$re/ };
        $@ and die "Invalid regex in include_files: $re ($@)";
        unless ($filename =~ $re) {
            $self->log(["skipped file %s (doesn't match exclude_files)",
                              $filename]);
            return;
        }
    }
    if (defined $self->include_modules) {
        my $re = $self->include_modules;
        eval { $re = qr/$re/ };
        $@ and die "Invalid regex in include_modules: $re ($@)";
        unless ($package =~ $re) {
            $self->log (["skipped package %s (doesn't match exclude_modules)",
                         $package]);
            return;
        }
    }

    local @INC = ("lib", @INC);

    # run code
    $self->log(["running code on module %s", $package]);
    my %args = (
        args     => \@_,
        document => $document,
        input    => $input,
        filename => $filename,
        package  => $package,
        module   => $package, # synonym
    );
    $self->{_compiled_code}->($self, %args);
}

1;
# ABSTRACT: (DEPRECATED) Evaluate code

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::Eval - (DEPRECATED) Evaluate code

=head1 VERSION

This document describes version 0.03 of Pod::Weaver::Plugin::Eval (from Perl distribution Pod-Weaver-Plugin-Eval), released on 2016-10-14.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-Eval]
 include_modules = ^Foo::Bar$
 ;include_files  = REGEX
 code = sub { my ($self, %args)=@_; use Module::Load; load $args{module}; my $document = $args{document}; push @{$document->children}, ... }

=head1 DESCRIPTION

B<DEPRECATION NOTICE:> This module is deprecated in favor of
L<Pod::Weaver::Plugin::Run>.

This plugin evaluates Perl code specified in your weaver.ini (or dist.ini). It
can be used to do various stuffs that might be too trivial/short to build a
dedicated Pod::Weaver::Plugin for.

I first created this module to insert list of border styles and color themes
contained in C<%border_styles> package variable in
C<Text::ANSITable::BorderStyle::*> modules and C<%color_themes> variable in
C<Text::ANSITable::ColorTheme::*> modules.

Yes, it's a dirty (and ugly) hack. But it's quick :-)

=for Pod::Coverage weave_section

=head1 CONFIGURATION

=head2 include_files => STR

Value should be a regex, e.g. C</Foo/Bar/>.

=head2 include_modules => REGEX

Value should be a regex, e.g. C<^Foo::Bar$>.

=head2 code => STR

Should be something like:

 sub { my ($self, %args) = @_; ... }

C<sub {> and C<}> will be added if code does not have it. Code will be called
with C<%args> containing these keys:

=over

=item * filename => STR

=item * package => STR

=item * module => STR

Alias for C<package>.

=item * args => ARRAY

The original C<@_> passed to weave_section(). Note that weave_section() is
passed:

 ($self, $document, $input)

=item * document => OBJ

Document object passed to weave_section(). This is the output POD we are
building and this is what we're mostly interested in, usually. It can also be
retrieved from C<args>.

=item * input => OBJ

The input object passed to weave_section(). It contains information about the
input (original) document. Can also be retrieved from C<args>.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-Eval>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Pod-Weaver-Plugin-Eval>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-Eval>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Pod::Weaver>

L<Pod::Weaver::Plugin::Run>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
