#===============================================================================
#  DESCRIPTION:  Base class for tests
#       AUTHOR:  Aliaksandr P. Zahatski (Mn), <zahatski@gmail.com>
#===============================================================================
package TestSlide;
use warnings;
use strict;
use Perl6::Pod::Slide;
use base 'Perl6::Pod::Slide';
sub export_block_DESCRIPTION {
    my $self = shift;
    return $self->{DESCRIPTION} = $self->SUPER::export_block_DESCRIPTION(@_)
}

sub export_block_Slide {
    my $self = shift;
    return $self->{Slide} = $self->SUPER::export_block_Slide(@_)
}

1;
package TBase;
#Setup uses

use strict;
use warnings;
use Test::More;
use Test::Class;
use Perl6::Pod::Test;
use base qw( Test::Class Perl6::Pod::Test );
use Perl6::Pod::To::DocBook;
use Perl6::Pod::To::XHTML;
use XML::Flow;

sub testing_class {
    my $test = shift;
    ( my $class = ref $test ) =~ s/^T[^:]*::/Perl6::Pod::/;
    return $class;
}

sub parse_to_latex {
    my ( $text, %args) = @_;
    my $out    = '';
    open( my $fd, ">", \$out );
    my $renderer = new Perl6::Pod::Slide::
#      writer  => new Perl6::Pod::Writer( out => $fd, escape=>'xml' ),
      out => $fd,
        %args;
    $renderer->parse( \$text, default_pod=>1 );
    return wantarray ? (  $out, $renderer  ) : $out;
}

sub new_args { () }

sub _use : Test(startup=>1) {
    my $test = shift;
    use_ok $test->testing_class;
}


1;

