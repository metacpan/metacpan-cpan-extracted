package Tenjin::Context;

use strict;
use warnings;
use Tenjin::Util;
use Carp;

our $VERSION = "1.000001";
$VERSION = eval $VERSION;

=head1 NAME

Tenjin::Context - In charge of managing variables passed to Tenjin templates.

=head1 SYNOPSIS

	# this module is used internally, but if you insist, it is
	# in charge of the context object:

	# in your templates (unnecessary, for illustration purposes):
	<title>[== $_context->{title} =]</title>
	# instead use:
	<title>[== $title =]</title>

=head1 DESCRIPTION

This module is in charge of managing Perl variables that are passed to
templates upon rendering for direct usage. The context object is simply
a hash-ref of key-value pairs, which are made available for templates
as "standalone variables" named for each key in the hash-ref.

This module is also in charge of the actual rendering of the templates,
or more correctly, for evaluating the Perl code created from the templates,
first integrating the context variables to them, and returning the rendered
output.

Finally, this module makes the Tenjin utility methods of L<Tenjin::Util>
available natively inside templates. See L<Tenjin::Util> for more info.

=head1 INTERNAL METHODS

=head2 new( [\%vars] )

Constructs a new context object, which is basically a hash-ref of key-value pairs
which are passed to templates as variables. If a C<$vars> hash-ref is passed
to the constructor, it will be augmented into the created object.

To illustrate the context object, suppose it looks like so:

	{
		scalar		=> 'I am a scalar',
		arrayref	=> [qw/I am an array/],
		hashref	=> 	{ i => 'am', a => 'hash-ref' },
	}

Then the variables C<$scalar>, C<$arrayref> and C<$hashref> will be available for
direct usage inside your templates, and you can dereference the variables
normally (i.e. C<@$arrayref> and C<%$hashref>).

=cut

sub new {
	my ($class, $self) = @_;

	$self ||= {};

	return bless $self, $class;
}

=head2 evaluate( $script, $template_name )

This method receives a compiled template and actually performes the evaluation
the renders it, then returning the rendered output. If Tenjin is configured
to C<use strict>, the script will be C<eval>ed under C<use strict>.

=cut

sub evaluate {
	my ($self, $script, $name) = @_;

	my $_context = $self;
	$script = ($script =~ /\A(.*)\Z/s) && $1 if $Tenjin::BYPASS_TAINT;
	my $s = $name ? "# line 1 \"$name\"\n" : '';  # line directive
	$s .= $script;

	my $ret;
	if ($Tenjin::USE_STRICT) {
		$ret = eval($s);
	} else {
		no strict;
		$ret = eval($s);
		use strict;
	}

	croak "[Tenjin] Failed rendering $name: $@" if $@;
	
	return $ret;
}

=head2 to_func( $script, [$filename] )

This method receives the script created when reading a template and wraps
it in a subroutine, C<eval>s it and returns the rendered output. This method
is called when compiling the template.

=cut

sub to_func {
	my ($self, $script, $name) = @_;

	$script = ($script =~ /\A(.*)\Z/s) && $1 if $Tenjin::BYPASS_TAINT;
	my $s = $name ? "# line 1 \"$name\"\n" : '';  # line directive
	$s .= "sub { my (\$_context) = \@_; $script }";
	
	my $ret;
	if ($Tenjin::USE_STRICT) {
		$ret = eval($s);
	} else {
		no strict;
		$ret = eval($s);
		use strict;
	}

	croak "[Tenjin] Failed compiling $name: $@" if $@;
	
	return $ret;
}

=head2 _build_decl()

This method is in charge of making all the key-value pairs of the context
object available to templates directly by the key names. This is simply done
by traversing the key-value pairs of the context object and adding an
assignment line between a scalar variable named as the key and its appropriate
value.

=cut

sub _build_decl {
	my $self = shift;

	my $s = '';
	foreach my $k (keys %$self) {
		next if $k eq '_context';
		$s .= "my \$$k = \$_context->{'$k'}; ";
	}
	return $s;
}

=head1 UTILITY METHODS

These methods are defined in L<Tenjin::Util> and used here so they are
made available natively inside templates. See L<Tenjin::Util> for more
information.

=head2 _p( $expr )

=head2 _P( $expr )

=head2 escape( $expr )

=head2 escape_xml( $expr )

=head2 unescape_xml( $expr )

=head2 encode_url( $url )

=head2 decode_url( $url )

=head2 checked( $expr )

=head2 selected( $expr )

=head2 disabled( $expr )

=head2 nl2br( $text )

=head2 text2html( $text )

=head2 tagattr( $name, $expr, [$value] )

=head2 tagattrs( %attrs )

=head2 new_cycle( @items )

=cut

# this makes the Tenjin utility methods available to templates 'natively'
*_p = *Tenjin::Util::_p;
*_P = *Tenjin::Util::_P;
*escape = *Tenjin::Util::escape_xml;
*escape_xml = *Tenjin::Util::escape_xml;
*unescape_xml = *Tenjin::Util::unescape_xml;
*encode_url = *Tenjin::Util::encode_url;
*decode_url = *Tenjin::Util::decode_url;
*checked = *Tenjin::Util::checked;
*selected = *Tenjin::Util::selected;
*disabled = *Tenjin::Util::disabled;
*nl2br = *Tenjin::Util::nl2br;
*text2html = *Tenjin::Util::text2html;
*tagattr = *Tenjin::Util::tagattr;
*tagattrs = *Tenjin::Util::tagattrs;
*new_cycle = *Tenjin::Util::new_cycle;

1;

=head1 SEE ALSO

L<Tenjin>, L<Tenjin::Util>, L<Tenjin::Template>.

=head1 AUTHOR, LICENSE AND COPYRIGHT

See L<Tenjin>.

=cut
