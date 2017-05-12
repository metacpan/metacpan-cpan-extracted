
package Package::Pkg::Lexicon;

use strict;
use warnings;

use Mouse;
use Clone qw/ clone /;

has lexicon => qw/ is ro lazy_build 1 isa HashRef /;
sub _build_lexicon { {} }

has prefix => qw/ accessor _prefix isa Maybe[Str] /;
has suffix => qw/ accessor _suffix isa Maybe[Str] /;

sub prefix {
    my $self = shift;
    return $self->_prefix unless @_;
    $self->_prefix( $_[0] );
    return $self;
}

sub suffix {
    my $self = shift;
    return $self->_suffix unless @_;
    $self->_suffix( $_[0] );
    return $self;
}

sub copy {
    my $self = shift;
    my $lexicon;
    if ( @_ )   { $lexicon = { $self->slice( @_ ) } }
    else        { $lexicon = clone( $self->lexicon ) }
    return (ref $self)->new(
        lexicon => $lexicon,
        prefix => $self->prefix,
        suffix => $self->suffix,
    );
}

sub add {
    my $self = shift;

    die "Missing name & subroutine" unless @_;

    while ( @_ ) {
        my $name = shift;
        my $subroutine = shift;
        next unless defined $name and defined $subroutine;
        die "Invalid name ($name)" unless $name =~ m/^\w+$/;
        die "Invalid subroutine ($subroutine)" unless ref $subroutine eq 'CODE';
        $self->lexicon->{$name} = $subroutine;
    }

    return $self;
}

sub remove {
    my $self = shift;

    die "Missing name" unless @_;
    
    for my $name ( @_ ) {
        next unless defined $name;
        delete $self->lexicon->{$name};
    }

    return $self;
}

sub get {
    my $self = shift;
    my @namelist = @_ ? @_ : keys %{ $self->lexicon };
    return map { defined $_ ? $self->lexicon->{$_} : undef } @namelist;
}

sub slice {
    my $self = shift;
    return %{ $self->lexicon } unless @_;
    my @namelist = @_ ? @_ : keys %{ $self->lexicon };
    my @valuelist = map { defined $_ ? $self->lexicon->{$_} : undef } @namelist;
    my %slice;
    @slice{ @namelist } = @valuelist;
    return %slice;
}

sub export {
    my $self = shift;
    my @namelist = @_ ? @_ : keys %{ $self->lexicon };
    my @valuelist = map { defined $_ ? $self->lexicon->{$_} : undef } @namelist;
    if ( defined ( my $prefix = $self->prefix ) ) {
        @namelist = map { defined $_ ? join '_', $prefix, $_ : undef } @namelist;
    }
    if ( defined ( my $suffix = $self->suffix ) ) {
        @namelist = map { defined $_ ? join '_', $_, $suffix : undef } @namelist;
    }
    my %export;
    @export{ @namelist } = @valuelist;
    return %export;
}

sub filter {
    my $self = shift;
}

sub map {
    my $self = shift;
}

sub install {
    my $self = shift;
    # overwrite => 0|1
    # collide => 0|1|2
}

1;
