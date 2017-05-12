package Padre::Plugin::CSS;

use warnings;
use strict;

our $VERSION = '0.08';

use base 'Padre::Plugin';
use Padre::Wx ();
use Padre::Util   ('_T');

sub padre_interfaces {
	'Padre::Plugin'   => 0.26,
	'Padre::Document' => 0.21,
}

sub registered_documents {
	'text/css' => 'Padre::Document::CSS',
}

sub menu_plugins_simple {
    my $self = shift;
    
	return ('CSS' => [
		_T('CSS Minifier'),   sub { $self->css_minifier },
		_T('Validate CSS'),   sub { $self->validate_css },
	]);
}

sub validate_css {
	my ( $self ) = @_;
	my $main = $self->main;
	
	my $doc  = $main->current->document;
	my $code = $doc->text_get;
	
	unless ( $code and length($code) ) {
		Wx::MessageBox( _T('No Code'), _T('Error'), Wx::wxOK | Wx::wxCENTRE, $main );
	}
	
	require WebService::Validator::CSS::W3C;
	my $val = WebService::Validator::CSS::W3C->new();
	my $ok  = $val->validate(string => $code);

	if ($ok) {
		if ( $val->is_valid ) {
			$self->_output( _T("CSS is valid\n") );
		} else {
			my $error_text = _T("CSS is not valid\n");
			$error_text .= _T("Errors:\n");
			my @errors = $val->errors;
			foreach my $err (@errors) {
				my $message = $err->{message};
				$message =~ s/(^\s+|\s+$)//isg;
				$error_text .= " * $message ($err->{context}) at line $err->{line}\n";
			}
			$self->_output( $error_text );
		}
	} else {
		my $error_text = _T("Failed to validate the code\n");
		$self->_output( $error_text );
	}
}

sub _output {
	my ( $self, $text ) = @_;
	my $main = $self->main;
	
	$main->show_output(1);
	$main->output->clear;
	$main->output->AppendText($text);
}

sub css_minifier {
	my ( $self ) = @_;
	my $main = $self->main;

	my $src = $main->current->text;
	my $doc = $main->current->document;
	return unless $doc;
	my $code = $src ? $src : $doc->text_get;
	return unless ( defined $code and length($code) );

	require CSS::Minifier::XS;
	CSS::Minifier::XS->import('minify');
		
	my $css = minify( $code );
    
	if ( $src ) {
		my $editor = $main->current->editor;
		$editor->ReplaceSelection( $css );
	} else {
		$doc->text_set( $css );
	}
}

1;
__END__

=head1 NAME

Padre::Plugin::CSS - L<Padre> and CSS

=head1 CSS Minifier

use L<CSS::Minifier::XS> to minify css

=head1 Validate CSS

use L<WebService::Validator::CSS::W3C> to validate the CSS

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
