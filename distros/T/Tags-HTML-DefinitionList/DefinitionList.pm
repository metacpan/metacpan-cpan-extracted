package Tags::HTML::DefinitionList;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use Mo::utils::CSS 0.07 qw(check_css_border check_css_class check_css_unit);

our $VERSION = 0.02;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['border', 'color', 'css_class', 'dd_left_padding', 'dt_sep',
		'dt_width'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# Border of dl.
	$self->{'border'} = undef;

	# Definition key color.
	$self->{'color'} = 'black';

	# CSS class.
	$self->{'css_class'} = 'dl';

	# Left padding after term.
	$self->{'dd_left_padding'} = '110px';

	# Definition term separator.
	$self->{'dt_sep'} = ':';

	# Definition term width.
	$self->{'dt_width'} = '100px';

	# Process params.
	set_params($self, @{$object_params_ar});

	check_css_border($self, 'border');

	check_css_class($self, 'css_class');

	check_css_unit($self, 'dd_left_padding');
	check_css_unit($self, 'dt_width');

	# Object.
	return $self;
}

sub _cleanup {
	my $self = shift;

	delete $self->{'_definition_list'};

	return;
}

sub _init {
	my ($self, $definition_list_ar) = @_;

	return $self->_set_dl($definition_list_ar);
}

sub _prepare {
	my ($self, $definition_list_ar) = @_;

	return $self->_set_dl($definition_list_ar);
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	if (! exists $self->{'_definition_list'}) {
		return;
	}

	$self->{'tags'}->put(
		['b', 'dl'],
		['a', 'class', $self->{'css_class'}],
	);
	foreach my $item_ar (@{$self->{'_definition_list'}}) {
		$self->{'tags'}->put(
			['b', 'dt'],
			['d', $item_ar->[0]],
			['e', 'dt'],
			['b', 'dd'],
			['d', $item_ar->[1]],
			['e', 'dd'],
		);
	}
	$self->{'tags'}->put(
		['e', 'dl'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	$self->{'css'}->put(
		['s', '.'.$self->{'css_class'}],
		defined $self->{'border'} ? (
			['d', 'border', $self->{'border'}],
		) : (),
		['d', 'padding', '0.5em'],
		['e'],

		['s', '.'.$self->{'css_class'}.' dt'],
		['d', 'float', 'left'],
		['d', 'clear', 'left'],
		['d', 'width', $self->{'dt_width'}],
		['d', 'text-align', 'right'],
		['d', 'font-weight', 'bold'],
		['d', 'color', $self->{'color'}],
		['e'],

		['s', '.'.$self->{'css_class'}.' dt:after'],
		['d', 'content', '"'.$self->{'dt_sep'}.'"'],
		['e'],

		['s', '.'.$self->{'css_class'}.' dd'],
		['d', 'margin', '0 0 0 '.$self->{'dd_left_padding'}],
		['d', 'padding', '0 0 0.5em 0'],
		['e'],
	);

	return;
}

sub _set_dl {
	my ($self, $definition_list_ar) = @_;

	if (! defined $definition_list_ar) {
		return;
	}
	if (ref $definition_list_ar ne 'ARRAY') {
		err 'Definition list must be a reference to array.';
	}

	$self->{'_definition_list'} = $definition_list_ar;

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::DefinitionList - Tags helper for definition list.

=head1 SYNOPSIS

 use Tags::HTML::DefinitionList;

 my $obj = Tags::HTML::DefinitionList->new(%params);
 $obj->cleanup;
 $obj->init($definition_list_ar);
 $obj->prepare($definition_list_ar);
 $obj->process;
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::DefinitionList->new(%params);

Constructor.

=over 8

=item * C<border>

Border of definition list.

Default value is undef.

=item * C<color>

Definition key color.

Default value is 'black'.

=item * C<css>

'CSS::Struct::Output' object for L<process_css> processing.

Default value is undef.

=item * C<css_class>

CSS class for main box.

Default value is 'dl'.

=item * C<dd_left_padding>

Left padding after term.

Default value is '110px'.

=item * C<dt_sep>

Definition term separator.

Default value is ':'.

=item * C<dt_width>

Definition term width.

Default value is '100px'.

=item * C<tags>

'Tags::Output' object.

Default value is undef.

=back

=head2 C<cleanup>

 $obj->cleanup;

Cleanup L<Tags::HTML> object for definition list.

Returns undef.

=head2 C<init>

 $obj->init($definition_list_ar);

Initialize L<Tags::HTML> object (in page run) for definition list with structure defined in C<$definition_list_ar> variable.
Variable is reference to array with arrays, which contains key and value.

Returns undef.

=head2 C<prepare>

 $obj->prepare($definition_list_ar);

Prepare L<Tags::HTML> object (in page preparation) for definition list with structure defined in C<$definition_list_ar> variable.
Variable is reference to array with arrays, which contains key and value.

Returns undef.

=head2 C<process>

 $obj->process;

Process L<Tags> structure for defintion list.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process L<CSS::Struct> structure for output.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Mo::utils::CSS::check_css_border():
                 Parameter 'border' contain bad unit.
                         Unit: %s
                         Value: %s
                 Parameter 'border' doesn't contain unit name.
                         Value: %s
                 Parameter 'border' doesn't contain unit number.
                         Value: %s
                 Parameter 'border' has bad rgb color (bad hex number).
                         Value: %s
                 Parameter 'border' has bad rgb color (bad length).
                         Value: %s
                 Parameter 'border' has bad color name.
                         Value: %s
                 Parameter 'border' hasn't border style.
                         Value: %s
                 Parameter 'border' must be a array.
                         Value: %s
                         Reference: %s
         From Mo::utils::CSS::check_css_class():
                 Parameter 'css_class' has bad CSS class name.
                         Value: %s
                 Parameter 'css_class' has bad CSS class name (number on begin).
                         Value: %s
         From Mo::utils::CSS::check_css_unit():
                 Parameter 'dd_left_padding' doesn't contain number.
                         Value: %s
                 Parameter 'dd_left_padding' doesn't contain unit.
                         Value: %s
                 Parameter 'dd_left_padding' contain bad unit.
                         Unit: %s
                         Value: %s
                 Parameter 'dt_width' doesn't contain number.
                         Value: %s
                 Parameter 'dt_width' doesn't contain unit.
                         Value: %s
                 Parameter 'dt_width' contain bad unit.
                         Unit: %s
                         Value: %s
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 init():
         Definition list must be a reference to array.

 prepare():
         Definition list must be a reference to array.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.

=head1 EXAMPLE1

=for comment filename=dl_example.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::DefinitionList;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::DefinitionList->new(
         'css' => $css,
         'tags' => $tags,
 );

 $obj->init([
         ['cze' => 'Czech'],
         ['eng' => 'English'],
 ]);

 # Process container with text.
 $obj->process;
 $obj->process_css;

 # Print out.
 print $tags->flush;
 print "\n\n";
 print $css->flush;

 # Output:
 # <dl class="dl">
 #   <dt>
 #     cze
 #   </dt>
 #   <dd>
 #     Czech
 #   </dd>
 #   <dt>
 #     eng
 #   </dt>
 #   <dd>
 #     English
 #   </dd>
 # </dl>
 # 
 # .dl {
 #         padding: 0.5em;
 # }
 # .dl dt {
 #         float: left;
 #         clear: left;
 #         width: 100px;
 #         text-align: right;
 #         font-weight: bold;
 #         color: black;
 # }
 # .dl dt:after {
 #         content: ":";
 # }
 # .dl dd {
 #         margin: 0 0 0 110px;
 #         padding: 0 0 0.5em 0;
 # }

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Mo::utils::CSS>,
L<Tags::HTML>,

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-DefinitionList>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
