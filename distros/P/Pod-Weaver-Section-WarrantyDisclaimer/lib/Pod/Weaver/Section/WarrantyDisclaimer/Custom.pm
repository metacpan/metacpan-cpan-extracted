use strict;
use warnings;

package Pod::Weaver::Section::WarrantyDisclaimer::Custom;
{
  $Pod::Weaver::Section::WarrantyDisclaimer::Custom::VERSION = '0.121290';
}
use Moose;
extends "Pod::Weaver::Section::WarrantyDisclaimer";
# ABSTRACT: Specify a custom warranty section


has 'title' => (
    is => 'ro',
    isa => 'Str',
    default => '',
);


has 'text' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);

around warranty_section_title => sub {
    my $orig = shift;
    my $self = shift;
    # Use the standard title if not specified.
    return $self->title || $self->$orig(@_);
};

around warranty_text => sub {
    my $orig = shift;
    my $self = shift;
    # If no text is specified, use the default
    if (@{ $self->text}) {
        return join( "\n", @{ $self->text } );
    }
    else {
        return $self->$orig(@_);
    }
};

1;



=pod

=head1 NAME

Pod::Weaver::Section::WarrantyDisclaimer::Custom - Specify a custom warranty section

=head1 VERSION

version 0.121290

=head1 SYNOPSIS

In F<weaver.ini>, probably near the end:

    [WarrantyDisclaimer::Custom]
    title = "WARRANTY"
    text = "First line of warranty text"
    text = "Second line of text"

=head1 OVERVIEW

This section plugin will add a warranty section to your POD, with a
custom title and text. You can use this to add your own license's
warranty to your code if you are using a license for which a warranty
moduel is not already available.

If not specified, the default title and text are the same as if you
just put `[WarrantyDisclaimer]` in weaver.ini.

=head1 ATTRIBUTES

=head2 title

Specify your own section title.

=head2 text

Specify your own warranty as text.

Default: none

Since you can't put newlines in weaver.ini you can specify this option
multiple times:

  text = My Default Foo Warranty
  text = Second line of warranty
  text = ...
  text = Last line of warranty

=for Pod::Coverage mvp_multivalue_args

sub mvp_multivalue_args { qw( text ) }

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Ryan C. Thompson <rct@thompsonclan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ryan C. Thompson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__

