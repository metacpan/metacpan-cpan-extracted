package Perl6::Pod::FormattingCode;

=pod

=head1 NAME

Perl6::Pod::FormattingCode - base class for formatting code

=head1 SYNOPSIS


=head1 DESCRIPTION

Perl6::Pod::FormattingCode - base class for formatting code

=cut

use warnings;
use strict;
use Perl6::Pod::Block;
use base 'Perl6::Pod::Block';
our $VERSION = '0.01';

=head2 get_attr [code_name]

Return formatting code  attributes splited with pre-configured via =config.
Unless provided <code_name> return attributes for current .

=cut

sub get_attr {
    my $self = shift;
    my $attr = $self->SUPER::get_attr;
    #union attr with =config
    if (my $ctx = $self->context) {
        if ( my $config = $ctx->get_config( $self->name . '<>' ) ) {
         while ( my ($k, $v) = each %$config ) {
            $attr->{$k} = $v
           }
         }
    }
    $attr;
}

1;
__END__


=head1 SEE ALSO

L<http://zag.ru/perl6-pod/S26.html>,
Perldoc Pod to HTML converter: L<http://zag.ru/perl6-pod/>,
Perl6::Pod::Lib

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

