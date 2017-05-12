package String::ShortenHostname::App;
# ABSTRACT: class for wrapping getopt options to the class interface

use Moose;
use IO::Handle;

our $VERSION = '0.006'; # VERSION


extends 'String::ShortenHostname';
with 'MooseX::Getopt';

has '+length' => (
	traits => ['Getopt'],
	cmd_aliases => "l",
	documentation => "the desired length of the hostname string",
);

has '+keep_digits_per_domain' => (
	traits => ['Getopt'],
	cmd_aliases => "d",
	documentation => "number of digits per domain",
);

has '+domain_edge' => (
	isa => 'Str',
	traits => ['Getopt'],
	cmd_aliases => "e",
	documentation => "edge string for truncation of domain",
);

has '+cut_middle' => (
	traits => ['Getopt'],
	cmd_aliases => "m",
	documentation => "dont truncate, cut in the middle of domain",
);

has '+force' => (
	traits => ['Getopt'],
	cmd_aliases => "f",
	documentation => "force string length (truncate)",
);

has '+force_edge' => (
	isa => 'Str',
	traits => ['Getopt'],
	cmd_aliases => "E",
	documentation => "edge string for forced truncation of string",
);

sub run {
	my $self = shift;

	if( @{$self->extra_argv} ) {
		foreach my $hostname ( @{$self->extra_argv} ) {
			print $self->shorten($hostname)."\n";
		}
		return;
	}
	
	my $stdin = IO::Handle->new_from_fd(fileno(STDIN),"r")
		or die('cant open STDIN: '.$@);
	while( my $line = $stdin->getline ) {
		chomp($line);
		print $self->shorten($line)."\n";
	}
	$stdin->close;

	return;
}

1;


__END__
=pod

=head1 NAME

String::ShortenHostname::App - class for wrapping getopt options to the class interface

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  use String::ShortenHostname::App;

  my $app = String::ShortenHostname::App->new_with_options();
  $app->run;

=head1 SEE ALSO

L<shorten_hostname>

=head1 AUTHOR

Markus Benning <me@w3r3wolf.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

