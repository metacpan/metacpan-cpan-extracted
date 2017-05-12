#===============================================================================
#
#  DESCRIPTION:  Export to latex
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::To::Latex;
use strict;
use warnings;
use strict;
use warnings;
use Perl6::Pod::To::DocBook;
use base 'Perl6::Pod::To::DocBook';
use Perl6::Pod::Utl;
our $VERSION = '0.01';

sub new {
    my $class =  shift;
    my %args = @_;
    unless ( $args{writer} ) {
        use Perl6::Pod::Writer::Latex;
        $args{writer} = new Perl6::Pod::Writer::Latex(
            out => ( $args{out} || \*STDOUT ),
        );
    }
    my $self = $class->SUPER::new(%args);
    return $self;
}

sub switch_head_level {
    my $self = shift;
    my $level = shift;
    my $w = $self->w;
    my $prev = $self->Perl6::Pod::To::switch_head_level($level);
}

1;


