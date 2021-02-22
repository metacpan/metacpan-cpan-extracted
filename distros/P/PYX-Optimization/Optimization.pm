package PYX::Optimization;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Encode;
use Error::Pure qw(err);
use PYX qw(char comment);
use PYX::Parser;
use PYX::Utils;

our $VERSION = 0.04;

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Output encoding.
	$self->{'output_encoding'} = 'utf-8';

	# Output handler.
	$self->{'output_handler'} = \*STDOUT;

	# Process params.
	set_params($self, @params);

	# PYX::Parser object.
	$self->{'pyx_parser'} = PYX::Parser->new(
		'output_encoding' => $self->{'output_encoding'},
		'output_handler' => $self->{'output_handler'},
		'output_rewrite' => 1,
		'callbacks' => {
			'data' => \&_data,
			'comment' => \&_comment,
		},
		'non_parser_options' => {
			'output_encoding' => $self->{'output_encoding'},
		},
	);

	# Object.
	return $self;
}

# Parse pyx text or array of pyx text.
sub parse {
	my ($self, $pyx, $out) = @_;

	$self->{'pyx_parser'}->parse($pyx, $out);

	return;
}

# Parse file with pyx text.
sub parse_file {
	my ($self, $file, $out) = @_;

	$self->{'pyx_parser'}->parse_file($file, $out);

	return;
}

# Parse from handler.
sub parse_handler {
	my ($self, $input_file_handler, $out) = @_;

	$self->{'pyx_parser'}->parse_handler($input_file_handler, $out);

	return;
}

# Process data.
sub _data {
	my ($pyx_parser_obj, $data) = @_;

	my $tmp = PYX::Utils::encode($data);
	if ($tmp =~ /^[\s\n]*$/) {
		return;
	}

	# TODO Preserve?

	# White space on begin of data.
	$tmp =~ s/^[\s\n]*//s;

	# White space on end of data.
	$tmp =~ s/[\s\n]*$//s;

	# White space on middle of data.
	$tmp =~ s/[\s\n]+/\ /sg;

	$data = PYX::Utils::decode($tmp);
	my $out = $pyx_parser_obj->{'output_handler'};
	my $encoded_output = Encode::encode(
		$pyx_parser_obj->{'non_parser_options'}->{'output_encoding'},
		char($data),
	);
	print {$out} $encoded_output, "\n";

	return;
}

# Process comment.
sub _comment {
	my ($pyx_parser_obj, $comment) = @_;

	my $tmp = PYX::Utils::encode($comment);
	if ($tmp =~ /^[\s\n]*$/) {
		return;
	}
	$tmp =~ s/^[\s\n]*//s;
	$tmp =~ s/[\s\n]*$//s;
	$comment = PYX::Utils::decode($tmp);
	my $out = $pyx_parser_obj->{'output_handler'};
	my $encoded_output = Encode::encode(
		$pyx_parser_obj->{'non_parser_options'}->{'output_encoding'},
		comment($comment),
	);
	print {$out} $encoded_output, "\n";

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

PYX::Optimization - PYX optimization Perl class.

=head1 SYNOPSIS

 use PYX::Optimization;

 my $obj = PYX::Parser->new(%parameters);
 $obj->parse($pyx, $out);
 $obj->parse_file($pyx_file, $out);
 $obj->parse_handle($pyx_file_handler, $out);

=head1 METHODS

=head2 C<new>

 my $obj = PYX::Parser->new(%parameters);

Constructor.

Returns instance of object.

=over 8

=item * C<output_encoding>

Output encoding.
Default value is 'utf-8'.

=item * C<output_handler>

Output handler.
Default value is STDOUT.

=back

=head2 C<parse>

 $obj->parse($pyx, $out);

Optimize PYX string $pyx.
Output print to output handler.
If $out not present, use 'output_handler'.

Returns undef.

=head2 C<parse_file>

 $obj->parse_file($pux_file, $out);

Optimize PYX file $pyx_file.
Output print to output handler.
If $out not present, use 'output_handler'.

Returns undef.

=head2 C<parse_handler>

 $obj->parse_handle($pyx_file_handler, $out);

Optimize PYX file handler $pyx_file_handler.
Output print to output handler.
If $out not present, use 'output_handler'.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use PYX::Optimization;

 # Content.
 my $pyx_to_optimize = <<'END';
 (element
 - data \n data
 )element
 _       comment
 (element
 -                                 \n foo
 )element
 END

 PYX::Optimization->new->parse($pyx_to_optimize);

 # Output:
 # (element
 # -data data
 # )element
 # _comment
 # (element
 # -foo
 # )element

=head1 EXAMPLE2

 use strict;
 use warnings;

 use PYX::Optimization;

 if (@ARGV < 1) {
         print STDERR "Usage: $0 pyx_file\n";
         exit 1;
 }
 my $pyx_file = $ARGV[0];

 PYX::Optimization->new->parse_file($pyx_file);

 # Output:
 # Usage: __SCRIPT__ pyx_file

=head1 DEPENDENCIES

L<Class::Utils>,
L<Encode>,
L<Error::Pure>,
L<PYX>,
L<PYX::Parser>,
L<PYX::Utils>.

=head1 SEE ALSO

=over

=item L<Task::PYX>

Install the PYX modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/PYX-Optimization>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2011-2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
