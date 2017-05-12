package Scalar::Util::Instance;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.001';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub import {
    my $class  = shift;

    my $into = caller;
    foreach my $config(@_){
        my $as = $config->{as};
        if(!defined $as){
            require Carp;
            Carp::croak("You must define a predicate name by 'as'");
        }
        if($as !~ /::/){
            $as = $into . '::' . $as;
        }
        $class->generate_for($config->{for}, $as);
    }
    return;
}

1;
__END__

=head1 NAME

Scalar::Util::Instance - Generates and installs is-a predicates

=head1 VERSION

This document describes Scalar::Util::Instance version 0.001.

=head1 SYNOPSIS

    use Scalar::Util::Instance
        { for => 'Foo', as => 'is_a_Foo' },
        { for => 'Bar', as => 'is_a_Bar' },
    ;

    # ...
    if(is_a_Foo($_)){
        # ...
    }
    elsif(is_a_Bar($_)){
        # ...
    }

=head1 DESCRIPTION

Scalar::Util::Instance provides is-a predicates to look up
an is-a hierarchy for specific classes. This is an alternative to
C<< blessed($obj) && $obj->isa(...) >>, but is significantly faster than it.

=head1 INTERFACE

=head2 Utility functions

=head3 C<< Scalar::Util::Instance->generate_for(ClassName, ?PredicateName) >>

Generates an is-a predicate function for I<ClassName>.

If I<PredicateName> is specified, the method installs the generated function
as that name. Otherwise returns an anonymous CODE reference.

An is-a predicate is a function which is the same as the following:

    sub is_a_some_class {
        my($obj) = @_;
        return Scalar::Util::blessed($obj) && $obj->isa($ClassName);
    }

=head1 DEPENDENCIES

Perl 5.8.1 or later, and a C compiler.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 SEE ALSO

L<Scalar::Util>

L<Data::Util>

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Goro Fuji (gfx). Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
