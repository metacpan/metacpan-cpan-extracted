use strict; use warnings;

package Pod::Readme::Brief;
our $VERSION = '1.002';

use Pod::Text;

sub new { my $class = shift; bless [ split /(?<=\n)/, ( join '', @_ ), -1 ], $class }

sub find_pod_section {
	my ( $self, $section, $do_loose ) = ( shift, @_ );
	my $rx = $do_loose ? ".*?(?i:$section)" : "+(?i:$section)\$";
	my @match = grep /^=head1\s$rx/ ... /^=head1\s/, @$self, "=head1 BUFFER STOP\n";
	pop @match;
	die "$section heading not found in POD\n" unless @match;
	@match;
}

sub render {
	my ( $self, %arg ) = ( shift, @_ );

	my ( $name, @ambiguous ) = grep s/ - .*//s, $self->find_pod_section( NAME => 0 );
	die "Could not parse NAME from the POD\n" unless defined $name and not @ambiguous;

	s/\A\s+//, s/\s+\z// for $name;
	die "Bad module name $name\n" unless $name =~ /\A\w+(?:::\w+)*\z/;

	my @pod = $self->find_pod_section( DESCRIPTION => 0 );
	$pod[0] =~ s/\s.*/ $name/;

	( push @pod, $_ ), $pod[-1] =~ s!^\t!!mg for <<'__HERE__';
	=head1 INSTALLATION

	This is a Perl module distribution. It should be installed with whichever
	tool you use to manage your installation of Perl, e.g. any of

	  cpanm .
	  cpan  .
	  cpanp -i .

	Consult http://www.cpan.org/modules/INSTALL.html for further instruction.
__HERE__

	my $installer = $arg{'installer'};
	( push @pod, $_ ), $pod[-1] =~ s!^\t!!mg for $installer ? <<"__HERE__" : "\n";
	Should you wish to install this module manually, the procedure is
	${ $installer eq 'eumm' ? \'
	  perl Makefile.PL
	  make
	  make test
	  make install
	' : $installer eq 'mb' ? \'
	  perl Build.PL
	  ./Build
	  ./Build test
	  ./Build install
	' : die "Unknown installer $installer\n" }
__HERE__

	push @pod, $self->find_pod_section( LICENSE => 1 );

	my ( $pod, $text ) = join '', "=pod\n\n", @pod;

	open my $in,  '<', \$pod  or die $!;
	open my $out, '>', \$text or die $!;
	my $parser = Pod::Text->new( loose => 1, width => 73, indent => 0 );
	$parser->parse_from_filehandle( $in, $out );
	$text =~ s{\n+\z}{\n};

	$text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Readme::Brief - A short simple README with just the essentials

=head1 SYNOPSIS

 my $readme = Pod::Readme::Brief->new( do {
     open my $fh, '<', __FILE__ or die $!;
     readline $fh;
 } );
 
 my $installer
     = -e 'Makefile.PL' ? 'eumm'
     : -e 'Build.PL'    ? 'mb'
     : undef;
 
 print $readme->render( installer => $installer );

=head1 DESCRIPTION

This module creates a brief README from a POD document (presumably the main
module of a distribution) with just the information relevant to the audience
who would even look inside such a README: non-Perl people. This is intended
as a sensible boilerplate generated README, unlike the usual tick-the-box
approaches that do not actually help anyone (such as just converting the entire
documentation of the the main module to text, or putting in just the name and
abstract of the distribution).

The following information goes into such a README:

=over 2

=item *

The C<NAME> of the module

=item *

The content of the C<DESCRIPTION> section

=item *

Simple installation instructions

=item *

The content of the C<LICENSE> section

=back

=head1 INTERFACE

=head2 C<new>

Creates an instance of the class from a string or a list of lines,
which must contain a well-formed full POD document,
either by itself or embedded in Perl code.

=head2 C<render>

Renders the README. Takes the following named arguments:

=over 4

=item C<installer>

Specifies what manual installation instructions should be included, if any.
(Instructions involving a CPAN client are always included.)

The value may be one of
C<eumm> (for a distribution using C<Makefile.PL>),
C<mb> (for a distribution using C<Build.PL>),
or a false value (to omit manual installation instructions).

=back

=head1 SEE ALSO

L<Dist::Zilla::Plugin::Readme::Brief>

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
