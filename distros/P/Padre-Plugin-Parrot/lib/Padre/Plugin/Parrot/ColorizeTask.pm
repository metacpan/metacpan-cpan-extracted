package Padre::Plugin::Parrot::ColorizeTask;
BEGIN {
  $Padre::Plugin::Parrot::ColorizeTask::VERSION = '0.31';
}

# ABSTRACT: A Colorizer Task

use strict;
use warnings;
use base 'Padre::Task';
use Scalar::Util ();

our $thread_running = 0;

# This is run in the main thread before being handed
# off to a worker (background) thread. The Wx GUI can be
# polled for information here.
# If you don't need it, just inherit this default no-op.
sub prepare {
	my $self = shift;

	# it is not running yet.
	$self->{broken} = 0;

	return if $self->{_editor};
	$self->{_editor} = Scalar::Util::refaddr( Padre::Current->editor );

	# assign a place in the work queue
	if ($thread_running) {

		# single thread instance at a time please. aborting...
		$self->{broken} = 1;
		return "break";
	}
	$thread_running = 1;
	return 1;
}

sub is_broken {
	my $self = shift;
	return $self->{broken};
}

# used for coloring by parrot
my %colors = (

	# Perl 6
	quote_expression    => Padre::Constant::PADRE_BLUE,
	parse               => undef,
	statement_block     => undef,
	statementlist       => undef,
	statement           => undef,
	expr                => undef,
	'term:'             => undef,
	noun                => undef,
	value               => undef,
	quote               => undef,
	quote_concat        => undef,
	quote_term          => undef,
	quote_literal       => undef,
	post                => Padre::Constant::PADRE_MAGENTA,
	dotty               => undef,
	dottyop             => undef,
	methodop            => Padre::Constant::PADRE_GREEN,
	name                => Padre::Constant::PADRE_GREEN,
	identifier          => undef,
	term                => undef,
	args                => undef,
	arglist             => undef,
	EXPR                => undef,
	statement_control   => undef,
	use_statement       => undef,
	sym                 => Padre::Constant::PADRE_RED,
	'infix:='           => Padre::Constant::PADRE_GREEN,
	'infix:+'           => Padre::Constant::PADRE_GREEN,
	'infix:,'           => Padre::Constant::PADRE_GREEN,
	'infix:..'          => undef,
	'prefix:='          => undef,
	'infix:|'           => undef,
	'infix:=='          => undef,
	'infix:*='          => undef,
	twigil              => undef,
	if_statement        => undef,
	'infix:eq'          => undef,
	semilist            => undef,
	scope_declarator    => undef,
	scoped              => undef,
	variable_declarator => undef,
	declarator          => undef,
	variable            => Padre::Constant::PADRE_RED,
	integer             => undef,
	number              => Padre::Constant::PADRE_BROWN,
	circumfix           => undef,
	param_sep           => undef,
	sigil               => undef,
	desigilname         => undef,
	longname            => undef,
	parameter           => undef,
	param_var           => undef,
	quant               => undef,
	pblock              => undef,
	block               => undef,
	signature           => undef,
	for_statement       => undef,
	xblock              => undef,
	lambda              => Padre::Constant::PADRE_GREEN,

	# Cardinal
	ident             => undef,
	local_variable    => undef,
	basic_primary     => undef,
	basic_stmt        => undef,
	stmt              => undef,
	before            => undef,
	mrhs              => undef,
	varname           => undef,
	stmts             => undef,
	comp_stmt         => undef,
	assignment        => undef,
	mlhs              => undef,
	literal           => undef,
	arg               => undef,
	call_arsg         => undef,
	funcall           => undef,
	post_primary_expr => undef,
	call_args         => undef,
	string            => undef,
);

# This is run in the main thread after the task is done.
# It can update the GUI and do cleanup.
# You don't have to implement this if you don't need it.
sub finish {
	my $self       = shift;
	my $mainwindow = shift;

	my $editor = Padre::Current->editor;
	my $addr   = delete $self->{_editor};
	if ( not $addr or not $editor or $addr ne Scalar::Util::refaddr($editor) ) {

		# shall we try to locate the editor ?
		$thread_running = 0;
		return 1;
	}

	my $doc = Padre::Current->document;
	if ( not $doc ) {
		$thread_running = 0;
		return 1;
	}

	if ( $self->{_parse_tree} ) {
		$doc->remove_color;
		foreach my $pd ( @{ $self->{_parse_tree} } ) {
			my $type = $pd->{type};
			if ( not exists( $colors{$type} ) ) {
				warn "No color definiton for '$type':  " . $pd->{str} . "\n";
				next;
			}
			if ( not defined $colors{$type} ) {

				# no need to color
				next;
			}
			my $color = $colors{$type};
			$editor->StartStyling( $pd->{start}, $color );
			$editor->SetStyling( $pd->{length}, $color );
		}
	}
	$doc->{tokens} = [];
	$doc->{issues} = [];

	#$doc->check_syntax_in_background(force => 1); # $task-
	#$doc->get_outline(force => 1);

	# finished here
	$thread_running = 0;

	return 1;
}

# Task thread subroutine
sub run {
	my $self = shift;


	use File::Temp qw(tempdir);
	my $dir = tempdir( CLEANUP => 1 );
	my $file = "$dir/file";

	if ( open my $fh, '>', $file ) {
		print $fh $self->{text};
		delete $self->{text};
	} else {
		warn "Could not open $file for writing\n";
		return;
	}

	# TODO check if the path is there
	my $cmd = ( $self->{pbc} ? qq("$ENV{PARROT_DIR}/parrot" ) : '' );
	$cmd .= qq("$self->{path}");
	$cmd .= qq( --target=parse --dumper=padre "$file");

	#print "$cmd\n";
	my @data = `$cmd`;
	chomp @data;
	my @pd;
	foreach my $line (@data) {
		$line =~ s/^\s+//;
		my ( $start, $length, $type, $str ) = split /\s+/, $line, 4;
		push @pd,
			{
			start  => $start,
			length => $length,
			type   => $type,
			str    => $str,
			};
	}
	$self->{_parse_tree} = \@pd;
	return;

	return 1;
}

1;
__END__
=pod

=head1 NAME

Padre::Plugin::Parrot::ColorizeTask - A Colorizer Task

=head1 VERSION

version 0.31

=head1 AUTHORS

=over 4

=item *

Gabor Szabo L<http://szabgab.com/>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Gabor Szabo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

