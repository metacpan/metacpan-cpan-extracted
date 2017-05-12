package Template::Plugin::Monta;
use strict;
use base qw/Template::Plugin::Filter/;
use vars qw/$VERSION $DYNAMIC $FILTER_NAME/;
use Acme::Monta;

$VERSION = 0.03;
$DYNAMIC = 1;
$FILTER_NAME = 'monta';

my @setting_params  = qw/
	start end open_font open_back close_font
	close_back close_img replace_tag cursor
/;

sub init {
	my($self, $args) = @_;
	my $name = $self->{_ARGS}->[0] || $FILTER_NAME;
	$self->install_filter($name);
	return $self;
}

sub _param_check {
	my $key = shift;
	foreach(@setting_params){
		return 1 if($key eq $_);
	}
	return undef;
}

sub filter {
	my($self, $text, $args, $config) = @_;
	my $monta = Acme::Monta->new(
		map { ( $_ => $config->{$_} ) }
		grep{ _param_check($_) }
		keys %$config
	);
	return $monta->montaize($text);
}

1;
__END__

=head1 NAME

Template::Plugin::Monta - TT2 Filter, Acme::Monta adaptor 

=head1 SYNOPSIS

  [% USE Monta %]
  
  [% FILTER $Monta close_font => '#0f0', close_back => '#0f0' %]
  <monta>Let's Montaize!</monta>
  [% END %]

  [% FILTER monta %]
  <monta>some string</monta>
  [% END %]

  [% some_string = '<monta>some string</monta>' %]
  [% some_string | monta %]

=head1 DESCRIPTION

This is a Filter for Template-Toolkit.
This modules allows you to use monta-method on your template.
See details in Acme::Monta's documents.

=head1 SEE ALSO

L<Acme::Monta>

=head1 AUTHOR

Lyo Kato, E<lt>kato@lost-season.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Lyo Kato

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
