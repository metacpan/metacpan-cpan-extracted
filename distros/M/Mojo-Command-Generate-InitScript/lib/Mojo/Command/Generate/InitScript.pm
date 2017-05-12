package Mojo::Command::Generate::InitScript;

use warnings;
use strict;

use base 'Mojo::Commands';
use File::Spec;
use Getopt::Long 'GetOptions';
use Mojo::ByteStream 'b';



__PACKAGE__->attr(description => <<'EOF');
Generate application initscript (also known as rc.d script)
EOF
__PACKAGE__->attr(usage => <<"EOF");
usage: $0 generate init_script target_os [OPTIONS]

These options are available:
    --output <folder>   Set folder to output initscripts
    --deploy            Deploy initscripts into OS
                        Either --deploy or --output=dist should be specified

    --name <name>       Ovewrite name which is used for initscript filename(s)
EOF

__PACKAGE__->attr(namespaces => sub { ['Mojo::Command::Generate::InitScript'] });


=head1 NAME

Mojo::Command::Generate::InitScript - Initscript generator command

=head1 SYNOPSYS

	$ ./mojo_app.pl generate help init_script
	usage: ./mojo_app.pl generate init_script target_os [OPTIONS]

	These options are available:
		--output <folder>   Set folder to output initscripts
		--deploy            Deploy initscripts into OS
							Either --deploy or --output=dist should be specified

		--name <name>       Ovewrite name which is used for initscript filename(s)


=cut

our $VERSION = '0.03';



sub run
{
	my ( $self, $target ) = @_;

	my $opt = {};

	Getopt::Long::Configure('pass_through');
	GetOptions( $opt,
		'output=s', 'name=s', 'deploy',
	);

	if ( !( $opt->{'deploy'} || $opt->{'output'} ) )
	{
		die qq{Either --deploy or --output <folder> should be specified\n};
	}
	if ( $opt->{'deploy'} && $opt->{'output'} )
	{
		die qq{Either --deploy or --output <folder> should be specified but not both\n};
	}

	if ( $opt->{'deploy'} && !$self->user_is_root )
	{
		die qq{You must be root to deploy init script\n};
	}

	if ( !$opt->{'name'} )
	{
		my ( $vol, $folder, $filename ) = File::Spec->splitpath( $0 );
		($opt->{'name'}) = $filename =~ m/^(.*?)(?:\.pl)?$/;
	}

	$opt->{'app_script'} = File::Spec->rel2abs( $0 );

	$self->SUPER::run( $target, $opt, @_ );

}

sub user_is_root
{
	my $self = shift;
	return $> == 0 || $< == 0
}

sub help
{
	my $self = shift;
	my $name = pop @ARGV;
	if ( $name eq 'init_script' )
	{
		print $self->usage;
		return;
	}
	my $module;
	for my $namespace (@{$self->namespaces})
	{

		# Generate module
		my $try = $namespace . '::' . b($name)->camelize;

		# Load
		if (my $e = Mojo::Loader->load($try)) {

			# Module missing
			next unless ref $e;

			# Real error
			die $e;
		}

		# Module is a command?
		next unless $try->can('new') && $try->can('run');

		# Found
		$module = $try;
		last;
	}

	die qq/Command "$name" missing, maybe you need to install it?\n/
	  unless $module;

	my $command = $module->new;
	print $self->usage, "\n", $command->usage;
}

=head1 AUTHOR

Anatoliy Lapitskiy, C<< <nuclon at cpan.org> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojo::Command::Generate::InitScript


You can also look for information at:

=over 4

=item * bitbucket repository

L<http://bitbucket.org/nuclon/mojo-command-generate-initscript/>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojo-Command-Generate-InitScript/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Anatoliy Lapitskiy.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Mojo::Command::Generate::InitScript
