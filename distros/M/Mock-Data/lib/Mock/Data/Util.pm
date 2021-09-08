package Mock::Data::Util;
use strict;
use warnings;
require Carp;
our @CARP_NOT= qw( Mock::Data Mock::Data::Generator );
require Exporter;
our @ISA= qw( Exporter );
our @EXPORT_OK= qw( uniform_set weighted_set inflate_template coerce_generator mock_data_subclass
	charset template _parse_context _escape_str
);

# ABSTRACT: Exportable functions to assist with declaring mock data
our $VERSION = '0.02'; # VERSION


sub uniform_set {
	return Mock::Data::Set->new(items => [@_]);
}

sub weighted_set {
	my $i= 0;
	return Mock::Data::Set->new_weighted(@_);
}

sub charset {
	return Mock::Data::Charset->new(@_);
}


sub template {
	Mock::Data::Template->new(@_);
}

sub inflate_template {
	my ($tpl)= @_;
	# If it does not contain '{', return as-is.  Else parse.
	return $tpl if index($tpl, '{') == -1;
	local $@;
	my $cmp= eval { Mock::Data::Template->new($tpl) };
	# If the template "compiled" to a simple scalar, return the scalar.  Else return the generator.
	return !$cmp? $tpl : ref $cmp->{_compiled}? $cmp : $cmp->{_compiled};
}


sub coerce_generator {
	my ($spec)= @_;
	!ref $spec?              Mock::Data::Template->new($spec)
	: ref $spec eq 'ARRAY'?  Mock::Data::Set->new(items => [map &_maybe_coerce_set_item, @$spec])
	: ref $spec eq 'HASH'?   weighted_set(%$spec)
	: ref $spec eq 'CODE'?   Mock::Data::GeneratorSub->new($spec)
	: ref($spec)->can('generate')? $spec
	: ref $spec eq 'Regexp'? Mock::Data::Regex->new($spec)
	: Carp::croak("Don't know how to make '$spec' into a generator");
}
sub _maybe_coerce_set_item {
	!ref($_)? inflate_template($_)
	: ref($_) eq 'ARRAY'? Mock::Data::Set->new(items => [map &_maybe_coerce_set_item, @$_])
	: coerce_generator($_);
}


sub mock_data_subclass {
	my $self= shift;
	my $class= ref $self || $self;
	my @to_add= grep !$class->isa($_), @_;
	# Nothing to do if already part of this class/object
	return $self unless @to_add;
	# Determine what the new @ISA will be
	my @new_isa= defined $Mock::Data::auto_subclasses{$class}
		? @{$Mock::Data::auto_subclasses{$class}}
		: ($class);
	# Remove redundant classes
	for my $next_class (@to_add) {
		next if grep $_->isa($next_class), @new_isa;
		@new_isa= grep !$next_class->isa($_), @new_isa;
		push @new_isa, $next_class;
	}
	# If only one class remains, then this one class already defined an inheritance for all
	# the others.  Use it directly.
	my $new_class;
	if (@new_isa == 1) {
		$new_class= $new_isa[0];
	} else {
		# Now find if this combination was already composed, else create it.
		$new_class= _name_for_combined_isa(@new_isa);
		if (!$Mock::Data::auto_subclasses{$new_class}) {
			no strict 'refs';
			@{"${new_class}::ISA"}= @new_isa;
			$Mock::Data::auto_subclasses{$new_class}= \@new_isa;
		}
	}
	return ref $self? bless($self, $new_class) : $new_class;
}

# When choosing a name for a new @ISA list, the name could be something as simple as ::AUTO$n
# with an incrementing number, but that wouldn't be helpful in a stack dump.  But, a package
# name fully containing the ISA package names could get really long and also be unhelpful.
# Compromise by shortening the names by removing Mock::Data prefix and removing '::' and '_'.
# If this results in a name collision (seems unlikely), add an incrementing number on the end.
sub _name_for_combined_isa {
	my @parts= grep { $_ ne 'Mock::Data' } @_;
	my $isa_key= join "\0", @parts;
	for (@parts) {
		$_ =~ s/^Mock::Data:://;
		$_ =~ s/::|_//g;
	}
	my $class= join '_', 'Mock::Data::_AUTO', @parts;
	my $iter= 0;
	my $suffix= '';
	# While iterating, check to see if that package uses the same ISA list as this new request.
	while (defined $Mock::Data::auto_subclasses{$class . $suffix}
		&& $isa_key ne join("\0",
			grep { $_ ne 'Mock::Data' } @{$Mock::Data::auto_subclasses{$class . $suffix}}
		)
	) {
		$suffix= '_' . ++$iter;
	}
	$class . $suffix;
}

my %_escape_common= ( "\n" => '\n', "\t" => '\t', "\0" => '\0' );
sub _escape_str {
	my $str= shift;
	$str =~ s/([^\x20-\x7E])/ $_escape_common{$1} || sprintf("\\x{%02X}",ord $1) /ge;
	return $str;
}
sub _parse_context {
	return '"' . _escape_str(substr($_, defined $_[0]? $_[0] : pos, 10)) .'"';
}

# included last, because they depend on this module.
require Mock::Data::Set;
require Mock::Data::Charset;
require Mock::Data::Regex;
require Mock::Data::Template;
require Mock::Data::GeneratorSub;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mock::Data::Util - Exportable functions to assist with declaring mock data

=head1 SYNOPSIS

  use Mock::Data qw/
    uniform_set
    weighted_set
    inflate_template
    coerce_generator
    mock_data_subclass
  /;

=head1 DESCRIPTION

This module contains utility functions for L<Mock::Data>.  These functions can be imported
from this utility module, or (more conveniently) from L<Mock::Data> itself.

=head1 EXPORTS

Nothing is exported by default.  The following functions are available:

=head2 uniform_set

  $generator= uniform_set( @items )

Shortcut to create a L<Mock::Data::Set> with uniform probability.

=head2 weighted_set

  $generator= weighted_set( $item => $weight, ... )

Shortcut to L<Mock::Data::Set/new_weighted>

=head2 charset

  $generator= charset('A-Z');

Shortcut for L<Mock::Data::Charset/new>, which takes a perl-regex-notation
character set string, or list of attributes.

=head2 template

  $generator= template($template_string);

Shortcut for calling L<Mock::Data::Template/new>.

=head2 inflate_template

  my $str_or_generator= inflate_template( $string );

This function takes a string and checks it for template substitutions, returning a
L<Template|Mock::Data::Template> generator if it is a valid template, and returning the
string otherwise.  It may also return a string if the template substitutions were just escape
sequences for literal strings.  Don't call C<inflate_template> again on the output, because the
escape sequences such as C<< "{#7B}" >> will have been replaced by a literal C<< "{" >>.

=head2 coerce_generator

  my $generator= coerce_generator($spec);

Returns a L<Mock::Data::Generator> wrapping the argument.  The following types are handled:

=over

=item Scalar without "{"

Returns a Generator that always returns the constant scalar.

=item Scalar with "{"

Returns a L<Mock::Data::Template> that performs template substitution on the string.

=item ARRAY ref

Returns a L</uniform_set>.

=item HASH ref

Returns a L</weighted_set>.

=item CODE ref

Returns the coderef, blessed as a generator.

=item Regexp ref

Returns a L<Mock::Data::Regex> generator.

=item C<< $obj->can('compile' >>

Any object which has a C<compile> method is returned as-is.

=back

=head2 mock_data_subclass

  my $subclass= mock_data_subclass($class, @package_names);
  my $reblessed= mock_data_subclass($object, @package_names);

This method can be called on a class or instance to create a new package which inherits
from the original and all packages in the list.  If called on an instance, it also
re-blesses the instance to the new class.  All redundant items are removed from the
combined list. (such as where one of the classes already inherits from one of the others).

This does I<not> check if C<$package_name> is loaded.  That is the caller's responsibility.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.02

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
