#
# This file is part of MooseX-Attribute-Dependent
#
# This software is Copyright (c) 2017 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Attribute::Dependent::Meta::Role::Class;
$MooseX::Attribute::Dependent::Meta::Role::Class::VERSION = '1.1.4';
use strict;
use warnings;
use Moose::Role;

override _inline_check_required_attr => sub {
    my ($self, $attr, $idx) = @_;
    return super() 
        if(!$attr->does('MooseX::Attribute::Dependent::Meta::Role::Attribute')
            || !$attr->has_dependency
            || !$attr->init_arg);
    my @source;
    my $related = "'" . join("', '", @{$attr->dependency->parameters}) . "'";
    push @source => 'if(exists $params->{' . $attr->init_arg . '}) {';
    push @source => $self->_inline_throw_error( '"' . quotemeta($attr->dependency->get_message) . '"' );
    push @source => "unless(" . $attr->dependency->name . "->constraint->(\"" . quotemeta($attr->init_arg) . "\", \$params, $related));";
    push @source => '}';
    return join("\n", @source, super());
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Attribute::Dependent::Meta::Role::Class

=head1 VERSION

version 1.1.4

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
