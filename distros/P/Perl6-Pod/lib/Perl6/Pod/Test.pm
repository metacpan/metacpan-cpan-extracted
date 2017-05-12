package Perl6::Pod::To::Test;
our $VERSION = '0.01';
use strict;
use warnings;
use Perl6::Pod::To;
use base 'Perl6::Pod::To';
sub __default_method {
    my $self   = shift;
    my $n      = shift;
    unless (defined $n) {
    warn "default" . $n;
    use Data::Dumper;
    warn Dumper([caller(0)]);
    }

    #detect output format
    # Perl6::Pod::To::DocBook -> to_docbook
    my $export_method ='to_xhtml';
    unless ( $export_method && UNIVERSAL::can($n, $export_method) ) {
    my $method = $self->__get_method_name($n);
    die ref($self)
      . ": Method '$method' for class "
      . ref($n)
      . " not implemented. But also can't found export method ". ref($n) . "::$export_method";
    }
    #call method for export
    $n->$export_method($self);
   #src_name may be not eq for name
    # ie/ item2, head5
    my $name = $n->{name};
    if (UNIVERSAL::isa($n, 'Perl6::Pod::FormattingCode')) {
        $name = "$name<>";
    }
    push @{ $self->{ $name }}, $n;
    if ( exists ($n->{src_name}) && ($name ne  $n->{src_name}) ) {
       push @{ $self->{ $n->{src_name} }}, $n;
    }
}

package Perl6::Pod::Test;
our $VERSION = '0.01';

=pod

=head1 NAME

Perl6::Pod::Test - test lib

=head1 SYNOPSIS


=head1 DESCRIPTION

=cut
use strict;
use warnings;

use Test::More;
use Perl6::Pod::Writer;

use Perl6::Pod::To::DocBook;
use Perl6::Pod::To::XHTML;
use Perl6::Pod::To::Latex;
use XML::Flow;

sub parse_to_docbook {
    shift if ref($_[0]);
    my ( $text) = @_;
    my $out    = '';
    open( my $fd, ">", \$out );
    my $renderer = new Perl6::Pod::To::DocBook::
      writer  => new Perl6::Pod::Writer( out => $fd, escape=>'xml' ),
      out_put => \$out,
      doctype => 'chapter',
      header => 0;
    $renderer->parse( \$text, default_pod=>1 );
    return wantarray ? (  $out, $renderer  ) : $out;

}


sub parse_to_latex {
    shift if ref($_[0]);
    my ( $text) = @_;
    my $out    = '';
    open( my $fd, ">", \$out );
    my $renderer = new Perl6::Pod::To::Latex::
      writer  => new Perl6::Pod::Writer::Latex( out => $fd, escape=>'latex' ),
      out_put => \$out,
      header => 0;
    $renderer->parse( \$text, default_pod=>1 );
    return wantarray ? (  $out, $renderer  ) : $out;
}

sub parse_to_xhtml {
    shift if ref($_[0]);
    my ( $text) = @_;
    my $out    = '';
    open( my $fd, ">", \$out );
    my $renderer = new Perl6::Pod::To::XHTML::
      writer  => new Perl6::Pod::Writer( out => $fd, escape=>'xml' ),
      out_put => \$out,
      doctype => 'xhtml',
      header => 0;
    $renderer->parse( \$text, default_pod=>1 );
    return wantarray ? (  $out, $renderer  ) : $out;
}

sub parse_to_test {
    shift if ref($_[0]);
    my ( $text, %args) = @_;
    my $out    = '';
    open( my $fd, ">", \$out );
    my $renderer = new Perl6::Pod::To::Test::
      writer  => new Perl6::Pod::Writer( out => $fd, escape=>'xml' ),
      out_put => \$out,
      doctype => 'xhtml',
      header => 0;
    $renderer->parse( \$text, default_pod=>1 ) unless exists $args{no_parse};
    return wantarray ? (  $out, $renderer  ) : $renderer;

}
sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $self = bless( {@_}, $class );
    return $self;
}


=head2 is_deeply_xml <got_xml>,<expected_xml>,"text"

Check xml without attribute values and character data

=cut

sub _xml_to_ref {

    #    my $self = shift;
    my $xml = shift;
    my %tags;

    #collect tags names;
    map { $tags{$_}++ } $xml =~ m/<(\w+)/gis;

    #make handlers
    our $res;
    for ( keys %tags ) {
        my $name = $_;
        $tags{$_} = sub {
            my $attr = shift || {};
            return $res = {
                name    => $name,
                attr    => [ keys %$attr ],
                content => [ grep { ref $_ } @_ ]
            };
          }
    }
    my $rd = new XML::Flow:: \$xml;
    $rd->read( \%tags );
    $res;
}

sub xml_ref {
    my $self = shift;
    my $xml  = shift;
    my %tags;

    #collect tags names;
    map { $tags{$_}++ } $xml =~ m/<(\w+)/gis;

    #make handlers
    our $res;
    for ( keys %tags ) {
        my $name = $_;
        $tags{$_} = sub {
            my $attr = shift || {};
            return $res = {
                name    => $name,
                attr    => $attr,
                content => [ grep { ref $_ } @_ ]
            };
          }
    }
    my $rd = new XML::Flow:: \$xml;
    $rd->read( \%tags );
    $res;

}

sub is_deeply_xml {
    my $test = shift;
    my ( $got, $exp, @params ) = @_;
    unless ( is_deeply $test->xml_ref($got), $test->xml_ref($exp), @params ) {
        diag "got:", "<" x 40;
        diag $got;
        diag "expected:", ">" x 40;
        diag $exp;

    }
}

1;
