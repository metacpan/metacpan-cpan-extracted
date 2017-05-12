package Padre::Task::ClassSniff;
BEGIN {
  $Padre::Task::ClassSniff::VERSION = '0.30';
}

# ABSTRACT: Running class sniff in the background

use strict;
use warnings;

use Padre::Task::PPI ();
use Padre::Wx        ();
use Scalar::Util qw(blessed);
use IPC::Cmd ();

use base 'Padre::Task::PPI';

sub process_ppi {
	my $self = shift;
	my $ppi  = shift or return ();
	my $mode = $self->{mode} || 'print_report';


	my $sniff_config = $self->{sniff_config} ||= {};

	if ( not defined $sniff_config->{class} ) {
		$sniff_config->{class} = $self->find_document_namespace($ppi);
	}

	if ( $mode eq 'print_report' ) {
		$self->print_report($ppi);
	}

	return ();
}

sub find_document_namespace {
	my $self = shift;
	my $ppi  = shift;
	my $ns   = $ppi->find_first('PPI::Statement::Package');
	return ()
		if not defined $ns
			or !blessed($ns)
			or !$ns->isa('PPI::Statement::Package');
	return $ns->namespace;
}

sub print_report {
	my $self         = shift;
	my $ppi          = shift;
	my $sniff_config = $self->{sniff_config};

	if ( not defined $sniff_config->{class} ) {
		$self->task_warn( Wx::gettext("Could not determine class to run Sniff on.\n") );
		return ();
	}

	my ( $ok, $stdout, $stderr ) = $self->run_sniff( $sniff_config, $self->{text} || $ppi->serialize() );
	if ( !$ok or not defined $stdout ) {
		$self->task_warn( "Error running Class::Sniff on class '" . $sniff_config->{class} . "': " . $stderr . "\n" );
		return ();
	}
	if ( defined $stderr and $stderr =~ /\S/ ) {
		$self->task_warn(
			"Warning from running Class::Sniff on class '" . $sniff_config->{class} . "': " . $stderr . "\n" );
	}

	if ( defined $stdout and $stdout =~ /\S/ ) {
		$self->task_print( $stdout . "\n" );
	} else {
		$self->task_print( "No bad smell from class '" . $sniff_config->{class} . "'\n" );
	}
	return ();

}

sub run_sniff {
	my $self = shift;
	my $cfg  = shift;
	my $code = shift;

	require YAML::Tiny;
	require IPC::Cmd;
	require IPC::Open3;

	my $yaml = YAML::Tiny::Dump($cfg);
	my @cmd  = (
		Padre->perl_interpreter(),
		'-Mstrict',
		'-Mwarnings',
		'-mYAML::Tiny',
		'-mClass::Sniff',
		'-e',
	);
	push @cmd, <<'HERE';
	my $yaml = YAML::Tiny::Load(shift(@ARGV)) or die "Bad config";
	$yaml = $yaml->[0] if ref($yaml) eq 'ARRAY';
	my $code = shift(@ARGV);
	eval $code;
	die "Could not compile class: $@" if $@;
	my $sniff = Class::Sniff->new($yaml);
	die "Could not instantiate Class::Sniff" if not $sniff;
	print $sniff->report();
HERE
	push @cmd, '--', $yaml, $code;

	my ( $ok, $errno, undef, $stdout, $stderr ) = IPC::Cmd::run( command => \@cmd, verbose => 0 );
	$stdout = join "", @$stdout
		if defined $stdout and ref($stdout) eq 'ARRAY';
	$stderr = join "", @$stderr
		if defined $stderr and ref($stderr) eq 'ARRAY';
	return ( $ok, $stdout, $stderr );
}

1;



=pod

=head1 NAME

Padre::Task::ClassSniff - Running class sniff in the background

=head1 VERSION

version 0.30

=head1 SYNOPSIS

  my $task = Padre::Task::ClassSniff->new(
    mode => 'print_report',
    sniff_config => { ... },
  );
  $task->schedule;

=head1 DESCRIPTION

Runs Class::Sniff on the first namespace of the current document
and prints the results to the Padre output window.

=head1 SEE ALSO

This class inherits from C<Padre::Task::PPI> and its instances can be scheduled
using C<Padre::TaskManager>.

The transfer of the objects to and from the worker threads is implemented
with L<Storable>.

=head1 AUTHORS

=over 4

=item *

Steffen Mueller <smueller@cpan.org>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Steffen Mueller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

