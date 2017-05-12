package Padre::Plugin::PerlCritic;
BEGIN {
  $Padre::Plugin::PerlCritic::VERSION = '0.12';
}

# ABSTRACT: Analyze perl files with Perl::Critic

use 5.008;
use strict;
use warnings;
use Padre::Wx     ();
use Padre::Plugin ();

our @ISA = 'Padre::Plugin';

sub padre_interfaces {
	'Padre::Plugin' => '0.47',;
}

sub plugin_name {
	Wx::gettext('Perl Critic');
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('Perl::Critic Current Document') => sub {
			$self->critic(@_);
			}
	];
}

sub critic {
	my $self    = shift;
	my $current = $self->current;
	$DB::single = 1;

	# Get the document to critique
	my $document = $current->document or return;
	unless ( $document->isa('Padre::Document::Perl') ) {
		return Wx::MessageBox(
			Wx::gettext('Document is not a Perl document'),
			Wx::gettext('Error'),
			Wx::wxOK | Wx::wxCENTRE,
			$self,
		);
	}
	my $text = $document->text_get;
	return unless defined $text;

	# Do we have a project-specific configuration
	my $project           = $document->project;
	my $config            = $project->config;
	my $config_perlcritic = $config->config_perlcritic;
	my @params =
		$config_perlcritic
		? ( -profile => $config_perlcritic )
		: ();

	# Open and start output from the critic run
	my $main   = $current->main;
	my $output = $main->output;
	$output->clear;
	$main->show_output(1);
	if (@params) {
		$output->AppendText(
			sprintf( Wx::gettext('Perl::Critic running with project-specific configuration %s'), $config_perlcritic )
				. "\n" );
	} else {
		$output->AppendText( Wx::gettext("Perl\::Critic running with default or user configuration") . "\n" );
	}

	# Hand off to Perl::Critic
	require Perl::Critic;
	my $critic     = Perl::Critic->new(@params);
	my @violations = $critic->critique( \$text );

	# Write the results to the Output window
	if (@violations) {
		$output->AppendText( join '', @violations );
	} else {
		$output->AppendText( Wx::gettext('Perl::Critic found nothing to say about this code') . "\n" );
	}

	return;
}

1;



=pod

=head1 NAME

Padre::Plugin::PerlCritic - Analyze perl files with Perl::Critic

=head1 VERSION

version 0.12

=head1 SYNOPSIS

This is a simple plugin to run Perl::Critic on your source code.

Currently there is no configuration for this plugin, so you have to rely
on the default .perlcriticrc configuration. See Perl::Critic for details.

=head1 AUTHORS

=over 4

=item *

Kaare Rasmussen <kaare@cpan.org>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Kaare Rasmussen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

