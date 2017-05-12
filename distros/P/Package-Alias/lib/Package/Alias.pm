package Package::Alias;
{
  $Package::Alias::VERSION = '0.13';
}
# ABSTRACT: Alias one namespace as another

use strict qw/vars subs/;
use Carp;
use 5.006; # for INIT

our $BRAVE;
our $DEBUG;

sub alias {
    my $class = shift;
    my %args  = @_;

    while (my ($alias, $orig) = each %args) {
        if (scalar keys %{$alias . "::" } && ! $BRAVE) {
            carp "Cowardly refusing to alias over '$alias' because it's already in use";
            next;
        }

        *{$alias . "::"} = \*{$orig . "::"};
        print STDERR __PACKAGE__ . ": '$alias' is now an alias for '$orig'\n"
            if $DEBUG;
    }
}

sub import {
    my $class = shift;
    my %args  = @_;

    while (my ($alias, $orig) = each %args) {
        my ($alias_pm, $orig_pm) = ($alias, $orig);
        foreach ($alias_pm, $orig_pm) {
            s/::/\//g;
            $_ .= '.pm';
        }

        next if exists $INC{$alias_pm};
        my $caller = caller;
        eval "{package $caller; use $orig;}";
        confess $@ if $@;
        $INC{$alias_pm} = $INC{$orig_pm};
    }

    alias($class, @_);
}

1;

__END__

=pod

=head1 NAME

Package::Alias - Alias one namespace as another

=head1 VERSION

version 0.13

=head1 SYNOPSIS

  use Package::Alias 
      Foo    => 'main',
      'P::Q' => 'Really::Long::Package::Name',
      Alias  => 'Existing::Namespace';

=head1 DESCRIPTION

This module aliases one package name to another. After running the
SYNOPSIS code,  C<@INC> (shorthand for C<@main::INC>) and C<@Foo::INC>
reference the same memory, likewise for the other pairings.

Modules not currently loaded into %INC will be used automatically. e.g.,

  use Package::Alias HMS => 'Hash::Merge::Simple'; # automatically runs 'use Hash::Merge::Simple;'

To facilitate some crafty slight of hand, the above will also
C<use P::Q> if it's not already loaded, and tell Perl that
C<Really::Long::Package::Name> is loaded. In some rare cases
such as C<Mouse>, additional trickery may be required; see L<"Working with Mouse">.

=head1 GLOBALS

Package::Alias won't alias over a namespace if it's already in use. 
That's not a fatal error - you'll see a warning and flow will continue. 
You can change that cowardly behaviour this way:

  # Make Bar like Foo, even if Bar is already in use.

  BEGIN { $Package::Alias::BRAVE = 1 }

  use Package::Alias Bar => 'Foo'; # The old Bar was just clobbered

=head1 METHODS

=head2 alias

Underlying class method that aliases one namespace to another.

  Package::Alias->alias($aliased_namespace, $original_namespace);

=head1 CAVEATS

To be strict-compliant, you'll need to quote any packages on the
left-hand side of a => if the namespace has colons. Packages on the
right-hand side all have to be quoted. This is documented as
L<perlop/"Comma Operator">.

=head1 NOTES

Chip Salzenberg says that it's not technically feasible to perform
runtime namespace aliasing.  At compile time, Perl grabs pointers to
functions and global vars.  Those pointers aren't updated if we alias
the namespace at runtime.

=head2 Working with Mouse

  BEGIN {
    use Package::Alias Moose => Mouse;

    # Make Mouse's finicky internal checks happy...
    Moose::Exporter->setup_import_methods(exporting_package => 'Moose',

        # Alas the defaults live in Mouse...
        as_is => [qw(
                extends with
                has
                before after around
                override super
                augment  inner
            ),
            \&Scalar::Util::blessed,
            \&Carp::confess,
        ],
    );

=head1 SEE ALSO

L<aliased>
L<namespace>
L<Devel::Symdump>

=head1 AUTHORS

=over 4

=item *

Joshua Keroes <joshua@cpan.org>

=item *

Jerrad Pierce <jpierce@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Joshua Keroes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
