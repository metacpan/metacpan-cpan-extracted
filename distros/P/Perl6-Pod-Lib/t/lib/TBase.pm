#===============================================================================
#  DESCRIPTION:  Base class for tests
#       AUTHOR:  Aliaksandr P. Zahatski (Mn), <zahatski@gmail.com>
#===============================================================================
package TBase;
#Setup uses
use constant NAME_BLOCKS => {
    Include => 'Perl6::Pod::Lib::Include',
    Image   => 'Perl6::Pod::Lib::Image'
};

use strict;
use warnings;
use Test::More;
use Test::Class;
use Perl6::Pod::Test;
use base qw( Test::Class Perl6::Pod::Test );
use XML::Flow;

sub parse_to_test {
    my $t = shift;
    my ($o, $renderer ) = $t->SUPER::parse_to_test(@_, no_parse=>1);
    #install MAP
    while (my ($k, $v) = each %{( NAME_BLOCKS )}) {
        $renderer->context->use->{$k} = $v;
    }
    $renderer->parse( \$_[0], default_pod=>1 );
    return  $renderer 
}

sub parse_to_xhtml {
    my $t = shift;
    my ( $text, %args ) = @_;
    my $out    = '';
    open( my $fd, ">", \$out );
    my $renderer = new Perl6::Pod::To::XHTML::
      writer  => new Perl6::Pod::Writer( out => $fd, escape=>'xml' ),
      out_put => \$out,
      doctype => 'xhtml',
      header => 0;
    #install MAP
    while (my ($k, $v) = each %{( NAME_BLOCKS )}) {
        $renderer->context->use->{$k} = $v;
    }
    $renderer->parse( \$text, default_pod=>1 );
    return wantarray ? (  $out, $renderer  ) : $out;

}

sub parse_to_docbook {
    my $t = shift;
    my ( $text, %args ) = @_;
    my $out    = '';
    open( my $fd, ">", \$out );
    my $renderer = new Perl6::Pod::To::DocBook::
      writer  => new Perl6::Pod::Writer( out => $fd, escape=>'xml' ),
      out_put => \$out,
      doctype => 'chapter',
      header => 0;
    #install MAP
    while (my ($k, $v) = each %{( NAME_BLOCKS )}) {
        $renderer->context->use->{$k} = $v;
    }
    $renderer->parse( \$text, default_pod=>1 );
    return wantarray ? (  $out, $renderer  ) : $out;

}


sub testing_class {
    my $test = shift;
    ( my $class = ref $test ) =~ s/^T[^:]*::/Perl6::Pod::Lib::/;
    return $class;
}

#overwrite Perl6::Pod::Test class
sub make_parser {
    my $self = shift;
    my ( $p, $out_formatter )  = $self->SUPER::make_parser(@_);
    #resgister
    my $use = $p->current_context->use;
    %$use = ( %$use, %{( NAME_BLOCKS )}); 
    return wantarray ? ( $p, $out_formatter ) : $p;

}

sub new_args { () }

sub _use : Test(startup=>1) {
    my $test = shift;
    use_ok $test->testing_class;
}


1;

