package Template::Plugin::Java;

($VERSION) = '$ProjectVersion: 0.4 $' =~ /\$ProjectVersion:\s+(\S+)/;

=head1 NAME

Template::Plugin::Java - Generate Java Classes from XML description files and templates.

=head1 SYNOPSIS

From an xml file such as:

	<aBean>
		<java: option1="value1">
			<option2>value2</option2>
		</java:>
		<foo>10</foo>
		<bar>String</bar>
		<container>
			<baz>20</baz>
		</container>
	</aBean>

Through the program "tjava":

tjava [options] [file.xml ...]

Via a template, such as:

	[% USE Java %]
	package $package;
	
	public class $class {
	
	[% FOREACH Java.variables %]
	$type $name = $initializer;
	[% END %]
	
	//... etc
	}

To generated Java source code in the appropriate directory as determined by the
package of the .xml file's directory, specified package option if any, and
CLASSPATH.

=head1 OPTIONS

Any options may be given besides those listed, these are passed directly to the
Templates being processed in the stash (the variable table at time of
processing). They can be given in the <java:> ... </java:> section of an XML
file (in which case, don't use the -- dashes) as attributes or elements, or on
the command line.

=over 8

=item B<--template>

Name of the template to process. No extension is assumed by default unlike in
the previous version.

=item B<--package>

Destination package to put the generated classes, otherwise will be determined
from how the current directory relates to the CLASSPATH.

=item B<--class>

Class name to use, otherwise will infer from the root tag of the XML file.

=item B<--templatePath>

Colon separated path where the templates can be found, overrides the
environment variable TEMPLATEPATH. This doesn't work right now, so use the
TEMPLATEPATH environment variable.

=item B<--genContainers>

If set to 0, classes for subcontainers will not be generated. This is generally
not useful.

=item B<--containerTemplate>

By default set to F<Container>, this is the default template, as well
as the template used for sub-containers.

=item B<--containerNamePrefix>

By default, if generating class Foo that needs to have a sub container wrapped
in tag <bar>, it's name will be FooBar. This is safe and won't cause collisions
with different classes having sub containers of the same name (until some sort
 of dependency checking code is introduced). To turn this off, set it to the
empty string "".

=item B<--interface>

Interface to add to list of implemented interfaces, can be supplied multiple
times. Make sure you append any necessary code to implement any of these
interfaces.

=item B<--append>

Text to insert in the generated class body.

=item B<--appendFile>

Will insert text read from the file specified into the generated class body.
This option and the B<--append> option are mutually exclusive.

=item B<--file[s]>

The XML file(s) to parse. This is useful for when the Plugin is instantiated
from a custom script, not via tjava or inside a template.

Any other option will be placed into the stash for the templates to use, making
tjava very useful with your custom templates.

Anything that's not an option will be assumed to be a file.

=back

=head1 DESCRIPTION

Template::Plugin::Java is a plugin module for the Template toolkit that makes
it easier to write templates for generating Java source code, ultimately for
transforming XML descriptions into Java language sources.

It can be used either directly on the command line, or loaded from a Template
with a C<[% USE Java %]> statement, or in many other ways. It tries to be
intelligent and figure out what context you are using it in.

I'll write more eventually, for now see the examples in the distribution.

=head1 METHODS

=over 8

=cut

require Template::Plugin;
@ISA = 'Template::Plugin';

use strict;
use Carp qw/verbose croak/;
use Template::Plugin::Java::Utils qw(
	parseOptions findPackageDir isNum determinePackage createTemplate
	parseCmdLine javaTypeName
);
use Template::Plugin::Java::Constants qw/:all/;

=item B<new>

This, the constructor, does everything necessary to create a new instance of
the Java plugin, based on context. If not given a context, takes control of the
command line and then parses any options and files given. This is what the
"tjava" utility does.

=cut
sub new {
	use XML::Simple;
	use File::Basename;

	my $class	= shift;
	my $self	= bless {}, ref $class || $class;
	my $context;
	my $params	= {};
	my $arg1	= $_[0];

	if (@_ <= 1 && not ref $arg1) {
		$params->{file} = shift;
	} elsif (not ref $arg1) {
		$params = {@_};
	} elsif (UNIVERSAL::isa($arg1, 'Template::Context')) {
		$self->context(shift);
	} elsif (UNIVERSAL::isa($arg1, 'HASH')) {
		$params = { %{+shift}, @_ };
	}

	$self->context(delete $params->{context});

	my $defaults = delete $params->{defaults} || {};
	my $cmd_line = delete $params->{cmdLine} || {};

# Automatically parse the command line unless either explicitly told not to, or
# a the object has been created inside a template as an actual plugin.
	unless ((exists $params->{parseCmdLine}
	 && (not $params->{parseCmdLine}))
	 || $self->context) {
		$cmd_line = {
			%$cmd_line,
			parseOptions( parseCmdLine )
		};

# Use rest of @ARGV as files.
		push @{$params->{files}}, @ARGV;
		@ARGV = ();
	}

	unless ($self->context) {
		$self->template (
			createTemplate delete $params->{templateOptions}
		);
	}

	my $files    = delete $params->{file} || delete $params->{files};

	my @files;
	if (defined $files) {
		if (UNIVERSAL::isa($files, 'ARRAY')) {
			@files = @$files;
		} else {
			push @files, $files;
		}
	}

# The ! eof STDIN is necessary here, because sub-templates will want to create
# new instances of this Plugin, when the process still has a redirected STDIN,
# just with no data to read. Using eof on a terminal is bad, but this doesn't
# happen because of the && short circuit.
	if (scalar @files == 0 && ! -t STDIN && ! eof STDIN) {
		push @files, '-';
	}

	for my $file_name (@files) {
		my $stash;

		if ($file_name ne '-') {
# Prepend ./ if relative path.
			$file_name =~ s!^([^/-])!./$1!;
			$stash  = XMLin (
				$file_name,
				keyattr => "",
				keeproot => 1,
				cache => 'storable'
			);
		} else {
# Reading from STDIN.
			my $data;
			{
				local @ARGV = '-';
				$data = join '', <>;
			}
			$stash = XMLin (
				$data,
				keyattr => "",
				keeproot => 1,
			);
		}

		my $root   = (keys %$stash)[0];
		$stash     = {%{$stash->{$root}}};

		my $context = delete $stash->{'java:'} || {};

		$stash = {
			parseOptions(
				%$defaults,
				%$params,
				%$context,
				%$cmd_line
			),
			variables => $stash
		};

		$stash->{tag}		= $root;
		$stash->{class}		||= ucfirst $root;

# Allow nopackage="true" to create a class that isn't in a package.
		{
# Turn off warnings about comparing uninitialized values.
			local $^W = undef;

			if (!$stash->{package} && $stash->{package} ne '0') {
				$stash->{package} =
					determinePackage dirname($file_name);
			}
		}

		$stash->{genContainers} ||= TRUE;
		$stash->{containerTemplate} ||= 'Container';
		$stash->{template}	||= $stash->{containerTemplate};

		$stash->{containerNamePrefix} = $stash->{class}
			if not exists $stash->{containerNamePrefix};

		if (exists $stash->{appendFile}) {
			use IO::File;
			my $file = new IO::File $stash->{appendFile}
				or die "Could not open $stash->{appendFile}";
			local $/ = undef;
			$stash->{append} .= <$file>;
		}

		$self->genClass($stash);
	}

	return $self;
}

=item B<template>

Sets the Template of the instance (and therefore the context) when called with
a parameter, returns it otherwise.

=cut
sub template {
	my ($self, $template) = @_;

	if ($template) {
		$self->{template} = $template;
		$self->context($template->context);
	}
	
	return $self->{template};
}

=item B<context>

Sets the Template::Context of the instance when called with a parameter,
returns it otherwise.

=cut
sub context  { $_[0]->{context} = $_[1] || $_[0]->{context}  }

=item B<getInitializer>

Returns an initializer string for a type.

=cut
sub initializer {
	my ($self, $type) = @_;
	$type ||= $self->context->stash->get('type');

# Can check if user defined, for example StringInitializer="null" in xml file
# or template, and use that. But only if not called as a static method.
	if (ref $self) {
		my $res = $self->context->stash->get($type.'Initializer');
		return $res if defined $res && $res ne "";
	}

	return '""'	if $self->string($type);

	return $self->encapsulatePrimitive($type).".MIN_VALUE"
			if $self->scalar($type);

        return "new $type(0)"
                        if $type eq 'java.sql.Date' || $type eq 'Date';
	
	return undef	if $type =~ /\[\]$/;

	return "new $type()";
}

=item B<variables>

Returns a list of variable description hashes.

=cut
sub variables {
	my ($self, $options) = @_;

	my $vars = $self->getVariables (
		$self->context->stash->get('variables'),
		$options
	);

	return [ map {
		my $key  = $_;
		my $type = $self->mapType($key, $vars->{$key});

# Returns a hashref for each map iteration:
		{
			name	=> $key,
			capName	=> ucfirst $key,
			type	=> $type,
			typeName=> javaTypeName $type,
			value	=> $vars->{$key},
			initializer => $self->initializer($type)
		};
	} (sort keys %$vars) ];
}

=item B<variableDeclarations($options_hashref)>

Returns a list of <type> <name> strings such as:
	String foo
	int bar
	...

These can be used in a template in this way:
	function ([% Java.variableDeclarations.join(", ") %]) {
	...
	}

=cut
sub variableDeclarations {
	my ($self, $options) = @_;

	my $vars = $self->getVariables (
		$self->context->stash->get('variables'),
		$options
	);
	
	return [ map {
		my $key = $_;
		$self->mapType($key, $vars->{$key}).' '.$key;
	} (sort keys %$vars) ];
}

=item B<variableNames>

Returns a list of variable names.

=cut
sub variableNames {
	my ($self, $options) = @_;

	return [
		keys %{ $self->getVariables (
			$self->context->stash->get('variables'),
			$options
		)}
	];
}

=item B<getVariables>

Returns a hashref of variables, taking a raw variables hash.
Takes an optional variable type string.

=cut
sub getVariables {
	my ($self, $vars, $options) = @_;
	$options ||= { type => 'All' };

	if ($options->{type} eq 'ScalarArray') {
		1;
	}

# Don't spew out stuff belonging to our namespace.
	my @names = grep { !/^java:/ } keys %$vars;
	my %vars;

	if ($options->{type} eq 'All') {
		@vars{@names} = @$vars{@names};
	} elsif ($options->{type} eq 'Scalar') {
		for my $n (@names) {
			if ($self->scalar($self->mapType($n, $vars->{$n}))) {
				$vars{$n} = $vars->{$n};
			}
		}
        } elsif ($options->{type} eq 'Composite') {
		for my $n (@names) {
                        if (!$self->scalar($self->mapType($n, $vars->{$n}))
                            and
			    !$self->array($self->mapType($n, $vars->{$n}))
			    and
			    $self->mapType($n, $vars->{$n}) !~ /\[\]/) {
				$vars{$n} = $vars->{$n};
			}
                }
	} elsif ($options->{type} eq '!Scalar') {
		for my $n (@names) {
			if (!$self->scalar($self->mapType($n, $vars->{$n}))){
				$vars{$n} = $vars->{$n};
			}
		}
        } elsif ($options->{type} eq '!Composite') {
                for my $n (@names) {
			if ($self->scalar($self->mapType($n, $vars->{$n}))
                            or
                            $self->array($self->mapType($n, $vars->{$n}))) {
				$vars{$n} = $vars->{$n};
			}
                }
        } elsif ($options->{type} eq 'ScalarArray') {
                for my $n (@names) {
                        if ($self->array($self->mapType($n, $vars->{$n}))
                            and
                            $self->scalar($self->arrayType($n, $vars->{$n}))) {
				$vars{$n} = $vars->{$n};
			}
                }
        } elsif ($options->{type} eq 'CompositeArray') {
                for my $n (@names) {
                        if ($self->array($self->mapType($n, $vars->{$n}))
                            and
                            !$self->scalar($self->arrayType($n, $vars->{$n}))
                            and
                            !$self->array($self->arrayType($n, $vars->{$n}))) {
				$vars{$n} = $vars->{$n};
			}
                }
        } else {
                die "Unknown option $options->{type}";
        }

	return \%vars;
}

=item B<scalar>

Whether or not a java type is a Scalar type.

=cut
sub scalar {
	my ($self, $type) = @_;
	$type ||= $self->context->stash->get('type');

	return TRUE if $type =~ /@{[SCALAR]}/;
	return FALSE;
}

=item B<string>

Whether or not a java type is a String type.

=cut
sub string {
	my ($self, $type) = @_;
	$type ||= $self->context->stash->get('type');

	return $1 if $type =~ /@{[STRING]}/;
	return undef;
}

=item B<array>

Whether or not a java type is an Array type.

=cut
sub array {
	my ($self, $type) = @_;
	$type ||= $self->context->stash->get('type');

	return $1 if $type =~ /@{[ARRAY]}/;
	return undef;
}

=item B<arrayType>

Figures out the type of elements a Vector will take.
Parameters: name, arrayref
TODO: This should be an aggregate, not merely the type of the first element.

=cut
sub arrayType {
	my ($self, $name, $value) = @_;

	my $type = $self->mapType($name, $value->[0]);

	if ($self->scalar($type)) {
		return $self->encapsulatePrimitive($type);
	}

	return $type;
}

=item B<encapsulatePrimitive>

Translate int to Integer, long to Long, etc.

=cut
sub encapsulatePrimitive {
	my ($self, $type) = @_;

	if ($type eq 'int') {
		return 'Integer';
	} else {
		return ucfirst $type;
	}
}

{ # Closure over type cache.

my %cache;

=item B<mapType>

Maps a perl scalar or reference to a Java type.
Parameters: name of element, value of element.

=cut
sub mapType {
	my $self	= shift;
	my $name	= shift || croak "name required";
	my $value	= shift || croak "value required";

	my $type	= ref $value;
	my $result;

	return $cache{"$name $type"} if exists $cache{"$name $type"};

	if (not $type) { # I.E. a scalar.
		my $is_num = isNum $value;

		if ($is_num && $value =~ /\./) {
			$result = 'double';
		} elsif ($is_num) {
			$result = 'int';
		} else {
			$result = 'String';
		}
	} elsif($type eq 'ARRAY') {
		$result = 'Vector';
	} elsif($type eq 'HASH') {
		my @keys = keys %$value;

# Could be pre-mapped to a java type.
		if (exists $value->{'java:type'}) {
			$result = $value->{'java:type'};
		} else {
# Sub-container.
			my $s = $self->context->stash;
			if ($s->get('genContainers')) {
				$result = $self->genClass ({
					tag => $name,
					class =>
					 $s->get('containerNamePrefix')
					 ."\u$name",
					template =>
					 $s->get('containerTemplate'),
					variables => $value
				});
			} else {
				$result = 'Container';
			}
		}
	} else {
		die "Cannot map type $type to a Java type";
	}

	$cache{"$name $type"} = $result;

	return $result;
}

} # End closure.

=item B<genClass>

Generates a container class.

Parameters: name of tag to create container from, hashref to gen from.
Returns:    name of class generated.

=cut
sub genClass {
	my ($self, $hash) = @_;

	my $context = $self->context;

	my $variables = delete $hash->{variables};

	my $v = delete $variables->{'java:'} || {};
	$v = {
		%{$v},
		%{$hash}
	};

	$v->{destFile} = $v->{class}.".java";

	if (exists $v->{package}) {
		$v->{destFile} = findPackageDir (
			$v->{package}
		).$v->{destFile};
	}

	$context->localise({
		%{$v},
		variables => $variables
	});

# If not using version 2+ of Template, the context needs the output to be
# redirected to the appropriate file.
	if ($Template::VERSION =~ /^[01]/) {
# This is necessary for compiling with the newer version, since the
# TEMPLATE_OUTPUT constant is gone:
	 	my $redirect_constant =
			&{Template::Constants->can('TEMPLATE_OUTPUT')}();

		my $old_output_handle = $context->redirect(
			$redirect_constant,
			$v->{destFile}
		);

		$context->process($v->{template});

		$context->redirect(
			$redirect_constant,
			$old_output_handle
		);
	} else {
# In Template version 2+ process returns the output of processing a template.
		my $handle = new IO::File "> $v->{destFile}"
			or croak "Could not write to $v->{destFile}: $!";

		print $handle $context->process($v->{template});
		$handle->close;
	}

	$context->delocalise;

# Put variables back.
	$hash->{variables} = $variables;

# Return fully qualified name, or just name.
	if (exists $v->{package}) {
		return $v->{package}.".".$v->{class};
	} else {
		return $v->{class};
	}
}

=item B<castJavaString>

Casts a java String to another type using the appropriate code.
Parameters: name of variable to cast, type to cast to.

=cut
sub castJavaString {
	my $self = shift;
	&Template::Plugin::Java::Utils::castJavaString;
}

1;

__END__

=back

=head1 ENVIRONMENT

These are the environment variables used.

=over 8

=item B<TEMPLATEPATH>

Colon separated path to where templates can be found. Overridden by the
B<--templatePath> command line option.

=item B<CLASSPATH>

Used for many things, like inferring the package of the current directory,
where to put generated files that are in other packages, and other evil things
I have not yet thought of.

=back

=head1 AUTHOR

Rafael Kitover (caelum@debian.org)

=head1 COPYRIGHT

This program is Copyright (c) 2000 by Rafael Kitover. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=head1 BUGS

Probably many.

The B<--templatePath> option should actually work.

=head1 TODO

A very great deal.
Including more documentation.
DBClass doesn't work in tt 1.x.
Non-sense options in java: contexts should be somehow handled?

=head1 SEE ALSO

L<perl(1)>,
L<Template(3)>,
L<Template::Plugin::Java::Utils(3)>,
L<Template::Plugin::JavaSQL(3)>
L<Template::Plugin::Java::Constants(3)>,

=cut
