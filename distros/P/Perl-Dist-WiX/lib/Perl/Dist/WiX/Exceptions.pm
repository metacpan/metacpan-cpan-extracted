package Perl::Dist::WiX::Exceptions;

use 5.010;
use strict;
use warnings;
use WiX3::Traceable qw();
use Data::Dump::Streamer qw();
use File::Spec::Functions qw( catfile );

our $VERSION = '1.500';
$VERSION =~ s/_//ms;


#####################################################################
# Error Handling

use Exception::Class (
	'PDWiX'       => { 'description' => 'Perl::Dist::WiX error', },
	'PDWiX::Stop' => {
		'description' => 'Perl::Dist::WiX error: Debugging stop.',
		'isa'         => 'PDWiX',
	},
	'PDWiX::NotTask' => {
		'description' => 'does not know how to complete step',
		'isa'         => 'PDWiX',
		'fields'      => [qw(class task step)],
	},
	'PDWiX::Parameter' => {
		'description' =>
		  'Perl::Dist::WiX error: Parameter missing or invalid',
		'isa'    => 'PDWiX',
		'fields' => [ 'parameter', 'where' ],
	},
	'PDWiX::ParametersNotHash' => {
		'description' =>
		  'Perl::Dist::WiX error: Parameters not pairs or hashref',
		'isa'    => 'PDWiX',
		'fields' => ['where'],
	},
	'PDWiX::Caught' => {
		'description' =>
		  'Error caught by Perl::Dist::WiX from other module',
		'isa'    => 'PDWiX',
		'fields' => [ 'message', 'info' ],
	},
	'PDWiX::Caught::Storable' => {
		'description' => 'Error caught by Perl::Dist::WiX from Storable',
		'isa'         => 'PDWiX::Caught',
		'fields'      => [ 'message', 'object' ],
	},
	'PDWiX::Unimplemented' => {
		'description' => 'Perl::Dist::WiX error: Routine unimplemented',
		'isa'         => 'PDWiX',
	},
	'PDWiX::Directory' => {
		'description' => 'Perl::Dist::WiX error: Directory error',
		'isa'         => 'PDWiX',
		'fields'      => [ 'message', 'dir' ],
	},
	'PDWiX::File' => {
		'description' => 'Perl::Dist::WiX error: File error',
		'isa'         => 'PDWiX',
		'fields'      => [ 'message', 'file' ],
	},
);

sub PDWiX::full_message {
	my $self = shift;

	my $string =
	    $self->description() . ': '
	  . $self->message() . "\n"
	  . 'Time error caught: '
	  . localtime() . "\n";
	my $misc       = WiX3::Traceable->new();
	my $tracelevel = $misc->get_tracelevel();

	# Add trace to it if tracelevel high enough.
	if ( $tracelevel > 1 ) {
		$string .= "\n" . $self->trace() . "\n";
	}

	$self->growl();

	return $string;
} ## end sub PDWiX::full_message

sub PDWiX::growl {
	my $self = shift;

	if ( eval { require Growl::GNTP; 1; } ) {

		# Open up our communication link to Growl.
		my $growl = Growl::GNTP->new(
			AppName => 'Perl::Dist::WiX Error',
			AppIcon => catfile(
				File::ShareDir::dist_dir('Perl-Dist-WiX'),
				'growl-icon.png'
			),
		);

		# Need to register with Growl for Windows.
		$growl->register( [ {
					Name        => 'ERROR',
					DisplayName => 'Error occured',
					Enabled     => 'True',
					Sticky      => 'False',
					Priority    => 0,  # medium priority.
					Icon        => catfile(
						File::ShareDir::dist_dir('Perl-Dist-WiX'),
						'growl-icon.png'
					),
				} ] );

		# Actually do the notification.
		$growl->notify(
			Event   => 'OUTPUT_FILE',  # name of notification
			Title   => 'Output file created',
			Message => $self->description(),
			ID      => 0,
		);
	} ## end if ( eval { require Growl::GNTP...})

	return;
} ## end sub PDWiX::growl

sub PDWiX::Stop::full_message {
	my $self = shift;

	my $string =
	    $self->description() . "\n"
	  . 'Time error caught: '
	  . localtime() . "\n";

	# Add trace to it.
	$string .= "\n" . $self->trace() . "\n";

	$self->growl();

	return $string;
} ## end sub PDWiX::Stop::full_message

sub PDWiX::NotTask::full_message {
	my $self = shift;

	my $string =
	    $self->class() . q{ }
	  . $self->description() . ' #'
	  . $self->step() . ' ('
	  . $self->task() . ")\n"
	  . 'Time error caught: '
	  . localtime() . "\n";

	$self->growl();

	return $string;
} ## end sub PDWiX::NotTask::full_message

sub PDWiX::Parameter::full_message {
	my $self = shift;

	my $string =
	    $self->description() . ': '
	  . $self->parameter()
	  . ' in Perl::Dist::WiX'
	  . $self->where() . "\n"
	  . 'Time error caught: '
	  . localtime() . "\n";

	# Add trace to it. (We automatically dump trace for parameter errors.)
	$string .= "\n" . $self->trace() . "\n";

	$self->growl();

	return $string;
} ## end sub PDWiX::Parameter::full_message

sub PDWiX::ParametersNotHash::full_message {
	my $self = shift;

	my $string =
	    $self->description()
	  . ' in Perl::Dist::WiX'
	  . $self->where() . "\n"
	  . 'Time error caught: '
	  . localtime() . "\n";

	# Add trace to it. (We automatically dump trace for parameter errors.)
	$string .= "\n" . $self->trace() . "\n";

	$self->growl();

	return $string;
} ## end sub PDWiX::ParametersNotHash::full_message

sub PDWiX::Caught::full_message {
	my $self = shift;

	my $string =
	    $self->description() . ': '
	  . $self->message() . "\n"
	  . 'Info: '
	  . $self->info() . "\n"
	  . 'Time error caught: '
	  . localtime() . "\n";
	my $misc       = WiX3::Traceable->new();
	my $tracelevel = $misc->get_tracelevel();

	# Add trace to it if tracelevel high enough.
	if ( $tracelevel > 1 ) {
		$string .= "\n" . $self->trace() . "\n";
	}

	$self->growl();

	return $string;
} ## end sub PDWiX::Caught::full_message

sub PDWiX::Caught::Storable::full_message {
	my $self = shift;

	my $string =
	    $self->description() . q{: }
	  . $self->message() . "\n"
	  . 'Time error caught: '
	  . localtime() . "\n";
	my $misc       = WiX3::Traceable->new();
	my $tracelevel = $misc->get_tracelevel();

	# Add trace to it if tracelevel high enough.
	if ( $tracelevel > 1 ) {
		$string .= "\n" . $self->trace() . "\n";
	}

	$string .= "\nObject trace:\n";

	STDOUT->flush();

	my $dump = Data::Dump::Streamer->new();
	$dump->Ignore(
		'Template'                             => 1,
		'URI::file'                            => 1,
		'URI::http'                            => 1,
		'LWP::UserAgent'                       => 1,
		'Path::Class::Dir'                     => 1,
		'Path::Class::File'                    => 1,
		'Perl::Dist::WiX::Fragment::Files'     => 1,
		'Perl::Dist::WiX::Fragment::StartMenu' => 1,
		'Perl::Dist::WiX::DirectoryTree'       => 1,
		'Perl::Dist::WiX::Toolchain'           => 1,
		'Perl::Dist::WiX::FeatureTree'         => 1,
		'WiX3::XML::GeneratesGUID::Object'     => 1,
		'WiX3::Trace::Object'                  => 1,
		'WiX3::Traceable'                      => 1,
	);
	$dump->Data( $self->object() )->Indent(2)->Names('*self');
	$dump->Deparse(0)->CodeStub('sub {"CODE!"}');

	my $out = $dump->Out();

	print "$out\n";

	$self->growl();

	return $string;
} ## end sub PDWiX::Caught::Storable::full_message

sub PDWiX::Directory::full_message {
	my $self = shift;

	my $string =
	    $self->description()
	  . "\nDirectory: "
	  . $self->dir()
	  . "\nMessage: "
	  . $self->message() . "\n"
	  . 'Time error caught: '
	  . localtime() . "\n";
	my $misc       = WiX3::Traceable->new();
	my $tracelevel = $misc->get_tracelevel();

	# Add trace to it if tracelevel high enough.
	if ( $tracelevel > 1 ) {
		$string .= "\n" . $self->trace() . "\n";
	}

	$self->growl();

	return $string;
} ## end sub PDWiX::Directory::full_message

sub PDWiX::File::full_message {
	my $self = shift;

	my $string =
	    $self->description()
	  . "\nFile: "
	  . $self->file()
	  . "\nMessage: "
	  . $self->message() . "\n"
	  . 'Time error caught: '
	  . localtime() . "\n";
	my $misc       = WiX3::Traceable->new();
	my $tracelevel = $misc->get_tracelevel();

	# Add trace to it if tracelevel high enough.
	if ( $tracelevel > 1 ) {
		$string .= "\n" . $self->trace() . "\n";
	}

	$self->growl();

	return $string;
} ## end sub PDWiX::File::full_message

1;

__END__

=pod

=head1 NAME

Perl::Dist::WiX::Exceptions - Exception classes for Perl::Dist::WiX

=head1 VERSION

This document describes Perl::Dist::WiX::Exceptions version 1.500.

=head1 DESCRIPTION

This module provides the exceptions that Perl::Dist::WiX uses when notifying
the user about errors.

=head1 SYNOPSIS

	# TODO: Document

=head1 INTERFACE

	# TODO: Document

=head1 DIAGNOSTICS

This is the module that defines the throwable exceptions.

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2008 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
