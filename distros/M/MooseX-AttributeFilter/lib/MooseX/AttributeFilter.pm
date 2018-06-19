package MooseX::AttributeFilter;
use 5.008009;
use strict;
use warnings;

our $VERSION = "0.09";

use Moose ();
use Moose::Exporter;

Moose::Exporter->setup_import_methods();

sub init_meta {
    my ($class_name, %args) = @_;
    my $caller = $args{for_class};
    my $trait  = 'MooseX::AttributeFilter::Trait::Attribute';
    
    Moose::Util::MetaRole::apply_metaroles(
        for             => $caller,
        class_metaroles => {
            attribute         => [ $trait ],
        },
        role_metaroles => {
            attribute         => [ $trait . '::Role' ],
            applied_attribute => [ $trait ],
        },
        parameter_metaroles => {
            applied_attribute => [ $trait ],
        },
        parameterized_role_metaroles => {
            applied_attribute => [ $trait ],
        },
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

MooseX::AttributeFilter - MooX::AttributeFilter with cute antlers OwO

=head1 SYNOPSIS

    package My::Class;
    use Moose;
    use MooseX::AttributeFilter;
    
    has field => (
        is     => 'rw',
        filter => 'filterField',
    );
    
    sub filterField {
        my $this = shift;
        return "filtered($_[0])";
    }
    
    package main;
    my $obj = My::Class->new( field => "initial" );
    $obj->field eq "filtered(initial)"; # True!

=head1 DESCRIPTION

MooseX::AttributeFilter is a port of L<MooX::AttributeFilter> to L<Moose>.

A filter a method that is called before an attribute value is set (by accessor
or constructor). It is called before coercions, type checks, and triggers.

It is called as a method (so receives the object) with the new attribute value
as its first parameter, and the old attribute value as the second parameter.
(When called from constructor, no old value, so only one parameter.) Its return
value is used as the attribute value.

It is even called when an attribute value is build by builder methods or
defaults.

See L<MooX::AttributeFilter> for more details and for use cases.

=head1 BUGS

Some parts don't work correctly in mutable classes. Mutable classes are slow anyway.

L<https://rt.cpan.org/Dist/Display.html?Queue=MooseX-AttributeFilter>

=head1 CUTE

=begin html

<img height="680" width="500" src="https://data.whicdn.com/images/129435330/large.jpg" alt="cute kitty girl" />

=end html

Cute.

=head1 SEE ALSO

L<MooX::AttributeFilter>, L<Moose>.

L<MooseX::AttributeFilter::Trait::Attribute>,
L<MooseX::AttributeFilter::Trait::Attribute::Role>.

=head1 LICENSE

Copyright (C) 2018 Little Princess Kitten <kitten@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

KITTEN <kitten@cpan.org>

L<https://metacpan.org/author/KITTEN>

L<https://github.com/icklekitten>

<3

=cut

