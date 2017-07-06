package Parse::ErrorString::Perl;

use v5.8.7;
use strict;
use warnings;

our $VERSION = '0.26';

use Carp qw(carp cluck);
use Pod::Find ();
use Pod::POM 0.27 ();
use File::Spec                          ();
use File::Basename                      ();
use Parse::ErrorString::Perl::ErrorItem ();
use Parse::ErrorString::Perl::StackItem ();

sub new {
	my $class   = shift;
	my %options = @_;
	my $self    = bless {}, ref $class || $class;
	$self->_prepare_diagnostics;
	$self->_prepare_localized_diagnostics(%options);
	my %error_desc_hash = (
		W => 'warning',
		D => 'deprecation',
		S => 'severe warning',
		F => 'fatal error',
		P => 'internal error',
		X => 'very fatal error',
		A => 'alien error message',
	);
	$self->{error_desc_hash} = \%error_desc_hash;
	return $self;
}

sub parse_string {
	my $self   = shift;
	my $string = shift;

	# installs a sub named 'transmo', which returns the type of the error message
	if ( $self->{transmo} ) {
		no warnings 'redefine';
		eval $self->{transmo};
		carp $@ if $@;
		$self->{transmo} = undef;
	}

	my @hash_items = $self->_parse_to_hash($string);
	my @object_items;

	foreach my $item (@hash_items) {
		my $error_object = Parse::ErrorString::Perl::ErrorItem->new($item);
		push @object_items, $error_object;
	}

	return @object_items;
}

sub _prepare_diagnostics {
	my $self = shift;

	my $perldiag;
	my $pod_filename = Pod::Find::pod_where( { -inc => 1 }, 'perldiag' );

	if ( !$pod_filename ) {
		carp "Could not locate perldiag, diagnostic info will no be added";
		return;
	}

	my $parser = Pod::POM->new();
	my $pom    = $parser->parse_file($pod_filename);
	if ( !$pom ) {
		carp $parser->error();
		return;
	}

	my %transfmt = ();
	my %errors;
	foreach my $item ( $pom->head1->[1]->over->[0]->item ) {
		my $header = $item->title;
		$header =~ s/\n/ /g;

		my $content = $item->content;
		$content =~ s/\s*$//;
		$errors{$header} = $content;


		### CODE FROM SPLAIN

		#$header =~ s/[A-Z]<(.*?)>/$1/g;

		my @toks = split( /(%l?[dx]|%c|%(?:\.\d+)?s)/, $header );
		if ( @toks > 1 ) {
			my $conlen = 0;
			for my $i ( 0 .. $#toks ) {
				if ( $i % 2 ) {
					if ( $toks[$i] eq '%c' ) {
						$toks[$i] = '.';
					} elsif ( $toks[$i] eq '%d' ) {
						$toks[$i] = '\d+';
					} elsif ( $toks[$i] eq '%s' ) {
						$toks[$i] = $i == $#toks ? '.*' : '.*?';
					} elsif ( $toks[$i] =~ '%.(\d+)s' ) {
						$toks[$i] = ".{$1}";
					} elsif ( $toks[$i] =~ '^%l*x$' ) {
						$toks[$i] = '[\da-f]+';
					}
				} elsif ( length( $toks[$i] ) ) {
					$toks[$i] = quotemeta $toks[$i];
					$conlen += length( $toks[$i] );
				}
			}
			my $lhs = join( '', @toks );
			$transfmt{$header}{pat} = "    s<^$lhs>\n     <\Q$header\E>s\n\t&& return 1;\n";
			$transfmt{$header}{len} = $conlen;
		} else {
			$transfmt{$header}{pat} = "    m<^\Q$header\E> && return 1;\n";
			$transfmt{$header}{len} = length($header);
		}
	}

	$self->{errors} = \%errors;

	# Apply patterns in order of decreasing sum of lengths of fixed parts
	# Seems the best way of hitting the right one.
	my $transmo = '';
	for my $hdr ( sort { $transfmt{$b}{len} <=> $transfmt{$a}{len} } keys %transfmt ) {
		$transmo .= $transfmt{$hdr}{pat};
	}
	$transmo = "sub transmo {\n study;\n $transmo;  return 0;\n}\n";
	$self->{transmo} = $transmo;

	return;
}

sub _get_diagnostics {
	my $self = shift;
	local $_ = shift;
	eval { transmo(); };
	if ($@) {
		cluck($@);
	}
	return $self->{localized_errors}{$_} ? $self->{localized_errors}{$_} : $self->{errors}{$_};
}


# GOTCHAS OF "USE DIAGNOSTICS":
# 1. if error explanations are enabled (i.e. no '-traceonly'),
#    consecutive numbering at the end of the error message (e.g. "(#1)",
#    "(#2)", etc) will be appended
# 2. if error explanations are enabled, the original error messages
#    will be split into two lines if they exceed 79 characters
# 3. if a stack trace is to be printed, the error message will have
#    a tab prepended and will follow "Uncaught exception from user code:\n\t".
#	 This message may have been been printed already as part of the
#	 explanations.

sub _parse_to_hash {
	my $self   = shift;
	my $string = shift;

	if ( !$string ) {
		carp "parse_string called without an argument";
		return;
	}

	my $error_pattern = qr/
			^\s*			# optional whitespace
			(.*)			# $1 - the error message
			\sat\s(.*)		# $2 - the filename or eval
			\sline\s(\d+)	# $3 - the line number
			(?:
				\.						# end of error message
				|(?:					# or start collecting additional information
					(?:					# option 1: we have a "near" message
						,\snear\s\"(.*?)# $4 - the "near" message
						(\")?			# $5 - does the near message end on this line?
					)
					|(?:				# option 2: we have an "at" message
						,\sat\s(.*)		# $6 - the "at" message
					)
				)
			)?
			(?:\s\(\#\d+\))?	# "use diagnostics" appends "(#1)" at the end of error messages
			$/x;

	my @error_list;

	# check if error messages were split by diagnostics
	my @unchecked_lines = split( /\n/, $string );
	my @checked_lines;

	# lines after the start of the stack trace
	my @stack_trace;

	for ( my $i = 0; $i <= $#unchecked_lines; $i++ ) {
		my $current_line = $unchecked_lines[$i];
		if ( $current_line eq "Uncaught exception from user code:" ) {
			@stack_trace = @unchecked_lines[ ++$i .. $#unchecked_lines ];
			last;
		} elsif ( $i == $#unchecked_lines ) {
			push @checked_lines, $current_line;
		} else {
			my $next_line = $unchecked_lines[ $i + 1 ];
			my $test_line = $current_line . " " . $next_line;
			if (    length($current_line) <= 79
				and length($test_line) > 79
				and $next_line =~ /^\t.*\(\#\d+\)$/

				#and $test_line =~ $error_pattern
				)
			{
				$next_line =~ s/^\s*/ /;
				my $real_line = $current_line . $next_line;
				push @checked_lines, $real_line;
				$i++;
			} else {
				push @checked_lines, $current_line;
			}
		}
	}

	# file and line number where the fatal error occurred
	my ( $die_at_file, $die_at_line );

	# the items in the stack trace list
	my @trace_items;

	# the fatal error(s)
	my @stack_trace_errors;

	if (@stack_trace) {
		for ( my $i = 0; $i <= $#stack_trace; $i++ ) {
			if ( $stack_trace[$i] =~ /^\sat\s(.*)\sline\s(\d+)$/ ) {
				$die_at_file = $1;
				$die_at_line = $2;
				@trace_items = @stack_trace[ ++$i .. $#stack_trace ];
				last;
			} else {
				push @stack_trace_errors, $stack_trace[$i];
			}
		}
	}

	# used to check if we are in a multi-line 'near' message
	my $in_near;

	foreach my $line ( @checked_lines, @stack_trace_errors ) {

		# carriage returns may remain in multi-line 'near' messages and cause problems
		# $line =~ s/\r/ /g;
		# $line =~ s/\s+/ /g;
		if ( !$in_near ) {
			if ( $line =~ $error_pattern ) {
				my %err_item = (
					message => $1,
					line    => $3,
				);
				my $diagnostics = $self->_get_diagnostics($1);
				if ($diagnostics) {
					my $err_type = $self->_get_error_type($diagnostics);
					my $err_desc = $self->_get_error_desc($err_type);

					$err_item{diagnostics}      = $diagnostics;
					$err_item{type}             = $err_type;
					$err_item{type_description} = $err_desc;
				}
				my $file = $2;
				if ( $file =~ /^\(eval\s\d+\)$/ ) {
					$err_item{file_msgpath} = $file;
					$err_item{file}         = "eval";
				} else {
					$err_item{file_msgpath} = $file;
					$err_item{file_abspath} = File::Spec->rel2abs($file);
					$err_item{file}         = $self->_get_short_path($file);
				}
				my $near     = $4;
				my $near_end = $5;

				$err_item{at} = $6 if $6;

				if ( $near and !$near_end ) {
					$in_near = ( $near . "\n" );
				} elsif ( $near and $near_end ) {
					$err_item{near} = $near;
				}

				if (!grep {
						        $_->{message}      eq $err_item{message}
							and $_->{line}         eq $err_item{line}
							and $_->{file_msgpath} eq $err_item{file_msgpath}
					} @error_list
					)
				{
					push @error_list, \%err_item;
				}
			}
		} else {
			if ( $line =~ /^(.*)\"$/ ) {
				$in_near .= $1;
				$error_list[-1]->{near} = $in_near;
				undef $in_near;
			} else {
				$in_near .= ( $line . "\n" );
			}
		}
	}

	if (@trace_items) {
		my @parsed_stack_trace;
		foreach my $line (@trace_items) {
			if ( $line =~ /^\s*(.*)\scalled\sat\s(.*)\sline\s(\d+)$/ ) {
				my %trace_item = (
					sub          => $1,
					file_msgpath => $2,
					file_abspath => File::Spec->rel2abs($2),
					file         => $self->_get_short_path($2),
					line         => $3,
				);
				my $stack_object = Parse::ErrorString::Perl::StackItem->new( \%trace_item );
				push @parsed_stack_trace, $stack_object;
			}
		}

		for ( my $i = $#error_list; $i >= 0; $i-- ) {
			if ( $error_list[$i]->{file_msgpath} eq $die_at_file and $error_list[$i]->{line} == $die_at_line ) {
				$error_list[$i]->{stack} = \@parsed_stack_trace;
				last;
			}
		}
	}

	return @error_list;
}

sub _get_error_type {
	my ( $self, $description ) = @_;
	if ( $description =~ /^\(\u(\w)\|\u(\w)\W/ ) {
		return wantarray ? ( $1, $2 ) : "$1|$2";
	} elsif ( $description =~ /^\(\u(\w)\W/ ) {
		return $1;
	}
}

sub _get_error_desc {
	my ( $self, $error_type ) = @_;
	if ( $error_type =~ /^\u\w$/ ) {
		return $self->{error_desc_hash}->{$error_type};
	} elsif ( $error_type =~ /^\u(\w)\|\u(\w)$/ ) {
		return $self->{error_desc_hash}->{$1} . " or " . $self->{error_desc_hash}->{$2};
	}
}

sub _get_short_path {
	my ( $self, $path ) = @_;

	# my ($volume, $directories, $file) = File::Spec->splitpath($filename);
	# my @dirs = File::Spec->splitdir($directories);

	my ( $filename, $directories, $suffix ) = File::Basename::fileparse($path);
	if ( $suffix eq '.pm' ) {
		foreach my $inc_dir (@INC) {
			if ( $path =~ /^\Q$_\E(.+)$/ ) {
				return $1;
			}
		}

		return $path;

	} else {
		return $filename . $suffix;
	}
}

sub _prepare_localized_diagnostics {
	my $self    = shift;
	my %options = @_;

	return unless $options{lang};

	my $perldiag;
	my $pod_filename;

	$perldiag = 'POD2::' . $options{lang} . '::perldiag';
	$pod_filename = Pod::Find::pod_where( { -inc => 1 }, $perldiag );

	if ( !$pod_filename ) {
		carp "Could not locate localised perldiag, will use perldiag in English";
		return;
	}

	my $parser = Pod::POM->new();
	my $pom    = $parser->parse_file($pod_filename);
	if ( !$pom ) {
		carp $parser->error();
		return;
	}

	my %localized_errors;
	foreach my $item ( $pom->head1->[1]->over->[0]->item ) {
		my $header = $item->title;

		my $content = $item->content;
		$content =~ s/\s*$//;
		$localized_errors{$header} = $content;
	}

	$self->{localized_errors} = \%localized_errors;
}

1;

__END__

=head1 NAME

Parse::ErrorString::Perl - Parse error messages from the perl interpreter

=head1 SYNOPSIS

    use Parse::ErrorString::Perl;

    my $parser = Parse::ErrorString::Perl->new;
    # or: my $parser = Parse::ErrorString::Perl->new(lang => 'FR')
    # to get localized explanations
    my @errors = $parser->parse_string($string_containing_stderr_output);

    foreach my $error(@errors) {
    print 'Captured error message "' .
        $error->message .
        '" in file ' . $error->file .
        ' on line ' . $error->line . "\n";
    }


=head1 METHODS

=over

=item new(lang => $lang)

Constructor. Receives an optional C<lang> parameter, specifying that
error explanations need to be delivered in a language different from the
default (i.e. English). Will try to load C<POD2::$lang::perldiag>.

=item parse_string($string)

Receives an error string generated from the perl interpreter and
attempts to parse it into a list of C<Parse::ErrorString::Perl::ErrorItem>
objects providing information for each error.

=back

=head1 SEE ALSO

L<splain|http://perldoc.perl.org/splain.html>

=head1 ACKNOWLEDGEMENTS

Part of this module is based on code from L<splain|http://perldoc.perl.org/splain.html>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::ErrorString::Perl

=head1 AUTHOR

Petar Shangov, <pshangov at yahoo.com>

=head1 COPYRIGHT

Copyright 2008-2013 The Padre development team as listed in Padre.pm.
L<http://padre.perlide.org/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
