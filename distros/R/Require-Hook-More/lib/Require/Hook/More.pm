package Require::Hook::More;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-01-04'; # DATE
our $DIST = 'Require-Hook-More'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Module::Installed::Tiny qw(module_source);
use Scalar::Util qw(blessed reftype);

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub Require::Hook::More::INC {
    my ($self, $filename) = @_;

    print STDERR __PACKAGE__ . ": entering handler\n" if $self->{debug};

    my @orig_inc = @INC;
    local @INC;
    for my $entry (@orig_inc) {
        my $ref = ref $entry;

        next if $ref && "$entry" eq "$self"; # skip ourself, otherwise infinite loop
        next if !$ref && $self->{skip_scalar};
        if ($ref) {
            next if blessed($entry) && $self->{skip_object};
            #my $reftype = reftype($entry);
            next if $ref eq 'SCALAR' && $self->{skip_scalarref};
            next if $ref eq 'GLOB'   && $self->{skip_globref};
            next if $ref eq 'CODE'   && $self->{skip_coderef};
        }
        push @INC, $entry;
    }

    my ($module_source, $path) = module_source($filename);

    my $offset_prepend = 0;
    if (defined $self->{prepend_code}) {
        $offset_prepend++ while $self->{prepend_code} =~ /\R/g;
        $module_source = $self->{prepend_code} . $module_source;
    }
    if (defined $self->{append_code}) {
        $module_source .= $self->{prepend_code};
    }

    $module_source = "# line ".(1 - $offset_prepend)." \"$path\"\n" . $module_source;

    eval $module_source;
    die if $@;
}

1;
# ABSTRACT: Load module like perl, with more options

__END__

=pod

=encoding UTF-8

=head1 NAME

Require::Hook::More - Load module like perl, with more options

=head1 VERSION

This document describes version 0.001 of Require::Hook::More (from Perl distribution Require-Hook-More), released on 2020-01-04.

=head1 SYNOPSIS

 {
     local @INC = (Require::Hook::More->new(
         # skip_scalar    => 1,     # optional, default is 0
         # skip_scalarref => 1,     # optional, default is 0
         # skip_globref   => 1,     # optional, default is 0
         # skip_coderef   => 1,     # optional, default is 0
         # skip_object    => 1,     # optional, default is 0
         # prepend_code   => "use re::engine::PCRE2",   # optional, default is none
         # append_code    => "1;",                      # optional, default is none
     ), @INC);

     require Foo::Bar;
     # ...
 }

=head1 DESCRIPTION

This require hook behaves like perl when loading modules from (the rest of the)
C<@INC>. Read C<require> in L<perlfunc> for more details. basically perl
supports having scalar (directory names), or scalarref, or globref (filehandle),
or coderef, or objects (blessed refs) in C<@INC>.

Additionally, this require hook provides some more options like skipping some
items in C<@INC>, adding code before or after the module's source code. Planned
features in the future: plugins (e.g. storage plugin like retrieving source code
from database, git repository [e.g. some branch or older revision], or remote
storage), code filtering or mangling, signature checking, other kind of code
checking, retry/fallback mechanism when code fails to be compiled, etc.

=for Pod::Coverage .+

=head1 METHODS

=head2 new

Usage:

 $hook = Require::Hook::More->new(%args);

Constructor. Known arguments:

=over

=item * debug => bool (default: 0)

If set to 1, will print debugging messages.

=item * skip_scalar    => bool (default: 0)

=item * skip_scalarref => bool (default: 0)

=item * skip_globref   => bool (default: 0)

=item * skip_coderef   => bool (default: 0)

=item * skip_object    => bool (default: 0)

=item * append_code    => str (default: undef)

Code to be added at the beginning of module source code. Can be used for example
to add pragma since the code will be executed in the same lexical scope as the
module source code.

=item * prepend_code   => str (default: undef)

Code to be added at the end of module source code.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Require-Hook-More>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Require-Hook-More>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Require-Hook-More>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Actual implementation of getting module source code from C<@INC> is provided by
L<Module::Installed::Tiny>.

Other C<Require::Hook::*>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
