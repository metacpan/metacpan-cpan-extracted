package Net::Curl::Simple::Form;

use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use Net::Curl::Form;
use base qw(Net::Curl::Form);

our $VERSION = '0.13';

{
	my %optcache;

	sub add
	{
		my $form = shift;

		my @args;
		while ( my ( $opt, $val ) = splice @_, 0, 2 ) {
			unless ( looks_like_number( $opt ) ) {
				# convert option name to option number
				unless ( exists $optcache{ $opt } ) {
					eval '$optcache{ $opt } = '
						. "Net::Curl::Form::CURLFORM_COPY\U$opt";
					eval '$optcache{ $opt } = '
						. "Net::Curl::Form::CURLFORM_\U$opt"
						if $@;
					die "unrecognized literal option: $opt\n"
						if $@;
				}
				$opt = $optcache{ $opt };
			}

			push @args, $opt, $val;
		}

		$form->SUPER::add( @args );

		# allow chaining
		return $form;
	}
}

sub contents
{
	my ( $form, $name, $contents ) = @_;
	$form->add( name => $name, contents => $contents );
}

sub file
{
	my $form = shift;
	$form->add( name => shift, map +( file => $_ ), @_ );
}

1;

__END__

=head1 NAME

Net::Curl::Simple::Form - simplify Net::Curl::Form a little

=head1 SYNOPSIS

 use Net::Curl::Simple;
 use Net::Curl::Simple::Form;

 my $form = Net::Curl::Simple::Form->new();
 $form->contents( foo => "bar" )->file( photos => glob "*.jpg" );
 $form->add( name => "html", contents => "<html></html>",
     contenttype => "text/html" );

 Net::Curl::Simple->new->post( $uri, \&finished, $form );

=head1 DESCRIPTION

C<Net::Curl::Simple::Form> is a thin layer over L<Net::Curl::Form>.
It simplifies common tasks, while providing access to full power of
L<Net::Curl::Form> when its needed.

=head1 CONSTRUCTOR

=over

=item new

Creates an empty multipart/formdata object.

 my $form = Net::Curl::Simple::Form->new;

=back

=head1 METHODS

=over

=item add( OPTIONS )

Adds a section to this form. Behaves in the same way as add() from
L<Net::Curl::Form> but also accepts literal option names. Returns its own
object to allow chaining.

=item contents( NAME, CONTENTS )

Shortcut for add( name => NAME, contents => CONTENTS ).

=item file( NAME, FILE1, [FILE2, [...] ] )

Shortcut for add( name => NAME, file => FILE1, file => FILE2, ... ).

=back

=head1 SEE ALSO

L<Net::Curl::Simple>
L<Net::Curl::Form>
L<curl_formadd(3)>

=head1 COPYRIGHT

Copyright (c) 2011 Przemyslaw Iskra <sparky at pld-linux.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as perl itself.

=cut

# vim: ts=4:sw=4
