package Perl6::Pod::Lib::Include;

=pod

=head1 NAME

Perl6::Pod::Block::Include - to include pod in the specified place

=head1 SYNOPSIS

    =Include t/data/P_test1.pod
   

=head1 DESCRIPTION

The B<=Include> block is used to include other Pod documents.
The target file is defined by a URI:

    =Include ../intro.pod

=cut

use warnings;
use strict;
use Perl6::Pod::Block;
use base 'Perl6::Pod::Block';
use Perl6::Pod::Utl;
use open ':utf8';
our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    my $path  = $self->childs->[0];
    $path =~ s/^\s*//;
    $path =~ s/\s*$//;

    #now translate relative addr
    if ( $path !~ /^\//
        and my $current = $self->context->custom->{src} )
    {
        my ( $file, @cpath ) = reverse split( /\//, $current );
        my $cpath = join "/", reverse @cpath;
        $path = $cpath ? $cpath . "/" . $path : $path;
    }

    open( FH, "<", $path ) or die "=Include: Eror open file:$path $!";
    my $txt = '';
    { local $/ = undef; $txt = <FH>; }
    close FH;
    
    #make tree
    my $tree = Perl6::Pod::Utl::parse_pod( $txt, default_pod => 1 )
      or die "Can't parse $path";
    $self->childs($tree);

    #save PATH
    $self->{PATH} = $path;
    $self;
}

sub to_xhtml {
    my ( $self, $to ) = @_;
    my $old = $to->context->custom->{src};
    $to->context->custom->{src} = $self->{PATH};
    $to->visit_childs($self);
    $to->context->custom->{src} = $old;
}

sub to_docbook {
    my ( $self, $to ) = @_;
    my $old = $to->context->custom->{src};
    $to->context->custom->{src} = $self->{PATH};
    $to->visit_childs($self);
    $to->context->custom->{src} = $old;

}
sub to_latex {
    my ( $self, $to ) = @_;
    my $old = $to->context->custom->{src};
    $to->context->custom->{src} = $self->{PATH};
    $to->visit_childs($self);
    $to->context->custom->{src} = $old;

}

1;

__END__


=head1 SEE ALSO

L<http://perlcabal.org/syn/S26.html>,

Samples of B<=Include>: L<https://github.com/zag/webdao/blob/master/contrib/webdao-book.pod6>, L<https://raw.github.com/zag/ru-perl6-book/master/perl6-book.pod>


=head1 AUTHOR

Zahatski Aliaksandr <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

