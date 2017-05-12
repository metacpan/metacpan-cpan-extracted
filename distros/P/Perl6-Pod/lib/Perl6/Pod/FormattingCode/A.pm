#===============================================================================
#
#  DESCRIPTION:  Replaced by contents of specified macro/object
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::FormattingCode::A;

=pod

=head1 NAME

Perl6::Pod::FormattingCode::A - Replaced by contents of specified macro/object

=head1 SYNOPSIS

    =alias PROGNAME    Earl Irradiatem Eventually
    =alias VENDOR      4D Kingdoms
    =alias TERMS_URL   L<http://www.4dk.com/eie>
    
    The use of A<PROGNAME> is subject to the terms and conditions
    laid out by A<VENDOR>, as specified at A<TERMS_URL>.


=head1 DESCRIPTION

A variation on placement codes is the C<AE<lt>E<gt>> code, which is replaced
by the contents of the named alias or object specified within its delimiters.
For example:

    =alias PROGNAME    Earl Irradiatem Eventually
    =alias VENDOR      4D Kingdoms
    =alias TERMS_URL   L<http://www.4dk.com/eie>

    The use of A<PROGNAME> is subject to the terms and conditions
    laid out by A<VENDOR>, as specified at A<TERMS_URL>.

Any compile-time Perl 6 object that starts with a sigil is automatically
available within an alias placement as well. Unless the object is already
a string type, it is converted to a string during document-generation by
implicitly calling C<.perl> on it.

So, for example, a document can refer to its own filename (as
C<AE<lt>$?FILEE<gt>>), or to the subroutine inside which the specific Pod is nested
(as C<AE<lt>$?ROUTINEE<gt>>), or to the current class (as C<AE<lt>$?CLASSE<gt>>).
Similarly, the value of any program constants defined with sigils can be
easily reproduced in documentation:

    # Actual code...
    constant $GROWTH_RATE of Num where 0..* = 1.6;

    =pod
    =head4 Standard Growth Rate

    The standard growth rate is assumed to be A<$GROWTH_RATE>.

Non-mutating method calls on these objects are also allowed, so a
document can reproduce the surrounding subroutine's signature
(C<AE<lt>$?ROUTINE.signatureE<gt>>) or the type of a constant
(C<AE<lt>$GROWTH_RATE.WHATE<gt>>).

=cut

use warnings;
use strict;
use Data::Dumper;
use Perl6::Pod::FormattingCode;
use Perl6::Pod::Utl;
use base 'Perl6::Pod::FormattingCode';
our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my $alias_value = $self->context->{_alias}->{$self->{content}->[0]};
    if (my $tree = Perl6::Pod::Utl::parse_para($alias_value) ) {
        $self->{content}  = $tree;
    }
    return $self;
}

sub to_xhtml {
    my $self = shift;
    my $to   = shift;
    $to->visit_childs($self);
}

sub to_docbook {
    my $self = shift;
    my $to   = shift;
    $to->visit_childs($self);
}

sub to_latex {
    my $self = shift;
    my $to   = shift;
    $to->visit_childs($self);
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
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


