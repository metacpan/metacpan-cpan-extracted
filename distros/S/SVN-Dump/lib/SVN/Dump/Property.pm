package SVN::Dump::Property;

use strict;
use warnings;

my $NL = "\012";

# FIXME should I use Tie::Hash::IxHash or Tie::Hash::Indexed?
sub new {
    my ( $class, @args ) = @_;
    return bless {
        keys => [],
        hash => {},
    }, $class;
}

sub set {
    my ( $self, $k, $v ) = @_;

    push @{ $self->{keys} }, $k if !exists $self->{hash}->{$k};
    $self->{hash}{$k} = $v;
}
sub get    { return $_[0]{hash}{ $_[1] }; }
sub keys   { return @{ $_[0]{keys} }; }
sub values { return @{ $_[0]{hash} }{ @{ $_[0]{keys} } }; }
sub delete {
    my ( $self, @keys ) = @_;
    return if !@keys;
    my $re = qr/^@{[join '|', map { quotemeta } @keys]}$/;
    $self->{keys} = [ grep { !/$re/ } @{ $self->{keys} } ];
    delete @{ $self->{hash} }{@keys};
}

sub as_string {
    my ($self) = @_;
    my $string = '';

    $string .=
        defined $self->{hash}{$_}
        # existing key
        ? ( "K " . length($_) . $NL ) . "$_$NL"
        . ( "V " . length( $self->{hash}{$_} ) . $NL )
        . "$self->{hash}{$_}$NL"
        # deleted key (v3)
        : ( "D " . length($_) . "$NL$_$NL" )
        for @{ $self->{keys} };

    # end marker
    $string .= "PROPS-END$NL";

    return $string;
}

1;

__END__

=head1 NAME

SVN::Dump::Property - A property block from a svn dump

=head1 SYNOPSIS
 
=head1 DESCRIPTION

The SVN::Dump::Property class represents a property block in a svn
dump.

=head1 METHODS

The following methods are available:

=over 4

=item new()

Create a new empty property block.

=item set( $key => $value)

Set the C<$key> property with value C<$value>.

=item get( $key )

Get the value of property C<$key>.

=item delete( @keys )

Delete the keys C<@keys>. Behaves like the builtin C<delete()> on a hash.

=item keys()

Return the property block keys, in the order they were entered.

=item values()

Return the property block values, in the order they were entered.

=item as_string()

Return a string representation of the property block.

=back

=head1 SEE ALSO

L<SVN::Dump>, L<SVN::Dump::Record>.

=head1 COPYRIGHT

Copyright 2006-2013 Philippe Bruhat (BooK), All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
