package Peco::Spec;

use strict;
use warnings;

use Carp qw/croak/;

sub new { bless { } }

sub class { }

sub instance { }

sub clone {
    my ( $self, $data ) = @_;
    my $copy = ref( $self )->new(
        $self->{class}, $self->{deps}, $self->{ctor}, $self->{attrs}
    );
    $copy->{instance} = $self->{instance} if $data;
    return $copy;
}

sub _create {
    my ( $self, $cntr, %seen ) = @_;

    my @args = $self->_resolve( $cntr, %seen );
    my $ctor = $self->{ctor};

    $self->{class}->can( $ctor ) || croak( "$self->{class} can't `$ctor'" );

    my $inst = $self->{class}->$ctor( @args );
    while ( my ( $k, $v ) = each %{ $self->{attrs} } ) {
        $inst->$k( $v ) if $inst->can( $k );
    }

    return $inst;
}

sub _resolve {
    my ( $self, $cntr, %seen ) = @_;

    if ( ref $self->{deps} eq 'ARRAY' ) {
        my @resolved;
        foreach my $k ( @{ $self->{deps} } ) {
            if ( ref $k ) {
                push @resolved, $$k;
                next;
            }
            croak( "cyclic dependency detected for $k" ) if $seen{ $k };
            push @resolved, $cntr->service( $k, %seen );
        }
        return @resolved;
    }
    elsif ( ref $self->{deps} eq 'HASH' ) {
        my %resolved;
        foreach my $k ( keys %{ $self->{deps} } ) {
            if ( ref $self->{deps}{ $k } ) {
                $resolved{ $k } = ${ $self->{deps}{ $k } };
                next;
            }
            croak( "cyclic dependency detected for $k" ) if $seen{$k};
            $resolved{ $k } = $cntr->service( $self->{deps}{ $k }, %seen );
        }
        return %resolved;
    }
}


package Peco::Spec::Class;

use strict;
use warnings;

use Carp qw/croak/;
use base qw/Peco::Spec/;

sub new {
    my ( $class, @spec ) = @_;
    my $self = bless {
        class => $spec[0],
        deps  => $spec[1],
        ctor  => $spec[2],
        attrs => $spec[3],
    }, $class;
    $self;
}

sub class { shift->{class} }

sub instance {
    my ( $self, $cntr, $key, %seen ) = @_;
    $seen{ $key }++;
    $self->{instance} ||= $self->_create( $cntr, %seen );
}


package Peco::Spec::Code;

use strict;
use warnings;

use base qw/Peco::Spec/;

sub new {
    my ( $class, $code ) = @_;
    bless $code, $class;
}

sub class { ref( $_[0] ) }

sub instance {
    my ( $self, $cntr, $key, %seen ) = @_;
    $seen{ $key }++;
    return $self->( $cntr );
}


package Peco::Spec::Const;

use strict;
use warnings;

use base qw/Peco::Spec/;

sub new {
    my ( $class, $value ) = @_;
    bless \$value, $class;
}

sub class { ref( $_[0] ) }
sub instance { ${$_[0]} }


1;
