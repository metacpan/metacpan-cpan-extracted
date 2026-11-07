package Monitoring::Sneck::Checks::file_content;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use File::Slurp qw(read_file);

=head1 NAME

Monitoring::Sneck::Checks::file_content - checks a file being there, or not, and what is in it

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    hourly_logrotate|perl:file_content -f /etc/cron.hourly/logrotate -x -r /etc/logrotate\.conf
    app_logrotate|perl:file_content -f /etc/logrotate.d/app
    no_root_ssh|perl:file_content -f /etc/ssh/sshd_config -r '^PermitRootLogin\s+no'
    no_nologin|perl:file_content -f /etc/nologin -A

=head1 DESCRIPTION

A file that is not there is CRITICAL, as is one missing a line for a
--regex, or with one for a --not-regex. Lines matching --comment are
skipped for both.

=head1 OPTIONS

- -f, --file :: The file. Required.

- -r, --regex :: A regex at least one line must match. May be given
more than once.

- -R, --not-regex :: A regex no line may match. May be given more than
once.

- -x, --executable :: It must be executable.

- -A, --absent :: It must not be there, in place of the others.

- -C, --comment :: A regex for lines to skip.
Default :: ^\s*#

=cut

# The Getopt::Long specs of the options, see OPTIONS.
#
# Returns the list of specs.
#
# Example...
#
#     my @specs = $check->option_spec;
#     # ( 'file|f=s', 'regex|r=s@', 'not-regex|R=s@', 'executable|x', 'absent|A', 'comment|C=s' )
sub option_spec {
	return ( 'file|f=s', 'regex|r=s@', 'not-regex|R=s@', 'executable|x', 'absent|A', 'comment|C=s' );
}

# The option defaults, see OPTIONS.
#
# Returns a hash ref of option names to defaults.
#
# Example...
#
#     my $defaults = $check->defaults;
#     # { comment => '^\s*#' }
sub defaults { return { comment => '^\s*#' } }

# The options that must be given.
#
# Returns the list of option names.
#
# Example...
#
#     my @required = $check->required;
#     # ( 'file' )
sub required { return ('file') }

# Checks what Getopt::Long can not, every regex compiling and --absent not being mixed with what needs the file.
#
# Args...
#
#     - options :: Hash ref of option names to values, defaults included. regex and not-regex are array refs.
#
# Returns a list of what is wrong, each a string, empty if nothing is.
#
# Example...
#
#     my @problems = $check->validate( { file => '/etc/sudoers', regex => ['('], comment => '^\s*#' } );
#     # ( '--regex "(" is not a valid regex' )
sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	foreach my $name ( 'regex', 'not-regex' ) {
		foreach my $regex ( @{ $options->{$name} // [] } ) {
			push( @problems, '--' . $name . ' "' . $regex . '" is not a valid regex' ) if !eval { qr/$regex/ };
		}
	}
	push( @problems, '--comment is not a valid regex' ) if !eval { qr/$options->{comment}/ };
	if ( $options->{absent} && ( $options->{regex} || $options->{'not-regex'} || $options->{executable} ) ) {
		push( @problems, '--absent can not be used with --regex, --not-regex, or --executable' );
	}

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $file = $self->opt('file');
	if ( $self->opt('absent') ) {
		return $self->finish( $self->CRITICAL, $file . ' is there' ) if -e $file;
		return $self->finish( $self->OK,       $file . ' is not there' );
	}

	return $self->finish( $self->CRITICAL, $file . ' is not a file' ) if !-f $file;
	my $content = read_file( $file, err_mode => 'quiet' );
	return $self->finish( $self->CRITICAL, 'can not read ' . $file . ', ' . $! ) if !defined($content);

	my @problems;
	push( @problems, 'is not executable' ) if $self->opt('executable') && !-x $file;
	my $comment = $self->opt('comment');
	my @lines   = grep { !/$comment/ } split( /\n/, $content );
	foreach my $regex ( @{ $self->opt('regex') // [] } ) {
		push( @problems, 'has no line matching ' . $regex ) if !grep { /$regex/ } @lines;
	}
	foreach my $regex ( @{ $self->opt('not-regex') // [] } ) {
		push( @problems, 'has a line matching ' . $regex ) if grep { /$regex/ } @lines;
	}

	return $self->finish( $self->CRITICAL, $file . ' ' . join( ', ', @problems ) ) if @problems;

	return $self->finish( $self->OK, $file . ' looks good' );
} ## end sub check

1;
