package Pod::PseudoPod::XHTML;

# ABSTRACT: format PseudoPod as valid XHTML

use warnings;
use strict;

use base qw( Pod::PseudoPod::HTML );

use Carp;

our $VERSION = '1.02'; # VERSION

sub new {

  my $self = shift;
  my $new  = $self->SUPER::new( @_ );

  $new->accept_targets( 'xhtml', 'XHTML' );
  $new->dtd_strict;

  return $new;

}

{  # These definitions are found at http://www.w3.org/TR/xhtml1/#strict

  my %dtd = (

    # XHTML 1.0 - Strict

    'strict' => q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
},

    # XHTML 1.0 - Transitional

    'transitional' => q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
},
  );

  sub _set_dtd {

    my ( $self, $type ) = @_;

    croak "unknown dtd ($type)" unless exists $dtd{ $type };

    $self->{ 'dtd' } = $type;

  }

  sub _get_dtd {

    my $self = shift;

    croak "unknown dtd ($self->{ 'dtd' })" unless exists $self->{ 'dtd' };

    return $dtd{ $self->{ 'dtd' } };

  }
};

sub dtd_strict       { $_[ 0 ]->_set_dtd( 'strict' ) }
sub dtd_transitional { $_[ 0 ]->_set_dtd( 'transitional' ) }

sub start_Document {

  my $self = shift;

  if ( $self->{ 'body_tags' } ) {

    my $dtd = $self->_get_dtd;

    $self->{ 'scratch' } .= qq{<?xml version="1.0" encoding="UTF-8"?>
$dtd
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
};
    $self->{ 'scratch' } .= "<link rel='stylesheet' href='style.css' type='text/css' />\n" if $self->{ 'css_tags' };
    $self->{ 'scratch' } .= q{</head><body>};

    $self->emit( 'nowrap' );

  }
} ## end sub start_Document

# Override inherited functions to handle self-contained tags and proper closing of tags.

sub start_Para { $_[ 0 ]{ 'scratch' } .= '<p>' }

sub start_item_text {

  $_[ 0 ]{ 'scratch' } .= "</li>\n"
    if exists $_[ 0 ]{ 'li_opened' };

  $_[ 0 ]{ 'li_opened' }++;
  $_[ 0 ]{ 'scratch' } .= "<li>";

}

sub end_item_text { }
sub end_over_text { $_[ 0 ]{ 'scratch' } .= "</li>\n</ul>"; $_[ 0 ]->emit( 'nowrap' ) }

sub end_F { $_[ 0 ]{ 'scratch' } .= ( $_[ 0 ]{ 'in_figure' } ) ? '" />' : '</em>' }
sub end_Z { $_[ 0 ]{ 'scratch' } .= '" />' }

1;  # End of Pod::PseudoPod::XHTML


__END__
=pod

=head1 NAME

Pod::PseudoPod::XHTML - format PseudoPod as valid XHTML

=head1 VERSION

version 1.02

=head1 SYNOPSIS

  use Pod::PseudoPod::XHTML;

  my $parser = Pod::PseudoPod::XHTML->new();
  $parser->parse_file('path/to/file.pod');

=head1 DESCRIPTION

This class is a formatter that takes PseudoPod and renders it as
valid XHTML.

This is a subclass of L<Pod::PseudoPod::HTML>, and from there
L<Pod::PseudoPod>, and inherits all their methods.

This code has been shamelessly ripped off from L<Pod::PseudoPod::HTML> and
jmcnamara's work on the Modern Perl epub book generator and massaged to work.

=head1 NAME

=head1 EXPORT

Nothing is exported.

=head1 METHODS

=head2 dtd_strict

Use the Strict DTD. (Default)

=head2 dtd_transitional

Use the Transitional DTD.

=head1 SEE ALSO

L<Pod::PseudoPod::HTML>, L<Pod::PseudoPod>, L<Pod::Simple>

=head1 AUTHOR

Alan Young, C<< <harleypig at gmail.com> >>

=head1 BUGS

This project is hosted on github
(L<http://github.com/harleypig/Pod-PseudoPod-XHTML>).  I'll see any issues
submitted there much faster than anywhere else.

You may also report any bugs or feature requests to C<bug-pod-pseudopod-xhtml at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-PseudoPod-XHTML>.  I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pod::PseudoPod::XHTML

You can also look for information at:

=over 4

=item * github

L<http://github.com/harleypig/Pod-PseudoPod-XHTML>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-PseudoPod-XHTML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Pod-PseudoPod-XHTML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Pod-PseudoPod-XHTML>

=item * Search CPAN

L<http://search.cpan.org/dist/Pod-PseudoPod-XHTML/>

=back

=head1 ACKNOWLEDGEMENTS

jmcnamara, Allison Randall, Larry Wall, the whole perl community

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Alan Young.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=for Pod::Coverage end_F end_Z end_item_text end_over_text start_Document start_Para start_item_text

=head1 AUTHOR

Alan Young <harleypig@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Young.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

