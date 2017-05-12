package Perl6::Pod::FormattingCode::M;

=pod

=head1 NAME

Perl6::Pod::FormattingCode::M - class of M code

=head1 SYNOPSIS

    =begin pod
    =use CustomCode TT<>
    sds M<TT: test_code>
    =end pod


=head1 DESCRIPTION

Perldoc modules can define their own formatting codes, using the M<> code. An M<> code must start with a colon-terminated scheme specifier. The rest of the enclosed text is treated as the (verbatim) contents of the formatting code. For example: 

    =use Perldoc::TT TT<>
    
    =head1 Overview of the M<TT: $CLASSNAME > class
    (version M<TT: $VERSION>)
    
    M<TT: get_description($CLASSNAME) >

The M<> formatting code is the inline equivalent of a named block. 

=cut

use warnings;
use strict;
use Perl6::Pod::FormattingCode;
use base 'Perl6::Pod::FormattingCode';
our $VERSION = '0.01';

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
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

