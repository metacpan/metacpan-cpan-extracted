package MooX::VariantAttribute::Role;

use Moo::Role;
use Carp qw/croak/;
use Scalar::Util qw/blessed refaddr reftype/;
use Combine::Keys qw/combine_keys/;

has variant_last_value => (
    is      => 'rw',
    lazy    => 1,
    default => sub { {} },
);

sub _given_when {
    my ($self) = shift;
    my ( $set, $given, $when, $attr, $run ) = @_;

    return if $self->_variant_last_value($attr, 'set', $set);

    my $find = $self->_find_from_given(@_);

    $self->variant_last_value->{$attr}->{find} = $find;
    my @when = @{ $when };
    while (scalar @when >= 2) {
        my $check = shift @when;
        my $found = shift @when;
        if ( _struct_the_same($check, $find) ) {
            if ( $found->{alias} ) {
                if (blessed $set) {
                    for my $alias ( keys %{ $found->{alias} } ) {
                        next if $set->can($alias);
                        my $actual = $found->{alias}->{$alias};
                        {
                            no strict 'refs';
                            *{"${find}::${alias}"} = sub { goto &{"${find}::${actual}"} };
                        }
                    }
                } else {
                    map { $set->{$_} = $set->{$found->{alias}->{$_}} } keys %{ $found->{alias} };
                }
            }

            if ( $run = $found->{run} ) { 
				my @new = ref $run eq 'CODE' 
                    ? $found->{run}->( $self, $find, $set, ) 
                    : $self->$run($find, $set);
                $set = scalar @new > 1 ? \@new : shift @new;
            }

            $self->variant_last_value->{$attr}->{set} = $set;
            return $self->$attr($set);
        }
    }

    croak sprintf 'Could not find - %s - in when spec for attribute - %s',
      $set, $attr;
}

sub _variant_last_value {
    my ($self, $attr, $value, $set) = @_;

    my $stored = $self->variant_last_value->{$attr}->{$value} or return undef;
    return _ref_the_same($stored, $set);
}

sub _ref_the_same {
    my ($stored, $passed) = @_;

    if ( ref $passed and ref $stored ) {
        return refaddr($stored) == refaddr($passed) ? 1 : undef;
    } 
    
    return ($stored =~ m/^$passed$/) ? 1 : undef;
}

sub _struct_the_same {
    my ($stored, $passed) = @_;
    
    my $stored_ref = reftype($stored) // reftype(\$stored);
    my $passed_ref = reftype($passed) // reftype(\$passed);
    $stored_ref eq $passed_ref or return undef;
     
    if ( $stored_ref eq 'SCALAR') {
          return ($stored =~ m/^$passed$/) ? 1 : undef;
    } elsif ($stored_ref eq 'HASH') {
        for (combine_keys($stored, $passed)) {
            $stored->{$_} and $passed->{$_} or return undef;
            _struct_the_same($stored->{$_}, $passed->{$_}) or return undef;    
        }
        return 1;
    } elsif ($stored_ref eq 'ARRAY') {
        my @count = (scalar @{$stored}, scalar @{$passed});
        $count[0] == $count[1] or return undef;
        for ( 0 .. $count[1] - 1 ) {
            _struct_the_same($stored->[$_], $passed->[$_]) or return undef;
        }
        return 1;
    }

    return 1;
}

sub _find_from_given {
    my ( $self, $set, $given, $when ) = @_;

    my $ref_given = ref $given;
    if ( $ref_given eq 'Type::Tiny' ) {
        $set = $given->($set);
        return $given->display_name eq 'Object' ? ref $set : $set;
    }
    elsif ( $ref_given eq 'CODE' ) {
        return $given->( $self, $set );
    }

    return $set;
}

1;

__END__

=head1 NAME

MooX::VariantAttribute::Role

=head1 AUTHOR

Robert Acock, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moox-variantattribute at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-VariantAttribute>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::VariantAttribute


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-VariantAttribute>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooX-VariantAttribute>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooX-VariantAttribute>

=item * Search CPAN

L<http://search.cpan.org/dist/MooX-VariantAttribute/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of MooX::VariantAttribute
