package IO::Detect;

use 5.008;
use constant { false => !1, true => !0 };
use strict;
use warnings;
use if $] < 5.010, 'UNIVERSAL::DOES';

BEGIN {
	$IO::Detect::AUTHORITY = 'cpan:TOBYINK';
	$IO::Detect::VERSION   = '0.203';
}

use namespace::clean 0.19;

EXPORTER:
{
	use base "Exporter::Tiny";
	
	our %_CONSTANTS;
	our @EXPORT    = qw( is_filehandle is_filename is_fileuri );
	our @EXPORT_OK = (
		qw( is_filehandle is_filename is_fileuri ),
		qw( FileHandle FileName FileUri ),
		qw( ducktype as_filehandle ),
	);
	our %EXPORT_TAGS = (
		smartmatch => [qw( FileHandle FileName FileUri )],
	);
	
	sub _exporter_validate_opts
	{
		require B;
		my $class = shift;
		$_[0]{exporter} ||= sub {
			my $into = $_[0]{into};
			my ($name, $sym) = @{ $_[1] };
			for (grep ref, $into->can($name))
			{
				B::svref_2object($_)->STASH->NAME eq $into
					and _croak("Refusing to overwrite local sub '$name' with export from $class");
			}
			"namespace::clean"->import(-cleanee => $_[0]{into}, $name);
			no strict qw(refs);
			no warnings qw(redefine prototype);
			*{"$into\::$name"} = $sym;
		}
	}
}

use overload qw<>;
use Scalar::Util qw< blessed openhandle reftype >;
use Carp qw<croak>;
use URI::file;

sub _lu {
	require lexical::underscore;
	goto \&lexical::underscore;
}

sub _ducktype
{
	my ($object, $methods) = @_;
	return unless blessed $object;
	
	foreach my $m (@{ $methods || [] })
	{
		return unless $object->can($m);
	}
	
	return true;
}

sub _generate_ducktype
{
	my ($class, $name, $arg) = @_;
	my $methods = $arg->{methods};
	return sub (;$) {
		@_ = ${+_lu} unless @_;
		push @_, $methods;
		goto \&_ducktype;
	};
}

my $expected_methods = [
	qw(close eof fcntl fileno getc getline getlines ioctl read print stat)
];

sub is_filehandle (;$)
{
	my $fh = @_ ? shift : ${+_lu};
	
	return true if openhandle $fh;
	
	# Logic from IO::Handle::Util
	{
		my $reftype = reftype($fh);
		$reftype = '' unless defined $reftype;
		
		if ($reftype eq 'IO'
		or  $reftype eq 'GLOB' && *{$fh}{IO})
		{
			for ($fh->fileno, fileno($fh))
			{
				return unless defined;
				return unless $_ >= 0;
			}
			
			return true;
		}
	}
	
	return true if blessed $fh && $fh->DOES('IO::Handle');
	return true if blessed $fh && $fh->DOES('FileHandle');
	return true if blessed $fh && $fh->DOES('IO::All');
	
	return _ducktype $fh, $expected_methods;
}

sub _oneline ($)
{
	!! ( $_[0] !~ /\r?\n|\r/s )
}

sub is_filename (;$)
{
	my $f = @_ ? shift : ${+_lu};
	return true if blessed $f && $f->DOES('IO::All');
	return true if blessed $f && $f->DOES('Path::Class::Entity');
	return ( length "$f" and _oneline "$f" )
		if blessed $f && overload::Method($f, q[""]);
	return ( length $f and _oneline $f )
		if defined $f && !ref $f;
	return;
}

sub is_fileuri (;$)
{
	my $f = @_ ? shift : ${+_lu};
	return $f if blessed $f && $f->DOES('URI::file');
	return URI::file->new($f->uri) if blessed $f && $f->DOES('RDF::Trine::Node::Resource');
	return URI::file->new($f) if $f =~ m{^file://\S+}i;
	return;
}

sub _generate_as_filehandle
{
	my ($class, $name, $arg) = @_;
	my $default_mode = $arg->{mode} || '<';
	
	return sub (;$$)
	{
		my $f = @_ ? shift : ${+_lu};
		return $f if is_filehandle($f);
		
		if (my $uri = is_fileuri($f))
			{ $f = $uri->file }
		
		my $mode = shift || $default_mode;
		open my $fh, $mode, $f
			or croak "Cannot open '$f' with mode '$mode': $!, died";
		return $fh;
	};
}

*as_filehandle = __PACKAGE__->_generate_as_filehandle('as_filehandle', +{});

{
	package IO::Detect::SmartMatcher;
	BEGIN {
		$IO::Detect::SmartMatcher::AUTHORITY = 'cpan:TOBYINK';
		$IO::Detect::SmartMatcher::VERSION   = '0.203';
	}
	use Scalar::Util qw< blessed >;
	use overload (); no warnings 'overload';  # '~~' unavailable in Perl 5.8
	use overload
		'""'     => 'to_string',
		'~~'     => 'check',
		'=='     => 'check',
		'eq'     => 'check',
		fallback => 1;
	sub check
	{
		my ($self, $thing) = @_;
		$self->[1]->($thing);
	}
	sub to_string
	{
		shift->[0]
	}
	sub new
	{
		my $proto = shift;
		if (blessed $proto and $proto->isa(__PACKAGE__))
		{
			return "$proto"->new(@_);
		}
		bless \@_ => $proto;
	}
}

use constant FileHandle => IO::Detect::SmartMatcher::->new(FileHandle => \&is_filehandle);
use constant FileName   => IO::Detect::SmartMatcher::->new(FileName   => \&is_filename);
use constant FileUri    => IO::Detect::SmartMatcher::->new(FileUri    => \&is_fileuri);

true;

__END__

=pod

=encoding utf8

=for stopwords frickin' filehandliness

=head1 NAME

IO::Detect - is this a frickin' filehandle or what?!

=head1 SYNOPSIS

	use IO::Detect;
	
	if (is_filehandle $fh)
	{
		my $line = <$fh>;
	}

=head1 DESCRIPTION

It is stupidly complicated to detect whether a given scalar is
a filehandle (or something filehandle like) in Perl. This module
attempts to do so, but probably falls short in some cases. The
primary advantage of using this module is that it gives you
somebody to blame (me) if your code can't detect a filehandle.

The main use case for IO::Detect is for when you are writing
functions and you want to allow the caller to pass a file as
an argument without being fussy as to whether they pass a file
name or a file handle.

=head2 Functions

Each function takes a single argument, or if called with no
argument, operates on C<< $_ >>.

=over

=item C<< is_filehandle $thing >>

Theoretically returns true if and only if $thing is a file handle,
or may be treated as a filehandle. That includes blessed references
to filehandles, things that inherit from IO::Handle, etc.

It's never going to work 100%. What Perl allows you to use as a
filehandle is mysterious and somewhat context-dependent, as the
following code illustrates.

	my $fh = "STD" . "OUT";
	print $fh "Hello World!\n";

=item C<< is_filename $thing >>

Returns true if $thing is a L<IO::All> object or L<Path::Class::Entity>
or L<any non-reference, non-zero-length string with no line breaks>.
That's because depending on your operating system, virtually anything
can be used as a filename. (In fact, on many systems, including Linux,
filenames can contain line breaks. However, this is unlikely to be
intentional.)

This function doesn't tell you whether $thing is an existing file on
your system. It attempts to tell you whether $thing could possibly be
a filename on some system somewhere.

=item C<< is_fileuri $thing >>

Returns true if $thing is a URI beginning with "file://". It
allows for L<URI> objects, L<RDF::Trine::Node::Resource> objects,
strings and objects that overload stringification.

This function actually returns an "interesting value of true". The
value returned is a L<URI::file> object.

=item C<< as_filehandle $thing, $mode >>

Returns $thing if it is a filehandle; otherwise opens it with mode
$mode (croaking if it cannot be opened). $mode defaults to "<" (read
access).

This function is not exported by default, but needs to be requested
explicitly:

	use IO::Detect qw(as_filehandle);

You may even specify a different default mode, or import it several
times with different names:

	use IO::Detect 
	  as_filehandle => { -as => 'as_filehandle_read',  mode => '<' },
	  as_filehandle => { -as => 'as_filehandle_write', mode => '>' };

=back

=head2 Smart Matching

You can import three constants for use in smart matching:

	use IO::Detect -smartmatch;

These constants are:

=over

=item C<< FileHandle >>

=item C<< FileName >>

=item C<< FileUri >>

=back

They can be used like this:

	if ($file ~~ FileHandle)
	{
		...
	}

Note that there does exist a L<FileHandle> package in Perl core. This
module attempts to do the right thing so that C<< FileHandle->new >>
still works, but there are conceivably places this could go wrong, or
be plain old confusing.

Although C<is_filehandle> and its friends support Perl 5.8 and above,
smart match is only available in Perl 5.10 onwards.

=head2 Use with Scalar::Does

The smart match constants can also be used with L<Scalar::Does>:

	if (does $file, FileHandle)
	{
		...;
	}
	elsif (does $file, FileName)
	{
		...;
	}

=head2 Precedence

Because there is some overlap/ambiguity between what is a filehandle
and what is a filename, etc, if you need to detect between them, I
recommend checking C<is_filehandle> first, then C<is_fileuri> and
falling back to C<is_filename>.

	for ($file)
	{
		when (FileHandle)  { ... }
		when (FileUri)     { ... }
		when (FileName)    { ... }
		default            { die "$file is not a file!" }
	}

=head2 Export

Like Scalar::Does, IO::Detect plays some tricks with L<namespace::clean> to
ensure that any functions it exports to your namespace are cleaned up when
you're finished with them.

=head3 Duck Typing

In some cases you might be happy to accept something less than a
complete file handle. In this case you can import a customised
"duck type" test...

	use IO::Detect
		-default,
		ducktype => {
			-as     => 'is_slurpable',
			methods => [qw(getlines close)],
		};
	
	sub do_something_with_a_file
	{
		my $f = shift;
		if ( is_filehandle $f or is_slurpable $f )
			{ ... }
		elsif ( is_filename $f )
			{ ... }
	}

Duck type test functions only test that the argument is blessed
and can do all of the specified methods. They don't test any other
aspect of "filehandliness".

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=IO-Detect>.

=head1 SEE ALSO

This module is an attempt to capture some of the wisdom from this
PerlMonks thread L<http://www.perlmonks.org/?node_id=980665> into
executable code.

Various other modules that may be of interest, in no particular
order...
L<Scalar::Does>,
L<Scalar::Util>,
L<FileHandle>,
L<IO::Handle>,
L<IO::Handle::Util>,
L<IO::All>,
L<Path::Class>,
L<URI::file>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

