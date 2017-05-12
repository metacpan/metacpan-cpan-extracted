package MooseX::Storage::Engine::Trait::WithRoles;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: An engine trait to include roles in serialization
$MooseX::Storage::Engine::Trait::WithRoles::VERSION = '0.2.0';
use Moose::Util qw/ with_traits /;

use List::Util qw/ pairgrep /;

use Moose::Role;
use MooseX::Storage::Base::SerializedClass;
use List::MoreUtils qw/ apply /;

use namespace::autoclean;

around collapse_object => sub {
    my( $orig, $self, @args ) = @_;

    my $packed = $orig->( $self, @args );

    my @extra;
    ( $packed->{'__CLASS__'}, @extra ) = split '\|', ($self->object->meta->superclasses)[0]
        if $self->object->meta->is_anon_class or $self->object->meta->name =~ /__ANON__/ ;

    my %in_superclass = map { $_ => 1 } map { split '\|', $_->name } @{ $packed->{'__CLASS__'}->meta->roles };

    if( my @roles = grep { !$in_superclass{$_} } map { split '\|', } ( @extra, map { $_->name } @{ $self->object->meta->roles } ) ) {
        @roles = apply { 
            $_ = { $_->meta->genitor->name => { pairgrep { $a ne '<<MOP>>' }  %{ $_->meta->parameters } } }
                if $_->meta->isa('MooseX::Role::Parameterized::Meta::Role::Parameterized') 
        } @roles;
        $packed->{'__ROLES__'} = \@roles;
    }


    return $packed;
};

around expand_object => sub {
    my( $orig, $self, $data, @args ) = @_;

    $self->class(
        MooseX::Storage::Base::SerializedClass::_unpack_class($data)
    );

    $orig->($self,$data,@args);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Storage::Engine::Trait::WithRoles - An engine trait to include roles in serialization

=head1 VERSION

version 0.2.0

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
