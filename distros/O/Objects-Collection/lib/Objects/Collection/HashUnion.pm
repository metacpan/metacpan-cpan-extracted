package Objects::Collection::HashUnion;

=head1 NAME

 Objects::Collection::HashUnion -  Union hashes.

=head1 SYNOPSIS

    use Objects::Collection::HashUnion;

   tie %hashu, 'Objects::Collection::HashUnion', \%hash1, \%hash2;

=head1 DESCRIPTION

 
 
=cut

use strict;
use warnings;
use strict;
use Carp;
use Data::Dumper;
require Tie::Hash;
use Objects::Collection::Base;
@Objects::Collection::HashUnion::ISA = qw(Tie::StdHash Objects::Collection::Base);
$Objects::Collection::HashUnion::VERSION = '0.01';

attributes qw( _orig_hashes _for_write __temp_array);


sub Init {
    my ( $self, @hashes ) = @_;
    $self->_for_write($hashes[ -1 ]);
    $self->_orig_hashes(\@hashes);
    return 1;
}




sub _init {
    my $self = shift;
    return $self->Init(@_);
}

#delete keys only from _for_write hashe!
sub DELETE {
    my ( $self, $key ) = @_;
    delete $self->_for_write->{ $key };
}

sub STORE {
    my ( $self, $key, $val ) = @_;
    my $hashes = $self->_orig_hashes;
    foreach my $hash ( @$hashes) {
        next unless exists $hash->{$key};
        return $hash->{$key} = $val;
    }
    $self->_for_write->{ $key } =$val;
    
}

=head2 _changed

Handle collections key _changed

=cut

sub _changed {
    my $self = shift;
    my $hashes = $self->_orig_hashes;
    my $res;
    foreach my $hash ( @$hashes) {
        $res++ if $hash->{_changed};
    }
    return $res
}

sub FETCH {
    my ( $self, $key ) = @_;
    if ( $key eq '_changed' ) {
        $self->_changed();
    }
    else {
        
    my $hashes = $self->_orig_hashes;
    foreach my $hash ( @$hashes) {
        next unless exists $hash->{$key};
        return $hash->{$key};
    }
    return 
    }
}


sub GetKeys {
    my $self = shift;
    my $hashes = $self->_orig_hashes;
    my %uniq;
    foreach my $hash ( @$hashes) {
        $uniq{$_}++ for keys %$hash;   
    }

    return [ keys %uniq ];
}


sub TIEHASH {return Objects::Collection::Base::new(@_) }

sub FIRSTKEY {
    my ($self) = @_;
    $self->__temp_array( [ sort { $a cmp $b } @{ $self->GetKeys() } ] );
    shift( @{ $self->__temp_array() } );
}

sub NEXTKEY {
    my ( $self, $key ) = @_;
    shift( @{ $self->__temp_array() } );
}

sub EXISTS {
    my ( $self, $key ) = @_;
    my $hashes = $self->_orig_hashes;
    my %uniq;
    foreach my $hash ( @$hashes) {
        $uniq{$_}++ for keys %$hash;   
    }
    return exists $uniq{$key};
}

sub CLEAR {
    my $self = shift;
    %{ $self->_for_write } = ()
}

1;
__END__


=head1 SEE ALSO

Tie::StdHash

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

