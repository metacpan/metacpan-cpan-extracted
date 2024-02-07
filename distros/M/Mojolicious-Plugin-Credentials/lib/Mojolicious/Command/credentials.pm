package Mojolicious::Command::credentials;
$Mojolicious::Command::credentials::VERSION = '0.006';
use Mojo::Base 'Mojolicious::Command', -signatures;

use File::Slurper qw/read_binary write_binary/;
use File::Temp 'tempfile';
use Getopt::Long 'GetOptionsFromArray';
use Text::ParseWords 'shellwords';
use YAML::PP 'LoadFile';

has description => 'Edit the applications credentials';

has usage => sub { shift->extract_usage };

sub run($self, $command, @args) {
	die $self->usage unless defined $command;

	my $credentials = $self->app->credentials;

	if ($command eq 'edit') {
		my $editor = $ENV{EDITOR} // 'vi';
		GetOptionsFromArray(\@args, 'yaml' => \my $yaml, 'editor=s' => \$editor) or die "Invalid arguments";
		my $name = shift @args or die 'No credential name given';

		my $suffix = $yaml ? '.yaml' : undef;
		my ($fh, $filename) = tempfile(UNLINK => 1, SUFFIX => $suffix);
		write_binary($filename, $credentials->get($name)) if $credentials->has($name);

		system shellwords($editor), $filename and die 'Could not save file';

		my $data = read_binary($filename);
		YAML::PP->new->load_string($data) if $yaml; # YAML validity check
		$credentials->put($name, $data);
	} elsif ($command eq 'show') {
		my $name = shift @args or die 'No credential name given';
		print $credentials->get($name);
	} elsif ($command eq 'list') {
		say for $credentials->list;
	} elsif ($command eq 'remove') {
		my $name = shift @args or die 'No credential name given';A
		$credentials->remove($name);
	} elsif ($command eq 'recode') {
		print 'Please input new key in hex form: ';
		chomp(my $encoded_key = <>);
		my $key = pack "H*", $encoded_key;
		$credentials->recode($key);
	} else {
		die "Unknown subcommand $command"
	}
}

1;

# ABSTRACT: Manage your app's credentials

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Command::credentials - Manage your app's credentials

=head1 VERSION

version 0.006

=head1 SYNOPSIS

Usage: myapp credentials <command> <arg>

 The credentials helper installed on your app will be used to manage credentials
 for your application. See Mojolicious::Plugin::Credentials for more info.

 # To edit a credentials entry simply do
 ./myapp.pl credentials edit some-name

=head1 DESCRIPTION

This allows you to interact with your applications credentials store. It has a number of subcommands:

=head2 edit <name>

This will open an editor for you to edit the contents of a credentials entry.

It will optionally take the following arguments:

=over 4

=item * C<--editor> will set the editor used. This defaults to the environmental variable C<EDITOR> if defined.

=item * C<--yaml> will cause C<credentials> to verify the file is valid YAML (and potentially tell the editor it's YAML)

=back

=head2 show <name>

This shows

=head2 list

This will return a list of all entries in the credentials store.

=head2 remove <name>

This will remove the named entry.

=head2 recode

This wil ask you for a new (hex encoded) key, and will re-encrypt the entire store using that new key.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
