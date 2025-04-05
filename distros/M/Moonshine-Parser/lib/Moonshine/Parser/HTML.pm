package Moonshine::Parser::HTML;

use strict;
use warnings;

use base qw/HTML::Parser/;

use Moonshine::Element;

=head1 NAME

Moonshine::Parser::HTML - Parse html into a Moonshine::Element object. 

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

sub new {
    my $class = shift;
    my $self  = bless {
    	elements => [ ],
	closed => [ ],
	base_element => undef,	
    }, $class;
    $self->SUPER::init(@_);
}

=head1 SYNOPSIS

    use Moonshine::Parser::HTML;

    my $parser = Moonshine::Parser::HTML:->new();
    my $moonshine_element = $parser->parse($html);

=head1 SUBROUTINES/METHODS

=head2 parse

Parse html string into a Moonshine::Element Object.

=cut

sub parse {
    my ( $self, $data ) = @_;
 
    $self->SUPER::parse($data);

    return $self->{base_element};
}

=head2 parse_file

Parse a file that contains html into a Moonshine::Element.

=cut

sub parse_file {
    my ( $self, $file ) = @_;

    $self->SUPER::parse_file($file);

    return $self->{base_element};
}

sub start {
    my ( $self, $tag, $attr) = @_;
    my $closed = delete $attr->{'/'};
   
    $attr->{tag} = lc $tag;
    $attr->{data} = [ ];
    
    my $element;
    if ( my $current_element = $self->_current_element ) {
        $element = $current_element->add_child($attr);
    }
    else {
        $element = Moonshine::Element->new($attr);
        if ( my $base_element = $self->{base_element} ) {
            my $action =
              $self->_is_closed( $base_element->{guid} )
              ? 'add_after_element'
              : 'add_child';
            $base_element->$action($element);
        }
        else {
            $self->{base_element} = $element;
        }
    }
    push @{ $self->{elements} }, $element
        unless $closed;
}

sub text {
    my ( $self, $text ) = @_;
    if ( $text =~ m{\S+}xms ) {
        my $element = $self->_current_element;
        $text =~ s{^\s+|\s+$}{}g;
        
        if ($element->has_children) {
            my $data = $element->children;
            push @{ $element->{data} }, @{ $data };
            $element->children([]);
        }
        
        $element->data($text);
    }
}

sub end {
    my ( $self, $tag, $origtext ) = @_;
    my $close = pop @{ $self->{elements} };
    push @{ $self->{closed} }, $close->{guid};
}

sub _current_element {
    my $count = scalar @{ $_[0]->{elements} };
    return $_[0]->{elements}[ $count - 1 ];
}

sub _is_closed {
    return grep { $_ =~ m/^$_[1]$/ } @{ $_[0]->{closed} };
}

=head1 AUTHOR

Robert Acock, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moonshine-parser at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Moonshine-Parser>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Moonshine::Parser

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Moonshine-Parser>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Moonshine-Parser>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Moonshine-Parser>

=item * Search CPAN

L<http://search.cpan.org/dist/Moonshine-Parser/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;    # End of Moonshine::Parser
