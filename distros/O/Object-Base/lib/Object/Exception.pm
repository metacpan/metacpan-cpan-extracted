package Object::Exception;
=head1 NAME

Object::Exception - Multi-threaded exception class

=head1 VERSION

version 1.14

=head1 ABSTRACT

Multi-threaded exception class

	package SampleException;
	use Object::Base qw(Object::Exception);
	#
	package main;
	use Object::Exception;
	#
	# Enable DEBUG for traceback
	our $DEBUG = 1;
	#
	# throws Object::Exception type and its msg: Exception1
	eval
	{
		throw("Exception1");
	};
	if ($@)
	{
		warn $@ if ref($@) eq "Object::Exception";
	}
	#
	# throws SampleException type and its msg: This is sample exception
	sub sub_exception
	{
		SampleException->throw("This is sample exception");
	}
	eval
	{
		sub_exception();
	};
	if ($@) {
		# $@ and $@->message returns same result
		warn $@->message if ref($@) eq "SampleException";
	}
	#
	# throws Object::Exception type and its message: SampleException. Because msg is not defined!
	eval
	{
		SampleException->throw();
	};
	if ($@)
	{
		if (ref($@) eq "SampleException")
		{
			warn $@;
		} else
		{
			# warns 'This is type of Object::Exception and its message: SampleException'
			warn "This is type of ".ref($@)." and its message: $@";
		}
	}

=head1 DESCRIPTION

=head2 Functions

=head3 traceback($level)

returns array specified level of traceback by calling point of traceback function.

=head3 dump_trace(@trace)

returns string dump of trace array. Always ends with "\n".

=head3 throw($msg)

dies with new Object::Exception instance with specified message.

=head2 Methods

=head3 $class->new($msg)

returns new Object::Exception instance with specified message. If $main::DEBUG is setted TRUE, $object->debug attribute is setted 1.

=head3 $object->message()

returns message of Object::Exception instance. If $msg is defined with new() or throw(), always ends with "\n".
If $object->debug attribute is TRUE, dump generated with dump_trace is added to end of message.

=head3 $class->throw($msg)

dies with new Object::Exception derived-class instance with specified message. If B<$class> is not derived from Object::Exception,
does nothing. $msg value must be specified explicitly and it can be B<undef>. Otherwise, method runs as B<throw($class)> function.

=cut
use Object::Base qw(Exporter);
use overload '""' => \&message;


BEGIN
{
	require 5.008;
	$Object::Exception::VERSION = '1.14';
	@Object::Exception::EXPORT = qw(throw);
	@Object::Exception::EXPORT_OK = qw(traceback dump_trace);
}


attributes qw(:shared msg debug trace);


sub traceback
{
	my ($level) = @_;
	$level = 0 unless defined($level) and $level >= 0;
	my @result;
	while (scalar(my @caller = caller($level++)))
	{
		my @caller_next = caller($level);
		push @result, {
			package => $caller[0],
			filename => $caller[1],
			line => $caller[2],
			subroutine => $caller_next[3],
		};
	}
	return @result;
}

sub dump_trace
{
	my @trace = @_;
	my $result = "";
	my $i = 1;
	for my $trace (reverse @trace)
	{
		$result .= sprintf("%-".($i*1)."s", "");
		$result .= "in $trace->{package} ";
		$result .= "at ";
		$result .= "$trace->{subroutine} " if defined($trace->{subroutine});
		$result .= "$trace->{filename} ";
		$result .= "line $trace->{line}\n";
	} continue
	{
		$i++;
	}
	return $result;
}

sub throw
{
	my $class;
	if (@_ > 1)
	{
		$class = shift;
	} else
	{
		$class = __PACKAGE__;
	}
	my ($msg, $tracelevel) = @_;
	return unless defined($class) and not ref($class) and UNIVERSAL::isa($class, __PACKAGE__);
	my @trace;
	if (ref($msg))
	{
		return unless UNIVERSAL::isa($msg, __PACKAGE__);
		$class = ref($msg) if $class eq __PACKAGE__;
		unshift @trace, @{$msg->trace};
		$msg = $msg->msg;
	}
	my $self = $class->new($msg);
	$tracelevel = 0 unless defined($tracelevel);
	$tracelevel++;
	my @traceback = traceback($tracelevel);
	unless (@trace)
	{
		unshift @trace, @traceback;
	} else
	{
		unshift @trace, $traceback[0];
	}
	$self->trace(\@trace);
	die $self;
}
################################################################################

sub new
{
	my $class = shift;
	my ($msg) = @_;
	my $self = $class->SUPER();
	$self->msg($msg);
	$self->debug((defined($main::DEBUG) and $main::DEBUG)? 1: 0);
	$self->trace([]);
	return $self;
}

sub message
{
	my $self = shift;
	my ($debug) = @_;
	$debug = $self->debug unless defined($debug);
	my $msg = $self->msg;
	my $result = "";
	$result .= "$msg\n" if defined($msg) and not ref($msg);
	return $result unless $debug;
	$result .= dump_trace(@{$self->trace});
	return $result;
}


1;
__END__
=head1 REPOSITORY

B<GitHub> L<https://github.com/orkunkaraduman/p5-Object-Base>

B<CPAN> L<https://metacpan.org/release/Object-Base>

=head1 SEE ALSO

=over

=item *

L<Object::Base|https://metacpan.org/pod/Object::Base>

=back

=head1 AUTHOR

Orkun Karaduman <orkunkaraduman@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017  Orkun Karaduman <orkunkaraduman@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
