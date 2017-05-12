#===============================================================================
#
#  DESCRIPTION:  Abstract writer
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::Writer;
our $VERSION = '0.01';
use strict;
use warnings;
sub new {
    my $class = shift;
    my $self = bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );
    $self;
}

sub o {
    return $_[0]->{out};
}

sub raw {
    my $self = shift;
    my $fh = $self->o;
    print $fh @_;
    $self
}

#http://stackoverflow.com/questions/1091945

sub _xml_escape {
    my ( $txt ) =@_;
    $txt   =~ s/&/&amp;/g;
    $txt   =~ s/</&lt;/g;
    $txt   =~ s/>/&gt;/g;
    $txt   =~ s/"/&quot;/g;
    $txt   =~ s/'/&apos;/g;
    $txt
}

sub _html_escape {
    my ( $txt ) =@_;
    $txt   =~ s/&/&amp;/g;
    $txt   =~ s/</&lt;/g;
    $txt   =~ s/>/&gt;/g;
    $txt   =~ s/"/&quot;/g;
    $txt   =~ s/'/&apos;/g;
    $txt
}


sub raw_print {
    my $self = shift;
    my $fh = $self->o;
    print $fh @_;
    $self
}

sub print {
    my $self = shift;
    my $fh = $self->o;
    if (my $type = $self->{escape}) {
        my $str = join ""=>@_;
        utf8::encode( $str) if utf8::is_utf8($str);
        print $fh ($type eq 'xml') ? _xml_escape($str) : _html_escape($str);
        return $self
    }
    print $fh @_;
    $self
}

sub say {
    my $self = shift;
    my $fh = $self->o;
    print $fh @_;
    print $fh "\n";
    $self
}

sub start_nesting {
    my $self = shift;
    my $level = shift || 1 ;
    $self->raw('<blockquote>') for (1..$level);
}
sub stop_nesting {
    my $self = shift;
    my $level = shift || 1 ;
    $self->raw('</blockquote>') for (1..$level);
}

1;


