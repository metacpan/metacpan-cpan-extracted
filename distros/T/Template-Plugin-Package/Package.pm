package Template::Plugin::Package;

=head1 NAME

Template::Plugin::Package - allow calling of class methods on arbitrary classes that do not accept the class name as their first argument.

=head1 SYNOPSIS

  [% USE foo = Package('Foo') %]
  [% foo.bar('arguments', 'to', 'bar') %]

=head1 DESCRIPTION

Template::Plugin::Package allows you to call functions in arbitrary
packages much like Template::Plugin::Class does, but the methods are called
without the package class name as the first parameter.

Use Template::Plugin::Package to call class methods that in normal Perl
code require '::' to call.

Use Template::Plugin::Class to call class methods that require '->' to
call.

=cut

use 5.010;
use warnings;
use strict;

use parent 'Template::Plugin';

our $VERSION = '1.00';

sub new {
    my $class = shift;
    my $context = shift;
    my $arg = shift;

    if ( ! eval "require $arg; 1;" ) {
        # Only ignore "Can't locate" errors from our eval require.
        # Other fatal errors (syntax etc) must be reported.
        (my $filename = $arg) =~ s!::!/!g;
        die $@ if $@ !~ /Can't locate \Q$filename.pm/;
    }
    no strict 'refs';
    if ( not scalar(%{"$arg\::"}) ) {
        die "Package \"$arg\" appears to have not been loaded. (Perhaps you need to 'use' the module, which defines that package first.)";
    }

    return bless \$arg, 'Template::Plugin::Package::Proxy';
}


package Template::Plugin::Package::Proxy;

use warnings;
use strict;

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my $class = ref $self;

    # Strip name of the proxy class, leaving just the function to call.
    my ($fn_name) = ($AUTOLOAD =~ /^$class\::(.*)/);

    # $$self evaluates to the name of the original class.
    # Get a reference to the function to call.
    my $fn = $$self->can( $fn_name ) or die "class $$self cannot $fn_name";

    # Call the function.
    return $fn->( @_ );
}


sub DESTROY {
    return;
}


=head1 SEE ALSO

L<Template::Plugin::Class>

=head1 COPYRIGHT & LICENSE

Copyright 2024 Andy Lester.

This library is free software; you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.

=head1 ACKNOWLEDGEMENTS

Template::Plugin::Package is taken directly from Template::Plugin::Class.

=head1 AUTHOR

Current maintainer: Andy Lester, C<< <andy at petdance.com> >>

=cut

1;
