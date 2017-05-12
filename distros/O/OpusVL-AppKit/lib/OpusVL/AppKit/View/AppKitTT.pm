package OpusVL::AppKit::View::AppKitTT;


#####################################################################################################################
# constructing code
#####################################################################################################################

use Moose;
BEGIN { 
    extends 'Catalyst::View::TT::Alloy'; 
}

__PACKAGE__->config->{AUTO_FILTER} = 'html';
__PACKAGE__->config->{ENCODING} = 'UTF-8';

$Template::Stash::LIST_OPS->{as_list} = sub { return ref( $_[0] ) eq 'ARRAY' ? shift : [shift]; };
$Template::Directive::WHILE_MAX = 100000;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::View::AppKitTT

=head1 VERSION

version 2.29

=head1 DESCRIPTION

    Standard TT View for OpusVL::AppKit. 
    Included is the 'AppKit' ShareDir path to include distributed files.

=head1 NAME

    OpusVL::AppKit::View::AppKitTT - TT View for OpusVL::AppKit

=head1 METHODS

=head2 as_list
    Little help vmethod for TemplateToolkit to force array context.
    Helps when DBIx::Class ->search method return only 1 result.
        eg.  [% FOR row IN rs.search().as_list %]

=head1 SEE ALSO

    L<OpusVL::AppKit>

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
