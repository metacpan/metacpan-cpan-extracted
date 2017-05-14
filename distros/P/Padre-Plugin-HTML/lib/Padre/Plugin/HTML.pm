package Padre::Plugin::HTML;
BEGIN {
  $Padre::Plugin::HTML::VERSION = '0.14';
}

# ABSTRACT: HTML Support for Padre

use warnings;
use strict;

use base 'Padre::Plugin';
use Padre::Wx ();

sub padre_interfaces {
	'Padre::Plugin' => 0.47, 'Padre::Document' => 0.47,;
}

sub registered_documents {
	'text/html' => 'Padre::Plugin::HTML::Document',;
}

sub menu_plugins_simple {
	my $self = shift;
	return (
		Wx::gettext('HTML') => [
			Wx::gettext('Tidy HTML'),
			sub { $self->tidy_html },
			Wx::gettext('HTML Lint'),
			sub { $self->html_lint },
			Wx::gettext('Validate HTML'),
			sub { $self->validate_html },
			Wx::gettext('Docs') => [
				Wx::gettext('HTML 4.01 Specification'),
				sub { Padre::Wx::launch_browser('http://www.w3.org/TR/html401/'); },
			],
		]
	);
}

sub validate_html {
	my ($self) = @_;
	my $main = $self->main;

	my $doc  = $main->current->document;
	my $code = $doc->text_get;

	unless ( $code and length($code) ) {
		Wx::MessageBox( 'No Code', 'Error', Wx::wxOK | Wx::wxCENTRE, $main );
	}

	require WebService::Validator::HTML::W3C;
	my $v = WebService::Validator::HTML::W3C->new( detailed => 1 );

	if ( $v->validate_markup($code) ) {
		if ( $v->is_valid ) {
			$self->_output("HTML is valid\n");
		} else {
			my $error_text = "HTML is not valid\n";
			foreach my $error ( @{ $v->errors } ) {
				$error_text .= sprintf( "%s at line %d\n", $error->msg, $error->line );
			}
			$self->_output($error_text);
		}
	} else {
		my $error_text = sprintf( "Failed to validate the code: %s\n", $v->validator_error );
		$self->_output($error_text);
	}
}

sub _output {
	my ( $self, $text ) = @_;
	my $main = $self->main;

	$main->show_output(1);
	$main->output->clear;
	$main->output->AppendText($text);
}

sub tidy_html {
	my ($self) = @_;
	my $main = $self->main;

	my $src = $main->current->text;
	my $doc = $main->current->document;
	return unless $doc;
	my $code = ($src) ? $src : $doc->text_get;

	return unless ( defined $code and length($code) );

	require HTML::Tidy;
	my $tidy = HTML::Tidy->new;

	my $cleaned_code = $tidy->clean($code);

	my $text;
	for my $message ( $tidy->messages ) {
		$text .= $message->as_string . "\n";
	}

	$text = 'OK' unless ( length($text) );
	$self->_output($text);

	if ($src) {
		my $editor = $main->current->editor;
		$editor->ReplaceSelection($cleaned_code);
	} else {
		$doc->text_set($cleaned_code);
	}
}

sub html_lint {
	my ($self) = @_;
	my $main = $self->main;

	my $src = $main->current->text;
	my $doc = $main->current->document;
	return unless $doc;
	my $code = ($src) ? $src : $doc->text_get;

	return unless ( defined $code and length($code) );

	require HTML::Lint;
	my $lint = HTML::Lint->new;

	$lint->parse($code);

	my $text;
	my $error_count = $lint->errors;

	foreach my $error ( $lint->errors ) {
		$text .= $error->as_string . "\n";
	}

	$text = 'OK' unless ( length($text) );
	$self->_output($text);
}

1;


=pod

=head1 NAME

Padre::Plugin::HTML - HTML Support for Padre

=head1 VERSION

version 0.14

=head1 Validate HTML

use L<WebService::Validator::HTML::W3C> to validate the HTML

=head1 Tidy HTML

use L<HTML::Tidy> to tidy HTML

=head1 HTML Lint

use L<HTML::Lint> to ?????

=head1 AUTHORS

=over 4

=item *

Fayland Lam <fayland@gmail.com>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

