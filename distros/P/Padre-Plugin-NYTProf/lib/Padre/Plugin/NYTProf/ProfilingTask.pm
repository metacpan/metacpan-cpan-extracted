package Padre::Plugin::NYTProf::ProfilingTask;
BEGIN {
  $Padre::Plugin::NYTProf::ProfilingTask::VERSION = '0.04';
}

# ABSTRACT: Creates a Padre::Task to do the profiling in the background.

use strict;
use warnings;

use base 'Padre::Task';


# we may want to set some default settings for NYTProf at some stage:
# keys should be relate to the environment vars NYTProf expects
my %nytprof_envars = (
	file => 'nytprof.out',
);

sub new {

	my $class         = shift;
	my $prof_settings = shift;

	my $self = $class->SUPER::new(@_);



	$self->{prof_settings} = $prof_settings;


	$self->{nytprof_envars} = \%nytprof_envars;

	# write the output to whatever temp is
	$self->{nytprof_envars}->{file} = $self->{prof_settings}->{report_file};

	bless( $self, $class );
	return $self;

}

sub run {
	my $self = shift;

	my $nytprof_env_vars = "";
	my $drive            = "";
	foreach my $env ( keys( %{ $self->{nytprof_envars} } ) ) {

		# we can't use the full file path because the colon
		# in the file path is the same delimiter NYTProf uses
		# for NYTPROF environment variable.
		# not the best but:
		if ( ( $env eq 'file' ) && ( $^O eq 'MSWin32' ) ) {
			$self->{nytprof_envars}->{$env} =~ /(\w\:)(.*$)/;
			$drive = $1;
			$self->{nytprof_envars}->{$env} = $2;
		}
		$nytprof_env_vars .= "$env=" . $self->{nytprof_envars}->{$env} . ":";
	}
	$nytprof_env_vars =~ s/\:$//;

	# doesn't work as expected
	# local $ENV{NYTPROF} = $nytprof_env_vars;
	# my @cmd = ( $self->{perl}, '-d:NYTProf', $self->{doc_path} );

	my $cmd = '';
	if ( $^O eq "MSWin32" ) {
		$cmd = "$drive && set NYTPROF=$nytprof_env_vars && ";
	} elsif ( $^O eq "darwin" ) {
	} elsif ( $^O eq "linux" ) {
		$cmd = "NYTPROF=$nytprof_env_vars; export NYTPROF; "
			; # . $self->{prof_settings}->{perl} . ' -d:NYTProf ' . $self->{prof_settings}->{doc_path};
	}

	# run the command if we can
	if ( $cmd ne '' ) {

		# append the rest of the command here
		$cmd .= $self->{prof_settings}->{perl} . ' -d:NYTProf ' . $self->{prof_settings}->{doc_path};
		system($cmd);
	} else {
		warn "Unable to determine your OS\n";
	}

	return 1;
}


sub finish {
	my $self = shift;

	return 1;

}


1;


=pod

=head1 NAME

Padre::Plugin::NYTProf::ProfilingTask - Creates a Padre::Task to do the profiling in the background.

=head1 VERSION

version 0.04

=head1 SYNOPSIS

Creates and runs the profilng task against your scripts from within Padre.

This should be called from the plugin module.

=head1 DESCRIPTION

Called from the plugin module.

=head1 BUGS

Plenty I'm sure, but since this doesn't even load anything I'm fairly safe.

=head1 SUPPORT

#padre on irc.perl.org

=head1 ACKNOWLEDGEMENTS

I'd like to acknowledge the support and patience of the #padre channel.

With nothing more than bravado and ignorance I pulled this together with the help of those in the #padre
channel answering all my clearly lack of reading questions.

=head1 SEE ALSO

L<Padre>

=head1 AUTHORS

=over 4

=item *

Peter Lavender <peter.lavender@gmail.com>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Peter Lavender.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

