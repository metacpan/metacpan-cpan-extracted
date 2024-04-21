package Tags::HTML;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Scalar::Util qw(blessed);

our $VERSION = 0.10;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# 'CSS::Struct::Output' object.
	$self->{'css'} = undef;

	# No CSS support.
	$self->{'no_css'} = 0;

	# 'Tags::Output' object.
	$self->{'tags'} = undef;

	# Process params.
	set_params($self, @params);

	# Check to 'CSS::Struct::Output' object.
	if (! $self->{'no_css'} && defined $self->{'css'}
		&& (! blessed($self->{'css'}) || ! $self->{'css'}->isa('CSS::Struct::Output'))) {

		err "Parameter 'css' must be a 'CSS::Struct::Output::*' class.";
	}

	# Check to 'Tags' object.
	if (defined $self->{'tags'}
		&& (! blessed($self->{'tags'}) || ! $self->{'tags'}->isa('Tags::Output'))) {

		err "Parameter 'tags' must be a 'Tags::Output::*' class.";
	}

	$self->{'css_src'} = [];
	$self->{'script_js'} = [];
	$self->{'script_js_src'} = [];

	# Object.
	return $self;
}

# Cleanup after dynamic part.
sub cleanup {
	my ($self, @params) = @_;

	$self->_cleanup(@params);

	$self->{'css_src'} = [];
	$self->{'script_js'} = [];
	$self->{'script_js_src'} = [];

	return;
}

# CSS link handling.
sub css_src {
	my ($self, $css_link_ar) = @_;

	if (defined $css_link_ar) {
		$self->{'css_src'} = $css_link_ar;
	}

	return $self->{'css_src'};
}

# Initialize in dynamic part.
sub init {
	my ($self, @params) = @_;

	$self->_init(@params);

	return;
}

# Initialize in preparation phase.
sub prepare {
	my ($self, @params) = @_;

	$self->_prepare(@params);

	return;
}

# Process 'Tags'.
sub process {
	my ($self, @params) = @_;

	if (! defined $self->{'tags'}) {
		err "Parameter 'tags' isn't defined.";
	}

	$self->_process(@params);

	return;
}

# Process 'CSS::Struct'.
sub process_css {
	my ($self, @params) = @_;

	# No CSS support.
	if ($self->{'no_css'}) {
		return;
	}

	if (! defined $self->{'css'}) {
		err "Parameter 'css' isn't defined.";
	}

	$self->_process_css(@params);

	return;
}

# Javascript handling.
sub script_js {
	my ($self, $js_code_ar) = @_;

	if (defined $js_code_ar) {
		$self->{'script_js'} = $js_code_ar;
	}

	return $self->{'script_js'};
}

# Javascript script handling.
sub script_js_src {
	my ($self, $js_link_ar) = @_;

	if (defined $js_link_ar) {
		$self->{'script_js_src'} = $js_link_ar;
	}

	return $self->{'script_js_src'};
}

sub _cleanup {
	my ($self, @params) = @_;

	# Default is no special code.

	return;
}

sub _init {
	my ($self, @params) = @_;

	# Default is no special code.

	return;
}

sub _prepare {
	my ($self, @params) = @_;

	# Default is no special code.

	return;
}

sub _process {
	my ($self, @params) = @_;

	err "Need to be implemented in inherited class in _process() method.";

	return;
}

sub _process_css {
	my ($self, @params) = @_;

	err "Need to be implemented in inherited class in _process_css() method.";

	return;
}

sub _process_js {
	my ($self, @params) = @_;

	err "Need to be implemented in inherited class in _process_js() method.";

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML - Tags helper abstract class.

=head1 SYNOPSIS

 use Tags::HTML;

 my $obj = Tags::HTML->new(%params);
 $obj->cleanup(@params);
 my $css_src_ar = $obj->css_src($css_link_ar);
 $obj->init(@params);
 my $script_js_ar = $obj->script_js($js_code_ar);
 my $script_js_src_ar = $obj->script_js_src($js_link_ar);
 $obj->prepare(@params);
 $obj->process;
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML->new(%params);

Constructor.

Returns instance of class.

=over 8

=item * C<css>

'L<CSS::Struct::Output>' object for L</process_css> processing.

Default value is undef.

=item * C<no_css>

No CSS support flag.
If this flag is set to 1, L</process_css> don't process CSS style.

Default value is 0.

=item * C<tags>

'L<Tags::Output>' object for L</process> processing.

Default value is undef.

=back

=head2 C<cleanup>

 $obj->cleanup(@params);

Process cleanup after page run.

Returns undef.

=head2 C<css_src>

 my $css_src_ar = $obj->css_src($css_link_ar);

Add CSS link to object.

C<$css_link_ar> is reference to array of hashes with CSS information.
CSS information is reference to hash with 'media' and 'link' keys.

Returns actual reference to array with CSS link info.

=head2 C<init>

 $obj->init(@params);

Process initialization in page run.
It's useful in e.g. L<Plack::App::Tags::HTML>.

Returns undef.

=head2 C<script_js>

 my $script_js_ar = $obj->script_js($js_code_ar);

Set/Get Javascript code array to object.

Returns reference to array with strings.

=head2 C<script_js_src>

 my $script_js_src_ar = $obj->script_js_src($js_link_ar);

Set/Get Javascript script link array to object.

Returns reference to array with strings.

=head2 C<prepare>

 $obj->prepare(@params);

Process initialization before page run.
It's useful in e.g. L<Plack::App::Tags::HTML>.

Returns undef.

=head2 C<process>

 $obj->process;

Process L<Tags> structure.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process L<CSS::Struct> structure.

Returns undef.

=head2 C<process_js>

 $obj->process_js;

Process structure.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         Parameter 'css' must be a 'CSS::Struct::Output::*' class.
         Parameter 'tags' must be a 'Tags::Output::*' class.

 process():
         Need to be implemented in inherited class in _process() method.
         Parameter 'tags' isn't defined.

 process_css():
         Need to be implemented in inherited class in _process_css() method.
         Parameter 'css' isn't defined.

=head1 EXAMPLE1

=for comment filename=trivial_html_example.pl

 use strict;
 use warnings;

 package Foo;

 use base qw(Tags::HTML);

 sub new {
         my ($class, @params) = @_;
 
         # No CSS support.
         push @params, 'no_css', 1;
 
         my $self = $class->SUPER::new(@params);
 
         # Object.
         return $self;
 }

 sub _cleanup {
         my $self = shift;

         delete $self->{'_dynamic_data'};
         delete $self->{'_static_data'};

         return;
 }

 sub _init {
         my ($self, @variables) = @_;

         $self->{'_dynamic_data'} = \@variables;

         return;
 }

 sub _prepare {
         my ($self, @variables) = @_;

         $self->{'_static_data'} = \@variables;

         return;
 }

 sub _process {
         my $self = shift;

         $self->{'tags'}->put(
                 ['b', 'div'],
         );
         foreach my $variable (@{$self->{'_static_data'}}) {
                 $self->{'tags'}->put(
                         ['b', 'div'],
                         ['a', 'class', 'static'],
                         ['d', $variable],
                         ['e', 'div'],
                 );
         }
         foreach my $variable (@{$self->{'_dynamic_data'}}) {
                 $self->{'tags'}->put(
                         ['b', 'div'],
                         ['a', 'class', 'dynamic'],
                         ['d', $variable],
                         ['e', 'div'],
                 );
         }
         $self->{'tags'}->put(
                 ['e', 'div'],
         );

         return;
 }

 package main;

 use Tags::Output::Indent;

 # Object.
 my $tags = Tags::Output::Indent->new;
 my $obj = Foo->new(
         'tags' => $tags,
 );

 # Init static data.
 $obj->prepare('foo', 'bar');

 # Init dynamic data.
 $obj->init('baz', 'bax');

 # Process.
 $obj->process;

 # Print out.
 print "HTML\n";
 print $tags->flush."\n";

 # Output:
 # HTML
 # <div>
 #   <div class="static">
 #     foo
 #   </div>
 #   <div class="static">
 #     bar
 #   </div>
 #   <div class="dynamic">
 #     baz
 #   </div>
 #   <div class="dynamic">
 #     bax
 #   </div>
 # </div>

=head1 EXAMPLE2

=for comment filename=trivial_html_css_example.pl

 use strict;
 use warnings;

 package Foo;

 use base qw(Tags::HTML);

 sub _process {
         my ($self, $value) = @_;

         $self->{'tags'}->put(
                 ['b', 'div'],
                 ['d', $value],
                 ['e', 'div'],
         );

         return;
 }

 sub _process_css {
         my ($self, $color) = @_;

         $self->{'css'}->put(
                 ['s', 'div'],
                 ['d', 'background-color', $color],
                 ['e'],
         );

         return;
 }

 package main;

 use CSS::Struct::Output::Indent;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Foo->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Process indicator.
 $obj->process_css('red');
 $obj->process('value');

 # Print out.
 print "CSS\n";
 print $css->flush."\n\n";
 print "HTML\n";
 print $tags->flush."\n";

 # Output:
 # CSS
 # div {
 # 	background-color: red;
 # }
 #
 # HTML
 # <div>
 #   value
 # </div>

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Scalar::Util>.

=head1 SEE ALSO

=over

=item L<Plack::App::Tags::HTML>

Plack application for Tags::HTML objects.

=item L<Plack::Component::Tags::HTML>

Plack component for Tags with HTML output.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.10

=cut
