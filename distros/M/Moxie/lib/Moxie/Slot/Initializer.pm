package Moxie::Slot::Initializer;
# ABSTRACT: Slots in a Moxie World

use v5.22;
use warnings;
use experimental qw[
    signatures
    postderef
];

use Carp ();

our $VERSION   = '0.03';
our $AUTHORITY = 'cpan:STEVAN';

use overload '&{}' => 'to_code', fallback => 1;

our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = (
        meta     => sub { die 'A class/role `meta` instance is required' },
        name     => sub { die 'A slot `name` is required' },
        # ...
        default  => sub {},
        required => sub {},
        builder  => sub {},
        # private ...
        _initializer => sub {},
    )
}

sub BUILD ($self, $) {
    ## TODO:
    ## - add consistency checking (no default + required, etc)
    ## - add type checking/coercion as needed
}

sub to_code ($self, @) {

    # short curcuit the optimal case ...
    return $self->{_initializer} if $self->{_initializer};

    my $meta = $self->{meta};
    my $name = $self->{name};

    ## FIXME:
    ## The eval-into-package thing below is not great
    ## and can likely be done in a much better way.
    ## - SL

    #warn sprintf "Generating initializer for slot(%s) in class(%s)", $name, $meta->name;

    if ( my $method = $self->{builder} ) {
        return $self->{_initializer} ||= eval 'package '.$meta->name.'; sub { (shift)->'.$method.'( @_ ) }';
    }
    elsif ( $self->{required} ) {
        return $self->{_initializer} ||= eval 'package '.$meta->name.'; sub { die "A `'.$name.'` value is required" }';
    }
    elsif ( $self->{default} ) {
        return $self->{_initializer} ||= $self->{default};
    }
    else {
        return $self->{_initializer} ||= eval 'package '.$meta->name.'; sub { undef }';
    }
}

1;

__END__

=pod

=head1 NAME

Moxie::Slot::Initializer - Slots in a Moxie World

=head1 VERSION

version 0.03

=head1 DESCRIPTION

Slots in the Moxie World (sung to the tune of "Spirits in the
Material World" by the Police), more details later ...

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
