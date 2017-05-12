package Rose::ObjectX::CAF::MethodMaker;
use warnings;
use strict;
use Carp;
use base qw( Rose::Object::MakeMethods::Generic );
my $Debug = 0;    #$ENV{PERL_DEBUG};

our $VERSION = '0.03';

=head1 NAME

Rose::ObjectX::CAF::MethodMaker - Class::Accessor::Fast compatability for Rose::Object

=head1 SYNOPSIS

 # see Rose::ObjectX::CAF
 
=head1 DESCRIPTION

This is a subclass of Rose::Object::MakeMethods::Generic. See those docs
and those of Rose::ObjectX::CAF.

=head1 METHODS

=head2 scalar

Overrides the Rose::Object::MakeMethods::Generic method of the same name
to provide read-only accessors like mk_ro_accessors().

=cut

# extend for mk_ro_accessors support
sub scalar {
    my ( $class, $name, $args ) = @_;

    my %methods;

    my $key       = $args->{'hash_key'}  || $name;
    my $interface = $args->{'interface'} || 'get_set';

    if ( $interface eq 'get_set_init' ) {
        my $init_method = $args->{'init_method'} || "init_$name";

        $methods{$name} = sub {
            return $_[0]->{$key} = $_[1] if ( @_ > 1 );

            return defined $_[0]->{$key}
                ? $_[0]->{$key}
                : ( $_[0]->{$key} = $_[0]->$init_method() );
        };
    }
    elsif ( $interface eq 'get_set' ) {
        if ( $Rose::Object::MakeMethods::Generic::Have_CXSA
            && !$ENV{'ROSE_OBJECT_NO_CLASS_XSACCESOR'} )
        {
            $methods{$name} = {
                make_method => sub {
                    my ( $name, $target_class, $options ) = @_;

                    $Debug
                        && warn
                        "Class::XSAccessor make method ($name => $key) in $target_class\n";

                    Class::XSAccessor->import(
                        accessors => { $name => $key },
                        class     => $target_class,
                        replace => $options->{'override_existing'} ? 1 : 0
                    );
                },
            };
        }
        else {
            $methods{$name} = sub {
                return $_[0]->{$key} = $_[1] if ( @_ > 1 );
                return $_[0]->{$key};
            };
        }
    }
    elsif ( $interface eq 'ro' ) {
        if ( $Rose::Object::MakeMethods::Generic::Have_CXSA
            && !$ENV{'ROSE_OBJECT_NO_CLASS_XSACCESOR'} )
        {
            $methods{$name} = {
                make_method => sub {
                    my ( $name, $target_class, $options ) = @_;

                    $Debug
                        && warn
                        "Class::XSAccessor make method ($name => $key) in $target_class\n";

                    Class::XSAccessor->import(
                        getters => { $name => $key },
                        class   => $target_class,
                        replace => $options->{'override_existing'} ? 1 : 0
                    );
                },
            };
        }
        else {
            $methods{$name} = sub {
                if ( @_ > 1 ) {
                    croak "usage: $name() is read-only (getter not setter)";
                }
                return $_[0]->{$key};
            };
        }
    }
    else { Carp::croak "Unknown interface: $interface" }

    return \%methods;
}

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rose-objectx-caf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rose-ObjectX-CAF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rose::ObjectX::CAF


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-ObjectX-CAF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rose-ObjectX-CAF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Rose-ObjectX-CAF>

=item * Search CPAN

L<http://search.cpan.org/dist/Rose-ObjectX-CAF/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Rose::ObjectX::CAF
