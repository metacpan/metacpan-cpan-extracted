package Padre::Plugin::REPL;

use warnings;
use strict;

sub BEGIN {
	$ENV{PERL_RL} = "Stub";
	$INC{'Term/ReadLine/Stub.pm'} = '/usr/share/perl/5.10/Term/ReadLine.pm';
}

use base 'Padre::Plugin';
use Padre::Wx;
use Padre::Util qw/_T/;
use Devel::REPL;
use Capture::Tiny qw/capture_merged/;
use Devel::REPL::Script;
use Class::Unload;
use Padre::Plugin::REPL::Panel;
use Padre::Plugin::REPL::History;

our $VERSION = '0.01';

our $repl;
our ( $input, $output );

sub make_panel {
	( $input, $output ) = Padre::Plugin::REPL::Panel->new();
}

sub padre_interfaces {
	return 'Padre::Plugin' => '0.26';
}

sub menu_plugins_simple_DISABLED {
	return "REPL" => [
		( ('Evaluate something') . "\tCtrl+e" ) => \&dialog,    ### _T
	];
}

sub plugin_enable {
	_init_repl();
}

sub plugin_disable {
	Class::Unload->unload('Padre::Plugin::REPL::History');
	Class::Unload->unload('Padre::Plugin::REPL::Panel');
}

sub dialog {
	my $code = Wx::GetTextFromUser("What do you want to evaluate?");
	my $res  = _eval_repl($code);
	Padre::Current->main->output->AppendText("# $code\n$res\n");
	Padre::Current->main->show_output(1);
}

sub set_text {
	$input->SetValue(shift);
	$input->SetInsertionPointEnd();
}

sub get_text {
	$input->GetValue();
}

sub evaluate {
	my $code = $input->GetValue();
	my $res  = _eval_repl($code);
	Padre::Plugin::REPL::History::evalled();
	$output->AppendText("# $code\n$res\n");
}

sub _init_repl {
	return if ( defined($repl) );
	make_panel();
	my $temp = Devel::REPL::Script->new();
	$repl = $temp->_repl();
	$temp->load_profile( $temp->profile );
	$temp->load_rcfile( $temp->rcfile );
	$repl->out_fh( \*STDOUT );
	Padre::Plugin::REPL::History::init();
}

sub _eval_repl {
	my $code = shift;
	my $res  = capture_merged {
		$repl->print( $repl->formatted_eval($code) );
	};
	return $res;
}

=head1 NAME

Padre::Plugin::REPL - read-evaluate-print plugin for Padre

=head1 SYNOPSIS

This plugin will ask you for some code, evaluate it, and show you its output and what it returned.

Since this uses L<Devel::REPL>, most of its plugins can be used in the same way as usual.

=head1 AUTHOR

Ryan Niebur, C<< <ryanryan52 at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ryan Niebur, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
