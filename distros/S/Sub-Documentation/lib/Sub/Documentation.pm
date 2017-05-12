use 5.008;
use strict;
use warnings;

package Sub::Documentation;
our $VERSION = '1.100880';

# ABSTRACT: Collect documentation for subroutines
use Exporter qw(import);
our %EXPORT_TAGS =
  (util => [qw(add_documentation get_documentation search_documentation)],);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };

sub add_documentation {
    my %args = @_;
    my $had_errors;
    for (qw(package glob_type name type documentation)) {
        next if defined $args{$_};
        $had_errors++;
        warn "add_documentation() needs a '$_' key\n";
    }
    die "add_documentation() had errors, aborting\n" if $had_errors;
    my %interpolate = (
        p   => $args{package},
        '%' => '%',
    );
    $args{documentation} =~ s/%(.)/ $interpolate{$1} || "%$1" /ge;
    push our @doc, \%args;
}

sub get_documentation {
    our @doc;
    wantarray ? @doc : \@doc;
}

sub search_documentation {
    my %args = @_;
    my @found;
    for my $doc (our @doc) {
        my $match = 1;
        while (my ($key, $value) = each %args) {
            if (defined $doc->{$key}) {
                my $ref = ref $doc->{$key};
                if ($ref eq 'ARRAY') {
                    $match = 0 unless grep { $_ eq $value } @{ $doc->{$key} };
                } elsif ($ref eq '') {
                    $match = 0 unless $doc->{$key} eq $value;
                } else {
                    die "search_documentation(): key [$key] has unsupported value ref $ref\n";
                }
            } else {
                $match = 0;
            }
        }
        push @found, $doc if $match;
    }
    wantarray ? @found : \@found;
}
1;


__END__
=pod

=head1 NAME

Sub::Documentation - Collect documentation for subroutines

=head1 VERSION

version 1.100880

=head1 SYNOPSIS

    use Sub::Documentation 'add_documentation';

    my $pkg = __PACKAGE__;
    add_documentation(
        package       => $pkg,
        glob_type     => 'CODE',
        name          => 'new',
        type          => 'purpose',
        documentation => 'A constructor.'
    );
    add_documentation(
        package       => $pkg,
        glob_type     => 'SCALAR',
        name          => 'count',
        type          => 'purpose',
        documentation => 'Number of flurbles.'
    );

=head1 DESCRIPTION

This module provides support for generating documentation for your
subroutines.  It does not itself generate the documentation, but relies on
tools such as L<Pod::Weaver::Transformer::AddMethodAutoDoc> - which is a
plugin to L<Pod::Weaver> that is most likely used in conjunction with
L<Dist::Zilla> - to put the collected information to use.

Also see L<Sub::Documentation::Attributes>.

Modules that generate methods - such as L<Class::Accessor::Installer> - might
want to use this module. L<Class::Accessor::Complex>,
L<Class::Accessor::Constructor> and L<Class::Accessor::FactoryTyped> use
L<Class::Accessor::Installer> and so support this kind of auto-generated
documentation.

This functions are exported on request.

=head1 FUNCTIONS

=head2 add_documentation(%args)

Adds documentation. It depends on how you use the collected documentation
data, but most tools would use the following key/value pairs:

=over 4

=item package

The package for which to add documentation.

=item glob_type

The kind of symbol that is being documented: C<CODE>, C<SCALAR>, C<ARRAY>,
C<HASH> etc. The symbol name alone is insufficient to determine what is
being documented - does C<new> refer to the subroutine C<new()> or any of
the variables C<$new>, C@new> or C<%new>. Therefore you also need to pass
the glob type.

=item name

The symbol name for which to add documentation, that is, the subroutine name
or variable name.

=item type

The type of documentation to add. This might be C<purpose>, C<example> or the
like.

The documentation type is freely definable, but the code that actually
generates the documentation, for example,
L<Pod::Weaver::Section::CollectWithAutoDoc> needs to understand
these documentation types.

=item documentation

The actual documentation string.

=back

You can add any other key/value pairs which your documentation tool needs. For
example, L<Class::Accessor::Complex> generates helper methods for most
accessors, so in the documentation tool we would like to know which helper
method belongs to which main accessor. For example, for array accessors,
C<foo_push()>, C<shift_foo()> and C<foo_count()>, amongst others, all
belong to the C<foo> array accessor.

The documentation is stored in a list where each element is the has passed to
C<add_documentation()>.

=head2 get_documentation

Returns the documentation list. This can be used by modules that actually
generate the documentation to inspect which documentation has been defined.

=head2 search_documentation(%args)

Goes through the list of collected documentation and returns those entries
that match the key/value pairs given as the arguments.

For example,

    search_documentation(
        package   => 'Foo::Bar',
        glob_type => 'CODE',
        type      => 'examples',
    );

will return all entries with those key/value pairs.

If a string value in the arguments is compared to an array value in the entry,
it is sufficient for one of the array elements to be equal to the required
value. For example,

    search_documentation(
        name => 'clear_foo'
    );

will match this entry:

    add_documentation(
        name => [ qw(clear_foo foo_clear) ],
        ...
    );

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Sub-Documentation>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Sub-Documentation/>.

The development version lives at
L<http://github.com/hanekomu/Sub-Documentation/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

