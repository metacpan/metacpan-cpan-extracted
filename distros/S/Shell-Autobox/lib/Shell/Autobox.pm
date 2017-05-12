package Shell::Autobox;

use strict;
use warnings;

use File::Temp;
use Carp qw(confess);
use base qw(autobox);

our $VERSION = '0.03';

sub import {
	my $class = shift;
	my $caller = (caller)[0];

	for my $program (@_) {
		my $sub = sub {
			my $input = shift;
			my $args = join ' ', @_;
			my $stdin = File::Temp->new();
			my $stdout = File::Temp->new();
			my $stderr = File::Temp->new();
			my $command = "$program $args $stdin 2> $stderr > $stdout";
			my ($output, $error, $status);

			print $stdin $input;
			$status = system $command;

			{
				local $/ = undef;
				$error = <$stderr>;
				$output = <$stdout>;
			}

			if ($status) {
				confess "can't exec $command" . ((length $error) ? ": $error" : '');
			} elsif (length $error) {
				warn $error;
			}

			return $output;
		};

		{
			no strict 'refs';
			*{"$caller\::$program"} = $sub;
		}
	}

	$class->SUPER::import(SCALAR => $caller);
}

1;

__END__

=head1 NAME

Shell::Autobox - pipe Perl strings through shell commands

=head1 SYNOPSIS

  use Shell::Autobox qw(xmllint);

  my $xml = '<foo bar="baz"><bar /><baz /></foo>';
  my $pretty = $xml->xmllint('--format');

=head1 DESCRIPTION

Shell::Autobox provides an easy way to pipe Perl strings through shell commands. Commands passed as arguments to the
C<use Shell::Autobox> statement are installed as subroutines in the calling package, and that package is then
registered as the handler for methods called on ordinary (i.e. non-reference) scalars.

When a method corresponding to a registered command is called on a scalar, it is passed as the command's standard input; 
additional arguments are passed through as a space-delimited list of options, and - if no error occurs - the
command's standard output is returned. This can then be piped into other commands.

The scalar is written to a temporary file, and the name of this file is appended to the program name and the supplied
options, so commands that expect their input to be supplied in some other fashion may need to be massaged.

e.g.

	$foo->bar('-input')->baz(...)

	# or
	
	$foo->bar('--option1', '--option2', '<')->baz(...)

The registered methods can also be called as regular functions e.g.

	use Shell::Autobox qw(cut);

	my $bar = cut("foo:bar:baz", "-d':' -f2");

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<autobox>, L<autobox::Core>, L<Shell>

=head1 AUTHOR

chocolateboy <chocolate.boy@email.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 by chocolateboy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 VERSION

0.03

=cut
