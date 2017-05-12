package MoobX::Trait::Observable;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: turn a Moose object attribute into an MoobX observable
$MoobX::Trait::Observable::VERSION = '0.1.0';

use Moose::Role;
use MoobX;
use Moose::Util;

Moose::Util::meta_attribute_alias('Observable');

use experimental 'signatures';

after initialize_instance_slot => sub($attr_self,$,$instance,$) {

    $instance->meta->add_before_method_modifier( $attr_self->get_read_method, sub($self,@) {
        push @MoobX::DEPENDENCIES, $attr_self if $MoobX::WATCHING;
    }) if $attr_self->has_read_method;

    $instance->meta->add_after_method_modifier( $attr_self->get_write_method, sub {
        my( $self, $value ) = @_;
        MoobX::observable_ref($value) if ref $value;
        MoobX::observable_modified( $attr_self );
    }) if $attr_self->has_write_method;

};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MoobX::Trait::Observable - turn a Moose object attribute into an MoobX observable

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

    package Person;

    use MoobX;

    our $OPENING :Observable = 'Dear';

    has name => (
        traits => [ 'Observable' ],
        is     => 'rw',
    );

    has address => (
        is      => 'ro',
        traits  => [ 'Observer' ],
        default => sub {
            my $self = shift;
            join ' ', $Person::OPENING, $self->name
        },
    );

    my $person = Person->new( name => 'Wilfred' );

    print $person->address;  # Dear Wilfred

    $person->name( 'Wilma' );

    print $person->address;  # Dear Wilma

=head1 DESCRIPTION

Turns an object attribute into an observable.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
