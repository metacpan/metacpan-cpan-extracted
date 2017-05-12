## ----------------------------------------------------------------------------
#  String::Gsub
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
package String::Gsub;
use warnings;
use strict;

use String::Gsub::Functions;
use base qw(Exporter);
use overload q|""| => \&stringy;
our @EXPORT_OK = qw(gstr);

our $VERSION = '0.04';


1;

# -----------------------------------------------------------------------------
# gstr($str).
#
sub gstr($)
{
	__PACKAGE__->new(shift);
}

# -----------------------------------------------------------------------------
# $pkg->new($str).
#
sub new
{
	my $pkg = shift;
	my $str = shift;
	bless {s=>$str}, $pkg;
}

# -----------------------------------------------------------------------------
# $gstr->gsubx($regex, $replacement);
#   $regex is qr// or "string".
#   $replacement is sub{} or "string".
#
sub gsubx
{
	my $this = shift;
	my $re = shift;
	my $sub = shift;
	
	&String::Gsub::Functions::gsubx($this->{s}, $re, $sub, @_);
	$this;
}

# -----------------------------------------------------------------------------
# $gstr->gsub($regex, $replacement);
#   $regex is qr// or "string".
#   $replacement is sub{} or "string".
#
sub gsub
{
	my $this = shift;
	my $re = shift;
	my $sub = shift;
	
	gstr(&String::Gsub::Functions::gsub($this->{s}, $re, $sub, @_));
}

# -----------------------------------------------------------------------------
# $gstr->subx($regex, $replacement);
#   $regex is qr// or "string".
#   $replacement is sub{} or "string".
#
sub subx
{
	my $this = shift;
	my $re = shift;
	my $sub = shift;
	
	&String::Gsub::Functions::subsx($this->{s}, $re, $sub, @_);
	$this;
}

# -----------------------------------------------------------------------------
# $gstr->sub($regex, $replacement);
#   $regex is qr// or "string".
#   $replacement is sub{} or "string".
#
sub sub
{
	my $this = shift;
	my $re = shift;
	my $sub = shift;
	
	gstr(&String::Gsub::Functions::subs($this->{s}, $re, $sub, @_));
}

# -----------------------------------------------------------------------------
# $gstr->stringy()
#   return string contained in.
#
sub stringy
{
	my $this = shift;
	$this->{s};
}

__END__

=head1 NAME

String::Gsub - regex on string object

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

 use String::Gsub qw(gstr);
 
 print gstr("abcabc")->gsub(qr/b/,sub{uc$1}); # ==> "aBcaBc"
 print gstr("hw")->gsub(qr/h/,"Hello")->gsub(qr/w/,"World"); # ==> "HelloWorld"

=head1 EXPORT

This module can export C<gstr>.
No functions are exported by default.

=head1 FUNCTIONS

=head2 gstr($str)

Alias for C<< String::Gsub-E<gt>new($str) >>;

=head1 METHODS

=head2 $pkg->new($str)

Create new instance.

=head2 $this->gsub($regexp, $replacement)

process global substitute, and return new object.

=head2 $this->gsubx($regexp, $replacement)

like gsub, but replace self object and return itself.

=head2 $this->sub($regexp, $replacement)

process one substitute, and return new object.

=head2 $this->subx($regexp, $replacement)

like sub, but replace self object and return itself.

=head2 $this->stringy()

returns string value contained in.

=head1 AUTHOR

YAMASHINA Hio, C<< <hio at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-string-gsub at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-Gsub>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::Gsub

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/String-Gsub>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/String-Gsub>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-Gsub>

=item * Search CPAN

L<http://search.cpan.org/dist/String-Gsub>

=back

=head1 SEE ALSO

L<String::Gsub>, L<String::Gsub::Functions>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 YAMASHINA Hio, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
