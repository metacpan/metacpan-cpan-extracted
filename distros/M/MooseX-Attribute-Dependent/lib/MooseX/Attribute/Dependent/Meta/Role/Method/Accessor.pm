#
# This file is part of MooseX-Attribute-Dependent
#
# This software is Copyright (c) 2016 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Attribute::Dependent::Meta::Role::Method::Accessor;
$MooseX::Attribute::Dependent::Meta::Role::Method::Accessor::VERSION = '1.1.3';
use strict;
use warnings;
use Moose::Role;

override _inline_check_constraint => sub {
    my ( $self, $val ) = @_;
    my $code = super();
    my $attr = $self->{attribute};
    
    return $code
        if( !$attr->does('MooseX::Attribute::Dependent::Meta::Role::Attribute')
            || !$attr->has_dependency
            || !$attr->init_arg);
    my @source;
    my $related = "'" . join("', '", @{$attr->dependency->parameters}) . "'";
    push @source => $self->_inline_throw_error( '"' . quotemeta($attr->dependency->get_message) . '"' );
    push @source => "unless(" . $attr->dependency->name . "->constraint->(\"" . quotemeta($attr->name) . "\", \$_[0], $related));";
    
    return join("\n", $code, @source);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Attribute::Dependent::Meta::Role::Method::Accessor

=head1 VERSION

version 1.1.3

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
