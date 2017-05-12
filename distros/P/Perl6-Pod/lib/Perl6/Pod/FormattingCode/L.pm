package Perl6::Pod::FormattingCode::L;

=pod

=head1 NAME

Perl6::Pod::FormattingCode::L - handle "L" formatting code

=head1 SYNOPSIS

A standard web URL. For example:

    This module needs the LAME library
    (available from L<http://www.mp3dev.org/mp3/>)


=head1 DESCRIPTION

The L<> code is used to specify all kinds of links, filenames, citations, and cross-references (both internal and external).

A link specification consists of a scheme specifier terminated by a colon, followed by an external address (in the scheme's preferred syntax), followed by an internal address (again, in the scheme's syntax). All three components are optional, though at least one must be present in any link specification.

Usually, in schemes where an internal address makes sense, it will be separated from the preceding external address by a #, unless the particular addressing scheme requires some other syntax. When new addressing schemes are created specifically for Perldoc it is strongly recommended that # be used to mark the start of internal addresses. 

=cut

use warnings;
use strict;
use Data::Dumper;
use Perl6::Pod::FormattingCode;
use base 'Perl6::Pod::FormattingCode';
use Perl6::Pod::Utl;
our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    #parse conntent
    if (0) {
      my $txt = $self->{'content'};
      ( $self->{alt_text}, $txt ) =  split( /\s*\|\s*/, $txt ) if $txt =~/\|/; 
      #cut scheme
      if ( $txt =~s/^\s*(\w+):// ) {
        $self->{scheme} = $1;
      }
      #is_external
      if ( $txt =~ s%^//%%) {
        $self->{is_external}='//'
      }
      #cut address
      if ($txt =~ /([^\#]*)(?:\#(.*))?/) {
            $self->{address} = $1 ||'';
            $self->{section} = $2 || '';
      }
    }
    return $self;
}

sub to_xhtml {
    my ( $self, $to ) = @_;
    my $w  = $to->w;
    my $scheme = $self->{scheme}|| '';
    if (  ( $scheme =~ /^https?|.*$/ ) or $self->{section} ) {
                my $url = $self->{address} || ''; 
                $url .= "#" . $self->{section} if $self->{section};
                $url = $self->{scheme} .  ($scheme =~ /^https?/ ? '//' : '') . $url if $self->{is_external} || ($self->{scheme} && $self->{scheme} eq 'mailto:');
                $w->raw('<a href="')->print($url)->raw('">');
                unless  ( $self->{alt_text}) {
                            $w->print($url)
                } else {
                    $to->visit(Perl6::Pod::Utl::parse_para($self->{alt_text}))
                }
                $w->raw('</a>');
      }
}

sub to_docbook {
    my ( $self, $to ) = @_;
    my $w  = $to->w;
    my $scheme = $self->{scheme}|| '';
    if (  ( $scheme =~ /^https?|.*$/ ) or $self->{section} ) {
                my $url = $self->{address} || ''; 
                $url .= "#" . $self->{section} if $self->{section};
                $url = $self->{scheme} .  ($scheme =~ /^https?/ ? '//' : '') . $url if $self->{is_external} || ($self->{scheme} && $self->{scheme} eq 'mailto:');
                $w->raw('<ulink url="')->print($url)->raw('">');
                unless  ( $self->{alt_text}) {
                            $w->print($url)
                } else {
                    $to->visit(Perl6::Pod::Utl::parse_para($self->{alt_text}))
                }
                $w->raw('</ulink>');
      }
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

