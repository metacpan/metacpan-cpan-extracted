package Pod::Simple::XHTML::BlendedCode;

use 5.008001;
use warnings;
use strict;
use parent qw(Pod::Simple::XHTML);
use List::Util qw(first);
use Pod::Simple::XHTML::BlendedCode::Blender 1.000 qw();
use IO::String 1.08 qw();
use Carp qw(croak);

our $VERSION = '1.003';
$VERSION =~ s/_//ms;

sub new {
	my $self = shift;
	my $new  = $self->SUPER::new(@_);
	$new->_accessorize(
		'internal_modules_hash', 'internal_url_postfix',
		'internal_url_prefix',   'internal_url_divide_slashes',
	);
	$new->internal_url_divide_slashes(1);
	$new->internal_modules_hash( {} );
	return $new;
}

## We cheat by processing through a preprocessor first.

sub parse_file {
	my $self    = shift;
	my $in_file = shift;

	my $pod        = q{};
	my $pod_handle = IO::String->new($pod);

	my $preprocessor = Pod::Simple::XHTML::BlendedCode::Blender->new();
	$preprocessor->parseopts( '-want_nonPODs' => 1 );
	$preprocessor->parse_from_file( $in_file, $pod_handle );

	return $self->SUPER::parse_string_document($pod);
} ## end sub parse_file

sub parse_string_document {
	my $self      = shift;
	my $in_string = shift;

	my $in_handle = IO::String->new($in_string);

	my $pod        = q{};
	my $pod_handle = IO::String->new($pod);

	my $preprocessor = Pod::Simple::XHTML::BlendedCode::Blender->new();
	$preprocessor->parseopts( '-want_nonPODs' => 1 );
	$preprocessor->parse_from_file( $in_handle, $pod_handle );

	return $self->SUPER::parse_string_document($pod);
} ## end sub parse_string_document

sub resolve_pod_page_link {
	my ( $self, $to, $section ) = @_;

	croak
q{The parser's internal_modules_hash method is not returning a hashref}
	  if ( 'HASH' ne ref( $self->internal_modules_hash() ) );

	my $key;
	if ( defined $to ) {
		$key = first { $to =~ m{\A$_\z}ms }
		sort { $a cmp $b } keys %{ $self->internal_modules_hash() };
		return $self->SUPER::resolve_pod_page_link( $to, $section )
		  if not defined $key;
	} else {
		return $self->SUPER::resolve_pod_page_link( $to, $section );
	}

	my $processed_to;

	if ( $self->internal_url_divide_slashes() ) {
		$processed_to = $to;
		$processed_to =~ s{::}{/}msg;
	} else {
		$processed_to = encode_entities($to);
	}

	if ( defined $section ) {
		$section = q{#} . $self->idify( $section, 1 );
	} else {
		$section = q{};
	}

	return
	    ( $self->internal_url_prefix() || q{} )
	  . ( $self->internal_modules_hash->{$key} || q{} )
	  . $processed_to
	  . $section
	  . ( $self->internal_url_postfix() || q{} );
} ## end sub resolve_pod_page_link


1;                                     # Magic true value required at end of module
__END__

=pod

=begin readme text

Pod::Simple::XHTML::BlendedCode version 1.003

=end readme

=for readme stop

=head1 NAME

Pod::Simple::XHTML::BlendedCode - Blends syntax-highlighted code and pod in one XHTML document.

=head1 VERSION

This document describes Pod::Simple::XHTML::BlendedCode version 1.003

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

This method of installation will install a current version of Module::Build 
if it is not already installed.
    
Alternatively, to install with Module::Build, you can use the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

=end readme

=for readme stop

=head1 SYNOPSIS

    use Pod::Simple::XHTML::BlendedCode 1.003 qw();
	
	my $parser = Pod::Simple::XHTML::BlendedCode->new();

	# These routines are specific to Pod::Simple::XHTML::BlendedCode.
	$parser->internal_modules_hash({
		'Perl::Dist::WiX(.*)?'   => 'Perl-Dist-WiX/', # Key can be a regex.
		'Perl::Dist::VanillaWiX' => 'Perl-Dist-WiX/',
		'File::List::Object'     => 'File-List-Object/',
		'Alien::WiX'             => 'Alien-WiX/',
	});
	$parser->internal_url_postfix('.pm.html');
	$parser->internal_url_prefix('http://csjewell.comyr.com/perl/');
	$parser->internal_url_divide_slashes(1);

	# Since this is a subclass of Pod::Simple::XHTML,
	# you can use all of its routines.
	$parser->index(1);
	$parser->html_css('code.css');
	$parser->parse_file('Perl-Dist-WiX\\lib\\Perl\\Dist\\WiX.pm');

=head1 DESCRIPTION

This class is a formatter that takes Pod and Perl code and renders it as XHTML 
validating HTML.

This is a subclass of L<Pod::Simple::XHTML|Pod::Simple::XHTML> and inherits all 
its methods.

=head1 METHODS 

C<Pod::Simple::XHTML::BlendedCode> offers additional methods that modify 
the format of the HTML output. Call these after creating the parser object, 
but before the call to C<parse_file> or C<parse_string_document>:

  my $parser = Pod::Simple::XHTML::BlendedCode->new();
  $parser->set_optional_param("value");
  $parser->parse_file($file);

=head2 internal_modules_hash

This determines which modules are internal to your own web site.

The module names in C<< LE<lt>E<gt> >> links are compared against the
regular expressions (wrapped in C<< \A >> and C<< \z >>) that are contained 
in the keys. If no keys match, then normal link processing is used.

If a key matches, then it is considered a "site-internal" link and the 
value is appended to C<internal_url_prefix> for this link, and 
C<internal_url_divide_slashes> and C<internal_url_postfix> are also used 
when creating the link.

If you are putting all modules in one path (so that there are no 
per-distribution prefixes), set the values to the empty string.

This defaults to an empty hashref, and a hashref must be passed in.

=head2 internal_url_divide_slashes

If this is set to a true value, then slashes are used to divide the portions
of a module name in the URL generated for an internal link.

If not, then the module name is left as is.

=head2 internal_url_prefix

In turning an internal link to L<Foo::Bar|Foo::Bar> into 
L<http://whatever/Foo%3a%3aBar> or L<http://whatever/Foo/Bar>, what to put 
before the "Foo%3a%3aBar" or "Foo/Bar". This option is not set by default.

=head2 perldoc_url_postfix

What to put after "Foo%3a%3aBar" or "Foo/Bar" in the URL for an internal link. 
This option is not set by default.

=head1 DIAGNOSTICS

"The parser's internal_modules_hash method is not returning a hashref" will 
be croaked upon processing of the first pod link when the 
interal_modules_hash method was passed anything but a hashref previously.

Also, this module will report any diagnostic 
L<Pod::Simple::XHTML|Pod::Simple::XHTML> will, as well as any diagnostic 
that L<Pod::Parser|Pod::Parser> will during the blending process.

=head1 CONFIGURATION AND ENVIRONMENT
  
Pod::Simple::XHTML::BlendedCode requires no configuration files or 
environment variables.

=for readme continue

=head1 DEPENDENCIES

Perl 5.8.1 is the mimimum version of perl that this module will run on.

Other modules that this module depends on are 
L<Pod::Simple::XHTML|Pod::Simple::XHTML>, L<Pod::Parser|Pod::Parser>, 
L<PPI::HTML|PPI::HTML> 1.08, and L<parent|parent> 0.223.

=for readme stop

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS (SUPPORT)

No bugs have been reported.

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Simple-XHTML-BlendedCode>
if you have an account there.

2) Email to E<lt>bug-Pod-Simple-XHTML-BlendedCode@rt.cpan.orgE<gt> if you do not.

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=head1 SEE ALSO

L<http://csjewell.comyr.com/perl/> (for examples of the output of this module.)

=for readme continue

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Curtis Jewell C<< <csjewell@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic> 
and L<perlgpl|perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=for readme stop

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
