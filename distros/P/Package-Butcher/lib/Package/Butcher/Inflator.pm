package Package::Butcher::Inflator;

# Borrows heavily from Hash::Inflator
use strict;
use warnings;

our $VERSION = '0.02';

sub new {
    my $class = shift;

    #return $_[0] if @_ == 1 && !ref $_[0];
    my %hash = %{ $_[0] };
    for my $key ( keys %hash ) {
        if ( ref $hash{$key} eq 'HASH' ) {
            $hash{$key} = $class->new( $hash{$key} );
        }
    }
    bless \%hash, $class;
}

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    $AUTOLOAD =~ s/.+:://;
    my $result = $self->{$AUTOLOAD};
    if ( 'CODE' eq ref $result ) {
        goto $result;
    }
    else {
        return $result;
    }
}

1;

__END__

=head1 NAME

Package::Butcher::Inflator - For internal use only

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Package::Butcher::Inflator;
    my $inflate = Package::Butcher::Inflator->new(
        { foo => { bar => { baz => sub { 'whee! } } } },
    );
    print $inflate->foo->bar->baz; # whee!

=head1 AUTHOR

Curtis 'Ovid' Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-package-butcher at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Package-Butcher>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Package::Butcher::Inflator

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Package-Butcher>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Package-Butcher>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Package-Butcher>

=item * Search CPAN

L<http://search.cpan.org/dist/Package-Butcher/>

=back

=head1 ACKNOWLEDGEMENTS

Marcel Gruenauer <marcel@cpan.org>, the author of L<Hash::Inflator>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Curtis 'Ovid' Poe.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
