package Tags::HTML::InfoBox;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use Mo::utils::CSS 0.02 qw(check_css_class);
use Scalar::Util qw(blessed);
use Tags::HTML::Icon;

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['css_class', 'lang'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# CSS style for info box.
	$self->{'css_class'} = 'info-box';

	$self->{'lang'} = undef;

	# Process params.
	set_params($self, @{$object_params_ar});

	check_css_class($self, 'css_class');

	# Object.
	return $self;
}

sub _cleanup {
	my $self = shift;

	delete $self->{'_infobox'};
	delete $self->{'_tags_icon'};

	return;
}

sub _init {
	my ($self, @params) = @_;

	return $self->_set_infobox(@params);
}

sub _prepare {
	my ($self, @params) = @_;

	return $self->_set_infobox(@params);
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	if (! exists $self->{'_infobox'}) {
		return;
	}

	$self->{'tags'}->put(
		['b', 'table'],
		['a', 'class', $self->{'css_class'}],
	);
	foreach my $item (@{$self->{'_infobox'}->items}) {
		$self->{'tags'}->put(
			['b', 'tr'],
			['b', 'td'],
		);
		if (defined $item->icon) {
			$self->{'_tags_icon'}->init($item->icon);
			$self->{'_tags_icon'}->process;
		}
		$self->{'tags'}->put(
			['e', 'td'],

			['b', 'td'],
			(defined $self->{'lang'} && defined $item->text->lang
				&& $item->text->lang ne $self->{'lang'}) ? (

				['a', 'lang', $self->text->lang],
			) : (),
			defined $item->uri ? (
				['b', 'a'],
				['a', 'href', $item->uri],
			) : (),
			['d', $item->text->text],
			defined $item->uri ? (
				['e', 'a'],
			) : (),
			['e', 'td'],
			['e', 'tr'],
		);
	}
	$self->{'tags'}->put(
		['e', 'table'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	if (! exists $self->{'_infobox'}) {
		return;
	}

	$self->{'css'}->put(
		['s', '.'.$self->{'css_class'}],
		['d', 'background-color', '#32a4a8'],
		['d', 'padding', '1em'],
		['e'],

		['s', '.'.$self->{'css_class'}.' .icon'],
		['d', 'text-align', 'center'],
		['e'],

		['s', '.'.$self->{'css_class'}.' a'],
		['d', 'text-decoration', 'none'],
		['e'],
	);
	$self->{'_tags_icon'}->process_css;

	return;
}

sub _set_infobox {
	my ($self, $infobox) = @_;

	if (! defined $infobox) {
		return;
	}

	if (! blessed($infobox) || ! $infobox->isa('Data::InfoBox')) {
		err "Info box object must be a instance of 'Data::InfoBox'.";
	}
	if (! $infobox->VERSION('0.04')) {
		err "Info box object must have a minimal version >= 0.04.";
	}

	$self->{'_infobox'} = $infobox;

	$self->{'_tags_icon'} = Tags::HTML::Icon->new(
		'css' => $self->{'css'},
		'tags' => $self->{'tags'},
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::InfoBox - Tags helper for HTML info box.

=head1 SYNOPSIS

 use Tags::HTML::InfoBox;

 my $obj = Tags::HTML::InfoBox->new(%params);
 $obj->cleanup;
 $obj->init($infobox);
 $obj->prepare($infobox);
 $obj->process;
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::InfoBox->new(%params);

Constructor.

=over 8

=item * C<css>

L<CSS::Struct::Output> object for L<process_css> processing.

Default value is undef.

=item * C<css_class>

Default value is 'info-box'.

=item * C<lang>

Language in ISO 639-1 code.

Default value is undef.

=item * C<tags>

L<Tags::Output> object.

Default value is undef.

=back

=head2 C<cleanup>

 $obj->cleanup;

Process cleanup after page run.

In this case cleanup internal representation of a set by L<init>.

Returns undef.

=head2 C<init>

 $obj->init($infobox);

Process initialization in page run.

Accepted C<$infobox> is L<Data::InfoBox>.

Returns undef.

=head2 C<prepare>

 $obj->prepare($infobox);

Process initialization before page run.

Accepted C<$infobox> is L<Data::InfoBox>.

Returns undef.

=head2 C<process>

 $obj->process;

Process L<Tags> structure for HTML a element to output.

Do nothing in case without inicialization by L<init>.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process L<CSS::Struct> structure for HTML a element to output.

Do nothing in case without inicialization by L<init>.

Returns undef.

=head1 ERRORS

 new():
         From Mo::utils::CSS::check_css_class():
                 Parameter '%s' has bad CSS class name.
                         Value: %s
                 Parameter '%s' has bad CSS class name (number on begin).
                         Value: %s
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 init():
         Info box object must be a instance of 'Data::InfoBox'.

 prepare():
         Info box object must be a instance of 'Data::InfoBox'.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.

=head1 EXAMPLE

=for comment filename=create_and_print_infobox.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::InfoBox;
 use Tags::Output::Indent;
 use Test::Shared::Fixture::Data::InfoBox::Street;
 use Unicode::UTF8 qw(encode_utf8);

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'xml' => 1,
 );
 my $obj = Tags::HTML::InfoBox->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Data object for info box.
 my $infobox = Test::Shared::Fixture::Data::InfoBox::Street->new;

 # Initialize.
 $obj->init($infobox);

 # Process.
 $obj->process;
 $obj->process_css;

 # Print out.
 print "HTML:\n";
 print encode_utf8($tags->flush);
 print "\n\n";
 print "CSS:\n";
 print $css->flush;

 # Output:
 # HTML:
 # <table class="info-box">
 #   <tr>
 #     <td />
 #     <td>
 #       Nábřeží Rudoarmějců
 #     </td>
 #   </tr>
 #   <tr>
 #     <td />
 #     <td>
 #       Příbor
 #     </td>
 #   </tr>
 #   <tr>
 #     <td />
 #     <td>
 #       Česká republika
 #     </td>
 #   </tr>
 # </table>
 # 
 # CSS:
 # .info-box {
 #         background-color: #32a4a8;
 #         padding: 1em;
 # }
 # .info-box .icon {
 #         text-align: center;
 # }
 # .info-box a {
 #         text-decoration: none;
 # }

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Mo::utils::CSS>,
L<Scalar::Util>,
L<Tags::HTML>,
L<Tags::HTML::Icon>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-InfoBox>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
