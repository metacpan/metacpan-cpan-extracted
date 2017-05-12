package Module::Functions;
use strict;
use warnings;
use 5.008005;
our $VERSION = '2.1.3';

use parent qw/Exporter/;

use Sub::Identify ();

our @EXPORT = qw(get_public_functions);
our @EXPORT_OK = qw(get_full_functions);

sub get_public_functions {
    my $klass = shift || caller(0);
    my @functions;
    no strict 'refs';
    my %class = %{"${klass}::"};
    while (my ($k, $v) = each %class) {
        next if $k =~ /^(?:BEGIN|UNITCHECK|INIT|CHECK|END|import)$/;
        next if $k =~ /^_/;
        next unless *{"${klass}::${k}"}{CODE};
        next if $klass ne Sub::Identify::stash_name( $klass->can($k) );
        push @functions, $k;
    }
    return @functions;
}

sub get_full_functions {
    my $klass = shift || caller(0);
    no strict 'refs';
    return keys %{"${klass}::"};
}

1;
__END__

=encoding utf8

=for stopwords catfile

=head1 NAME

Module::Functions - Get function list from package.

=head1 SYNOPSIS

    package My::Class;
    use parent qw/Exporter/;
    use Module::Functions;
    our @EXPORT = get_public_functions();

=head1 DESCRIPTION

Module::Functions is a library to get a public functions list from package.
It is useful to create a exportable function list.

=head1 METHODS

=head2 my @functions = get_public_functions()

=head2 my @functions = get_public_functions($package)

Get a public function list from the package.

If you don't pass the C<< $package >> parameter, the function use C<< caller(0) >> as a source package.

This function does not get a function, that imported from other package.

For example:

    package Foo;
    use File::Spec::Functions qw/catfile/;
    sub foo { }

In this case, return value of C<< get_public_functions('Foo') >> does not contain 'catfile'. Return value is C<< ('foo') >>.

=head3 RULES

This C<< get_public_functions >> removes some function names.

Rules are here:

=over 4

=item BEGIN, UNITCHECK, CHECK, INIT, and END are hidden.

=item 'import' method is hidden

=item function name prefixed by '_' is hidden.

=back

=head2 my @functions = get_full_functions();

=head2 my @functions = get_full_functions($package)

This function get ALL functions.
ALL means functions that were imported from other packages.
And included specially named functions(BEGIN , UNITCHECK , CHECK , INIT and END).
Of course, included also private functions( ex. _foo ).

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

L<Exporter::Auto> have same feature of this module, but it stands on very tricky thing.

L<Class::Inspector> finds the function list. But it does not check the function defined at here or imported from other package.

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
