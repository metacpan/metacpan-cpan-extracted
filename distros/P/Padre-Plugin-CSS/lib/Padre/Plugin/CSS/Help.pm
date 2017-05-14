package Padre::Plugin::CSS::Help;
BEGIN {
  $Padre::Plugin::CSS::Help::VERSION = '0.14';
}

# ABSTRACT: CSS Help provider

use 5.008;
use strict;
use warnings;
use Carp       ();
use File::Spec ();
use YAML::Tiny qw(LoadFile);

use Padre::Help ();
use Padre::Util ();

our @ISA = 'Padre::Help';

my $data;

sub help_init {
	my ($self) = @_;

	my $help_file = File::Spec->catfile( Padre::Util::share('CSS'), 'css.yml' );
	$data = LoadFile($help_file);

	return;
}

sub help_list {
	my ($self) = @_;

	$self->help_init unless $data;
	return [ keys %{ $data->{topics} } ];
}

sub help_render {
	my ( $self, $topic ) = @_;

	#warn "'$topic'";
	$topic =~ s/://;
	my $html = "No help found for '$topic'";
	if ( $data->{topics}{$topic} ) {
		$html = "$topic $data->{topics}{$topic}";
		$html =~ s/REPLACE_(\w+)/$data->{replace}{$1}/g;
	}
	my $location = $topic;
	return ( $html, $location );
}

1;


__END__
=pod

=head1 NAME

Padre::Plugin::CSS::Help - CSS Help provider

=head1 VERSION

version 0.14

=head1 AUTHORS

=over 4

=item *

Fayland Lam <fayland@gmail.com>

=item *

Alexandr Ciornii <alexchorny@gmail.com>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

