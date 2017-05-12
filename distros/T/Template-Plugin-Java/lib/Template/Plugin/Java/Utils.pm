package Template::Plugin::Java::Utils;

=head1 NAME

Template::Plugin::Java::Utils - Utility functions for Template::Plugin::Java.

=head1 SYNOPSIS

	use Template::Plugin::Java::Utils qw/list of subroutines to import/;

=head1 SUBROUTINES

=over 8

=cut

@EXPORT_OK = qw(
	parseOptions sqlType2JavaType simplifyPath findPackageDir isNum
	castJavaString determinePackage createTemplate parseCmdLine
	javaTypeName
);

use strict;
use base qw(Exporter);
use Carp;
use Template::Plugin::Java::Constants qw/:all/;

=item B<createTemplate>

Creates a new Template with reasonable options.

=cut
sub createTemplate {
	use Template;
	use Template::Constants qw/:status/;
	my %options = ref $_[0] ? %{+shift} : @_
		if $_[0];
	
# Enable template compilation if version of Template is 2 or greater.
	if ($Template::VERSION !~ /^[01]/) {
		$options{COMPILE_EXT} = '.compiled';
	}

	my $template = new Template({
		INTERPOLATE	=> 1,
		EVAL_PERL	=> 1,
		PRE_CHOMP	=> 1,
		RECURSION	=> 1,
		INCLUDE_PATH	=> $ENV{TEMPLATEPATH},
		CATCH		=> {'default' => sub {
			my ($context, $type, $info) = @_;
			print STDERR "Error generating class "
				. $context->stash->get("class")
				. ":\n\t$type: $info\n\n\n";
			return STATUS_STOP;
		}},
		%options
	});

	return $template;
}

=item B<parseOptions>

Replaces c_c with cC and nosomething=whatever with something=0 in the keys of a
hash.

=cut
sub parseOptions {
	my %options = ();

	if (@_ > 1) {
		%options = @_;
	} elsif (defined $_[0] and UNIVERSAL::isa($_[0], 'HASH')) {
		%options = %{+shift};
	}

	for my $option (keys %options) {
		if ($option =~ /^no(.*)/) {
			delete $options{$option};
			$option = $1;
			$options{$option} = 0;
		}
		if (($_ = $option) =~ s/_(\w)/\U$1/g) {
			$options{$_} = delete $options{$option};
		}
	}

	return wantarray ? %options : \%options;
}

=item B<setOption>

Adds to or sets an option in a hash, supports nested arrays and boolean
options. The logic here is one of those things that just works the way it is
and seems decipherable, but don't mess with it.

=cut
sub setOption (\%$;$) {
	my ($options, $option, $value) = @_;

	if (not exists $options->{$option}) {
		$options->{$option} = $value || TRUE;
	} elsif (not ref $options->{$option}) {
		if ($options->{$option} ne TRUE && $value) {
			$options->{$option} = [ $options->{$option}, $value ];
		} elsif (not $value) {
			return;
		} else {
			$options->{$option} = $value;
		}
	} elsif (not $value) {
		return;
	} elsif (ref $options->{$option} eq 'ARRAY') {
		push @{$options->{$option}}, $value;
	} elsif (ref $options->{$option} eq 'HASH') {
		$options->{$option}{$value} = TRUE;
	} elsif (UNIVERSAL::can($options->{$option}, $value)) {
		$options->{$option}->$value();
	}
}

=item B<parseCmdLine>

Parses @ARGV into a hash of options and values, leaving everything else that
is most likely a list of files on @ARGV.

=cut
sub parseCmdLine () {
	my (%options, @files);

	my ($value, $last_option, $last_option_had_value);

	while (defined ($_ = shift @ARGV)) {
		last if /^--$/;

		if (/^[-+]+(.*)=?(.*)/) {
			$last_option		= $1;
			$value			= $2;
			setOption %options, $last_option, $value;
			$last_option_had_value	= $2 ? TRUE : FALSE;
		} elsif ((not $last_option_had_value) && $last_option) {
			setOption %options, $last_option, $_;
			$last_option_had_value	= TRUE;
		} else {
			push @files, $_;
		}
	}

	push @ARGV, @files;
	return \%options;
}

=item B<sqlType2JavaType( type_name [, precision for numeric types] )>

Maps some ANSI SQL data types to the closest Java variable types. The default
case is byte[] for unrecognized sql types.

=cut
sub sqlType2JavaType ($;$) {
	($_, my $precision) = @_;

	/^.*char$/i	&& return 'String';
	/^integer$/i	&& return 'int';
	/^bigint$/i	&& return 'long';
	/^smallint$/i	&& return 'short';

	/^numeric$/i	&& do {
		$precision <= 5	&& return 'short';
		$precision <= 10&& return 'int';
				   return 'long';
	};

	/^date$/i	&& return 'Date';

	return 'byte[]';
}

=item B<simplifyPath( path )>

Remove any dir/../ or /./ or extraneous / from a path, as well as prepending
the current directory if necessary.

=cut
sub simplifyPath ($) {
	use URI::file;
	my $path = shift;

	return URI::file->new_abs($path)->file;
}

=item B<findPackageDir( directory )>

Find package in $ENV{CLASSPATH}.

=cut
sub findPackageDir ($) {
	my $package	= shift;
	my $classpath	= $ENV{CLASSPATH};
	my @classpath	= split /:/, $classpath;
	my @package	= split /\./, $package;
	my $package_dir	= join ("/", @package) . "/";

# Find the first match in CLASSPATH.
	for (map { "$_/$package_dir" } @classpath) {
		return $_ if -d;
	}

	return "";
}

=item B<determinePackage([ optional directory ])>

Determine the package of the current or passed-in directory.

=cut
sub determinePackage (;$) {
	my $dir = shift || ".";
	my @cwd = split m|/|, substr ( simplifyPath $dir, 1 );

	my $i = @cwd;
	while ($i--) {
		my $package = join ('.', @cwd[$i..$#cwd]);

		if (findPackageDir $package) {
			return $package;
		}
	}

	return join ('.', @cwd);	# If all else fails.
}

=item B<isNum( string )>

Determines whether a string is a number or not. Uses the more powerful
DBI::looks_like_number heuristic if available.

=cut
my $isNum_body;
eval { require DBI };
if (not $@ && DBI->can('looks_like_number')) {
	$isNum_body = sub {
		if (DBI::looks_like_number( shift )) {
			return TRUE;
		} else {
			return FALSE;
		}
	};
} else {
	$isNum_body = sub {
		local $^W = undef if $^W;
		$_	  = shift;

		if (not defined $_) {
			return FALSE;
		} elsif ($_ != 0 or /^0*(?:\.0*)$/) {
			return TRUE;
		} else {
			return FALSE;
		}
	}
}

# Install the sub reference as the sub.
{
	no strict 'refs';

	*{__PACKAGE__.'::isNum'} = $isNum_body;
}

=item B<castJavaString( variable_name, target_type )>

Casts a java String to another type using the appropriate code.

=cut
sub castJavaString {
	my ($name, $type) = @_;

	for ($type) {
		/String/&& do { return $name };
		/int/	&& do { return "Integer.parseInt($name)" };
		/@{[SCALAR]}/ && do {
			my $type = $1;
			if ($type =~ /^[A-Z]/) {
				return "new $type($name)";
			} else {
				return "\u$type.parse\u$type($name)";
			}
		};
		die "Cannot cast $name from String to $type.";
	}
}

=item B<javaTypeName( javaType )>

Transform a java type name to a character string version. In other words,
String remains String, but byte[] becomes byteArray.

=cut
sub javaTypeName ($) {
	local $_ = pop;
	s/\[\]/Array/g;

	return $_;
}

1;

__END__

=back

=head1 ENVIRONMENT

These are the environment variables used.

=over 8

=item B<TEMPLATEPATH>

Colon separated path to where templates can be found, used by default in the
B<createTemplate> subroutine.

=item B<CLASSPATH>

Searched in B<findPackageDir> to find a directory relative to it.

=back

=head1 AUTHOR

Rafael Kitover (caelum@debian.org)

=head1 COPYRIGHT

This program is Copyright (c) 2000 by Rafael Kitover. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=head1 BUGS

None known.

=head1 TODO

Nothing here.

=head1 SEE ALSO

L<perl(1)>,
L<Template(3)>,
L<Template::Plugin::Java(3)>,
L<Template::Plugin::JavaSQL(3)>
L<Template::Plugin::Java::Constants(3)>,

=cut
