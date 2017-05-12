package # Hide from pause
    Monitoring::Livestatus::Class::Abstract::Stats;

use Moose;
use Carp;
extends 'Monitoring::Livestatus::Class::Base::Abstract';

use Monitoring::Livestatus::Class;
my $TRACE = Monitoring::Livestatus::Class->TRACE() || 0;

sub build_mode { return 'Stats'; };

sub build_compining_prefix { return 'Stats'; }

sub build_operators {
    my $self = shift;
    my $operators = $self->SUPER::build_operators();

    push @{ $operators }, {
        regexp  => qr/(groupby)/ix,
        handler => '_cond_op_groupby',
    };

    push @{ $operators }, {
        regexp  => qr/(sum|min|max|avg|std)/ix,
        handler => '_cond_op_simple'
    };

    push @{ $operators }, {
        regexp  => qr/(isa)/ix,
        handler => '_cond_op_isa'
    };

    return $operators;
}

sub _cond_op_groupby {
    my $self    = shift;
    my $operator = shift;
    my $value = shift;
    my $combining_count = shift || 0;

    print STDERR "#IN  _cond_op_groupby $operator $value $combining_count\n" if $TRACE > 9;

    my ( @child_statment ) = $self->_dispatch_refkind($value, {
        SCALAR  => sub {
            return ( sprintf("%s%s: %s",$self->compining_prefix, 'GroupBy', $value) );
        },
    });
    print STDERR "#OUT _cond_op_groupby $operator $value $combining_count\n" if $TRACE > 9;
    return ( $combining_count, @child_statment );
}

sub _cond_op_simple {
    my $self    = shift;
    my $operator = shift;
    my $value = shift;
    my $combining_count = shift || 0;
    my @child_statment = ();

    print STDERR "#IN  _cond_op_simple $operator $value $combining_count\n" if $TRACE > 9;

    ( $combining_count,@child_statment ) = $self->_dispatch_refkind($value, {
        SCALAR  => sub {
            return (++$combining_count, sprintf("%s: %s %s",$self->compining_prefix,$operator,$value) );
        },
    });

    print STDERR "#OUT _cond_op_simple $operator $value $combining_count\n" if $TRACE > 9;
    return ( $combining_count, @child_statment );
}

sub _cond_op_isa {
    my $self     = shift;
    my $operator = shift;
    my $value    = shift;
    my $combining_count = shift || 0;
    my $as_name;
    print STDERR "#IN  _cond_op_isa $operator $value $combining_count\n" if $TRACE > 9;

    my ( $child_combining_count, @statment ) = $self->_dispatch_refkind($value, {
        HASHREF  => sub {
            my @keys = keys %$value;
            if ( scalar @keys != 1 ){
                die "Isa operator doesn't support more then one key.";
            }
            $as_name = shift @keys;
            my @values = values(%$value);
            return $self->_recurse_cond(shift( @values ), 0 );
        },
    });
    $combining_count += $child_combining_count;

    $statment[ $#statment ] = $statment[$#statment] . " as " . $as_name;

    print STDERR "#OUT _cond_op_isa $operator $value $combining_count isa key: " . $self->{_isa_key} . "\n" if $TRACE > 9;
    return ( $combining_count, @statment );
}

1;
__END__
=head1 NAME

Monitoring::Livestatus::Class::Abstract::Stats - Class to generate livestatus
stats

=head2 SYNOPSIS

=head1 ATTRIBUTES

=head1 METHODS

=head2 apply

please view in L<Monitoring::Livestatus::Class::Base::Abstract>

=head1 INTERNAL METHODS

=over 4

=item build_mode

=item build_compining_prefix

=item build_operators

=back

=head1 AUTHOR

See L<Monitoring::Livestatus::Class/AUTHOR> and L<Monitoring::Livestatus::Class/CONTRIBUTORS>.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Bohne.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
