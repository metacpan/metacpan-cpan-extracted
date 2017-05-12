#===============================================================================
#
#  DESCRIPTION:  Latex writer
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::Writer::Latex;
use strict;
use warnings;
use Perl6::Pod::Writer;
use base 'Perl6::Pod::Writer';
our $VERSION = '0.01';
sub new {
    my $class = shift;
    my $self = bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );
    $self;
}

sub repl {
    my $str = shift;
    warn "!!$str";
    my %map = (
    '\\' =>'\textbackslash{}',
    '^' =>'\textbackslash{}',
    '~' => '\textasciitilde{}'
    #$txt   =~ s/([#$%&_{}])/\\$1/g;
    );
    return $str if  exists $map{$str};
    return "\\$str"
}
#http://www.cespedes.org/blog/85/how-to-escape-latex-special-characters
sub _latex_escape {
    my ( $txt ) =@_;
    #die "$txt";
    #$txt = "#";
    #warn ">$txt";
    $txt  =~ s/(\\|\^|\~|[\#\$\%\&\_\{\}])/&repl($1)/eg;
#    $txt   =~ s/\\/\textbackslash{}/g;
#    $txt   =~ s/^/\textbackslash{}/g;
#    $txt   =~ s/~/\textasciitilde{}/g;
    #$txt   =~ s/([#$%&_{}])/\\$1/g;
    $txt
}


sub print {
    my $self = shift;
    my $fh = $self->o;
    my $str = join ""=>@_;
    utf8::encode( $str) if utf8::is_utf8($str);
    print $fh _latex_escape($str);
    $self
}

sub start_nesting {
    my $self = shift;
    my $level = shift || 1 ;
}
sub stop_nesting {
    my $self = shift;
    my $level = shift || 1 ;
}

1;


