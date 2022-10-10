package Tags::HTML::Pager;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use Readonly;
use Unicode::UTF8 qw(decode_utf8);

Readonly::Scalar our $NUMBER_OF_BOXES => 7;

our $VERSION = 0.04;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['css_colors', 'css_pager', 'flag_prev_next', 'flag_paginator',
		'url_page_cb'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# CSS colors.
	$self->{'css_colors'} = {
		'actual_background' => 'black',
		'actual_color' => 'white',
		'border' => 'black',
		'hover_background' => 'black',
		'hover_color' => 'white',
		'other_background' => undef,
		'other_color' => 'black',
	},

	# CSS class.
	$self->{'css_pager'} = 'pager';

	# Flag for prev/next buttons.
	$self->{'flag_prev_next'} = 0;

	# Flag for paginator.
	$self->{'flag_paginator'} = 1;

	# URL of page.
	$self->{'url_page_cb'} = undef;

	# Process params.
	set_params($self, @{$object_params_ar});

	if (! defined $self->{'css_pager'}) {
		err "Parameter 'css_pager' is required.";
	}

	if (! defined $self->{'url_page_cb'}) {
		err "Missing 'url_page_cb' parameter.";
	}

	if (! $self->{'flag_paginator'} && ! $self->{'flag_prev_next'}) {
		err 'Both paginator styles disabled.';
	}

	# Object.
	return $self;
}

sub _process {
	my ($self, $pages_hr) = @_;

	if (! $pages_hr) {
		err 'Pages data structure is missing.';
	}
	if (! exists $pages_hr->{'pages_num'}) {
		err "Missing 'pages_num' parameter in pages data structure.";
	}
	if (! exists $pages_hr->{'actual_page'}) {
		err "Missing 'actual_page' parameter in pages data structure.";
	}
	if ($pages_hr->{'actual_page'} > $pages_hr->{'pages_num'}) {
		err "Parameter 'actual_page' is greater than parameter 'pages_num'.",
			'actual_page', $pages_hr->{'actual_page'},
			'pages_num', $pages_hr->{'pages_num'},
			;
	}

	# No code.
	if (! $self->{'flag_paginator'}
		&& $self->{'flag_prev_next'} && $pages_hr->{'pages_num'} == 1) {

		return;
	}

	$self->{'tags'}->put(
		['b', 'div'],
		['a', 'class', $self->{'css_pager'}],
	);

	# Paginator
	if ($self->{'flag_paginator'}) {
		$self->{'tags'}->put(
			['b', 'p'],
			['a', 'class', $self->_css_class('paginator')],
		);
		my $buttons_from = 1;
		my $buttons_to = $pages_hr->{'pages_num'};
		if ($pages_hr->{'actual_page'} > 4
			&& $pages_hr->{'pages_num'} > $NUMBER_OF_BOXES) {

			$self->{'tags'}->put(
				['b', 'a'],
				['a', 'href', $self->{'url_page_cb'}->(1)],
				['d', 1],
				['e', 'a'],

				['b', 'span'],
				['d', decode_utf8('…')],
				['e', 'span'],
			);
			if ($pages_hr->{'actual_page'} < $pages_hr->{'pages_num'} - 3) {
				$buttons_from = $pages_hr->{'actual_page'} - 1;
			} else {
				$buttons_from = $pages_hr->{'pages_num'} - 4;
			}
		}
		if ($pages_hr->{'actual_page'} < $pages_hr->{'pages_num'} - 3
			&& $pages_hr->{'pages_num'} > $NUMBER_OF_BOXES) {

			if ($pages_hr->{'actual_page'} > 4) {
				$buttons_to = $pages_hr->{'actual_page'} + 1;
			} else {
				$buttons_to = 5;
			}
		}
		foreach my $button_num ($buttons_from .. $buttons_to) {
			if ($pages_hr->{'actual_page'} eq $button_num) {
				$self->{'tags'}->put(
					['b', 'strong'],
					['a', 'class', $self->_css_class('paginator-selected')],
					['d', $button_num],
					['e', 'strong'],
				);
			} else {
				$self->{'tags'}->put(
					['b', 'a'],
					['a', 'href', $self->{'url_page_cb'}->($button_num)],
					['d', $button_num],
					['e', 'a'],
				);
			}
		}
		if ($pages_hr->{'actual_page'} < $pages_hr->{'pages_num'} - 3
			&& $pages_hr->{'pages_num'} > $NUMBER_OF_BOXES) {

			$self->{'tags'}->put(
				['b', 'span'],
				['d', decode_utf8('…')],
				['e', 'span'],

				['b', 'a'],
				['a', 'href', $self->{'url_page_cb'}->($pages_hr->{'pages_num'})],
				['d', $pages_hr->{'pages_num'}],
				['e', 'a'],
			);
		}
		$self->{'tags'}->put(
			['e', 'p'],
		);
	}

	# Paging.
	if ($self->{'flag_prev_next'} && $pages_hr->{'pages_num'} > 1) {
		my ($prev, $next);
		if ($pages_hr->{'pages_num'} > 1) {
			if ($pages_hr->{'actual_page'} > 1) {
				$prev = $pages_hr->{'actual_page'} - 1;
			}
			if ($pages_hr->{'actual_page'} < $pages_hr->{'pages_num'}) {
				$next = $pages_hr->{'actual_page'} + 1;
			}
		}
		
		$self->{'tags'}->put(
			['b', 'p'],
			['a', 'class', $self->_css_class('prev_next')],

			# Previous page.
			$prev ? (
				['b', 'a'],
				['a', 'class', $self->_css_class('prev')],
				['a', 'href', $self->{'url_page_cb'}->($prev)],
				['d', decode_utf8('←')],
				['e', 'a'],
			) : (
				['b', 'span'],
				['a', 'class', $self->_css_class('prev-disabled')],
				['d', decode_utf8('←')],
				['e', 'span'],
			),

			# Next page.
			$next ? (
				['b', 'a'],
				['a', 'class', $self->_css_class('next')],
				['a', 'href', $self->{'url_page_cb'}->($next)],
				['d', decode_utf8('→')],
				['e', 'a'],
			) : (
				['b', 'span'],
				['a', 'class', $self->_css_class('next-disabled')],
				['d', decode_utf8('→')],
				['e', 'span'],
			),

			['e', 'p'],
		);
	}

	$self->{'tags'}->put(
		['e', 'div'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	$self->{'css'}->put(
		['s', '.'.$self->{'css_pager'}.' a'],
		['d', 'text-decoration', 'none'],
		['e'],

		['s', '.'.$self->_css_class('paginator')],
		['d', 'display', 'flex'],
		['d', 'flex-wrap', 'wrap'],
		['d', 'justify-content', 'center'],
		['d', 'padding-left', '130px'],
		['d', 'padding-right', '130px'],
		['d', 'float', 'both'],
		['e'],

		['s', '.'.$self->_css_class('prev_next')],
		['d', 'display', 'flex'],
		['e'],

		['s', '.'.$self->_css_class('paginator').' a'],
		['s', '.'.$self->_css_class('paginator').' strong'],
		['s', '.'.$self->_css_class('paginator').' span'],
		['s', '.'.$self->_css_class('next')],
		['s', '.'.$self->_css_class('next-disabled')],
		['s', '.'.$self->_css_class('prev')],
		['s', '.'.$self->_css_class('prev-disabled')],
		['d', 'display', 'flex'],
		['d', 'height', '55px'],
		['d', 'width', '55px'],
		['d', 'justify-content', 'center'],
		['d', 'align-items', 'center'],
		['d', 'border', '1px solid '.$self->{'css_colors'}->{'border'}],
		['d', 'margin-left', '-1px'],
		['e'],


		['s', '.'.$self->_css_class('prev')],
		['s', '.'.$self->_css_class('next')],
		['d', 'display', 'inline-flex'],
		['d', 'align-items', 'center'],
		['d', 'justify-content', 'center'],
		['e'],

		['s', '.'.$self->_css_class('paginator').' a:hover'],
		['s', '.'.$self->_css_class('prev_next').' a:hover'],
		$self->_css_colors_optional('hover_color', 'color'),
		$self->_css_colors_optional('hover_background', 'background-color'),
		['e'],

		['s', '.'.$self->_css_class('paginator').' a'],
		$self->_css_colors_optional('other_color', 'color'),
		$self->_css_colors_optional('other_background', 'background-color'),
		['e'],

		['s', '.'.$self->_css_class('paginator-selected')],
		['d', 'background-color', $self->{'css_colors'}->{'actual_background'}],
		['d', 'color', $self->{'css_colors'}->{'actual_color'}],
		['e'],
	);

	return;
}

sub _css_class {
	my ($self, $suffix) = @_;

	return $self->{'css_pager'}.'-'.$suffix;
}

sub _css_colors_optional {
	my ($self, $css_color, $css_key) = @_;

	return defined $self->{'css_colors'}->{$css_color}
		? (['d', $css_key, $self->{'css_colors'}->{$css_color}])
		: ();
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Pager - Tags helper for pager.

=head1 SYNOPSIS

 use Tags::HTML::Pager;

 my $obj = Tags::HTML::Pager->new(%params);
 $obj->process($pager_hr);
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Pager->new(%params);

Constructor.

=over 8

=item * C<css>

'CSS::Struct::Output' object for L<process_css> processing.

Default value is undef.

=item * C<css_colors>

Colors for CSS style.

Default value is:
 {
         'actual_background' => 'black',
         'actual_color' => 'white',
         'border' => 'black',
         'hover_background' => 'black',
         'hover_color' => 'white',
         'other_background' => undef,
         'other_color' => 'black',
 }

=item * C<css_pager>

Main CSS class of this block.

It's required.

Default value is 'pager'.

=item * C<flag_prev_next>

Flag, which mean print of prev_next buttons.

Default value is 0.

=item * C<flag_paginator>

Flag, which mean print of paginator buttons.

Default value is 1.

=item * C<url_page_cb>

Callback for creating of url for view page.

Input argument is page variable with number of page.

It's required parameter.

=item * C<tags>

'Tags::Output' object.

Default value is undef.

=back

=head2 C<process>

 $obj->process($pager_hr);

Process Tags structure for output with pager.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process CSS::Struct structure for output.

Returns undef.

=head1 ERRORS

 new():
         Both paginator styles disabled.
         Missing 'url_page_cb' parameter.
         Parameter 'css_pager' is required.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Tags::HTML::new():
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 process():
         Missing 'pages_num' parameter in pages data structure.
         Missing 'actual_page' parameter in pages data structure.
         Pages data structure is missing.
         Parameter 'actual_page' is greater than parameter 'pages_num'.
                 actual_page: %s
                 pages_num: %s
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.

=head1 EXAMPLE

=for comment filename=print_pager_html_and_css.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::Pager;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::Pager->new(
         'css' => $css,
         'tags' => $tags,
         'url_page_cb' => sub {
                 my $page = shift;
                 return 'https://example.com/?page='.$page;
         }
 );

 # Process pager.
 $obj->process({
         'actual_page' => 1,
         'pages_num' => 1,
 });
 $obj->process_css;

 # Print out.
 print $tags->flush;
 print "\n\n";
 print $css->flush;

 # Output:
 # <div class="pager">
 #   <p class="pager-paginator">
 #     <strong class="pager-paginator-selected">
 #      1
 #     </strong>
 #   </p>
 # </div>
 #
 # .pager a {
 #         text-decoration: none;
 # }
 # .pager-paginator {
 #         display: flex;
 #         flex-wrap: wrap;
 #         justify-content: center;
 #         padding-left: 130px;
 #         padding-right: 130px;
 #         float: both;
 # }
 # .pager-prev_next {
 #         display: flex;
 # }
 # .pager-paginator a, .pager-paginator strong, .pager-paginator span, .pager-next,
 # .pager-next-disabled, .pager-prev, .pager-prev-disabled {
 #         display: flex;
 #         height: 55px;
 #         width: 55px;
 #         justify-content: center;
 #         align-items: center;
 #         border: 1px solid black;
 #         margin-left: -1px;
 # }
 # .pager-prev, .pager-next {
 #         display: inline-flex;
 #         align-items: center;
 #         justify-content: center;
 # }
 # .pager-paginator a:hover, .pager-prev_next a:hover {
 #         color: white;
 #         background-color: black;
 # }
 # .pager-paginator a {
 #         color: black;
 # }
 # .pager-paginator-selected {
 #         background-color: black;
 #         color: white;
 # }

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Readonly>,
L<Tags::HTML>,
L<Unicode::UTF8>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Pager>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
