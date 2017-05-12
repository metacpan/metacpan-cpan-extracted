package Padre::Plugin::NYTProf;
BEGIN {
  $Padre::Plugin::NYTProf::VERSION = '0.04';
}

# ABSTRACT: Integrated profiling for Padre.

use warnings;
use strict;

use base 'Padre::Plugin';

require Padre::Plugin::NYTProf::ProfilingTask;

# local profile setup
my %prof_settings;

# The plugin name to show in the Plugin Manager and menus
sub plugin_name {Wx::gettext('NYTProf - Perl Profiler')}

# Declare the Padre interfaces this plugin uses
sub padre_interfaces {
	'Padre::Plugin' => 0.47,;
}


sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [

		Wx::gettext('Run Profiling')                                 => sub { $self->on_start_profiling },
		Wx::gettext('Generate Profiling Report')         => sub { $self->on_generate_report },
		Wx::gettext('Show Generated Profiling Report') => sub { $self->on_show_report },

		'---' => undef, # ...add a separator

		Wx::gettext('About') => sub { $self->on_show_about },

	];

}

sub plugin_enable {
	return;
}

sub plugin_disable {
	require Class::Unload;
	Class::Unload->unload('Padre::Plugin::NYTProf::ProfilingTask');
	Class::Unload->unload('Padre::Plugin::NYTProf');

	#    Class::Unload->unload('Devel::NYTProf');

}


sub on_start_profiling {


	# need to move these out to the plugin component
	$prof_settings{doc_path}    = Padre::Current->document->filename;
	$prof_settings{temp_dir}    = File::Temp::tempdir();
	$prof_settings{perl}        = Padre::Perl->perl;
	$prof_settings{report_file} = $prof_settings{temp_dir} . "/nytprof.out";
	my $prof_task = Padre::Plugin::NYTProf::ProfilingTask->new( \%prof_settings );
	$prof_task->schedule;


	return;

}

sub on_generate_report {

	my $main = Padre->ide->wx->main;

	# create the commandline to create HTML output
	# nytprof gets put into the perl bin directory
	#my $bin_path = $prof_settings{perl};
	#$bin_path =~ dirname( $bin_path); #s/[^\\\/](perl.*$)//i;

	# TODO the path to nytprofhtml has changed to /usr/local/bin
	# I'm not sure if this is due to the way I installed it or
	# if this is a change with the install location with nytprof.
	# so this needs to be done better.

	my ( $fname, $bin_path, $suffix ) = File::Basename::fileparse( $prof_settings{perl} );
	my $report =
		  $prof_settings{perl} . ' '
		. $bin_path
		. 'nytprofhtml -o '
		. $prof_settings{temp_dir}
		. '/nytprof -f '
		. $prof_settings{report_file};
	$main->run_command($report);
}

sub on_show_report {

	my $report = $prof_settings{temp_dir} . '/nytprof/index.html';

	Padre::Wx::launch_browser("file://$report");

	# testing..
	# now we need to read in the output file
	# require Devel::NYTProf::Data;
	# my $profile = Devel::NYTProf::Data->new( { filename => $prof_settings{file} } );

	return;

}

sub on_show_about {
	require Devel::NYTProf;
	require Class::Unload;
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::NYTProf");
	$about->SetDescription( Wx::getttext('Initial NYTProf profile support for Padre') . "\n\n"
			. Wx::gettext('This system is running NYTProf version ')
			. $Devel::NYTProf::VERSION
			. "\n" );
	$about->SetVersion($Devel::NYTProf::VERSION);
	Class::Unload->unload('Devel::NYTProf');

	Wx::AboutBox($about);
	return;
}


1;


=pod

=head1 NAME

Padre::Plugin::NYTProf - Integrated profiling for Padre.

=head1 VERSION

version 0.04

=head1 SYNOPSIS

Run profilng against your scripts from within Padre.

=head1 DESCRIPTION

The intention here is to have the profiler run over the current document and have it's report appear in a tab in the IDE.

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

