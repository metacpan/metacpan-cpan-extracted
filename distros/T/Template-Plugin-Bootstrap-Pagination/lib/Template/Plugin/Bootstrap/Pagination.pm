package Template::Plugin::Bootstrap::Pagination;
{
  $Template::Plugin::Bootstrap::Pagination::VERSION = '0.002000';
}
use parent qw(Template::Plugin);

# ABSTRACT: Produce HTML suitable for the Bootstrap pagination component

use strict;
use warnings;

use Carp;
use MRO::Compat;
use HTML::Entities;
use Scalar::Util qw(blessed);
use Template::Exception;


sub new {
	my ($class, $context, $arg_ref) = @_;

	my $self = $class->next::method($context, $arg_ref);

	if (defined $arg_ref && ref $arg_ref ne 'HASH') {
		$self->_throw('Hash reference required');
	}
	$arg_ref ||= {};
	$self->{default} = {
		prev_text => '&laquo;',
		next_text => '&raquo;',
		centered  => 0,
		right     => 0,
		siblings  => 3,
		offset    => 0,
		factor    => 1,
		version   => 2,
		%{$arg_ref},
	};

	return $self;
}



sub pagination {
	my ($self, $arg_ref) = @_;

	$arg_ref = {
		%{$self->{default}},
		%{$arg_ref || {}},
	};

	my $pager = $arg_ref->{pager};
	unless (blessed $pager && $pager->isa('Data::Page')) {
		$self->_throw("Required 'pager' parameter not passed or not a 'Data::Page' instance");
	}

	my $pagination = '';
	if ($pager->total_entries() > $pager->entries_per_page()) {
		my $current_page = $pager->current_page();
		my $first_page   = $pager->first_page();
		my $last_page    = $pager->last_page();
		my $page = $first_page;
		PAGE: while ($page <= $last_page) {
			if ($current_page == $page) {
				$pagination .= '<li class="active">'
					. '<span>'.$page.'</span>'
				. '</li>';
			}
			else {
				if ($page == $first_page || $page == $last_page
						|| abs($page - $current_page) <= ($arg_ref->{siblings})
							|| $last_page <= (2 * $arg_ref->{siblings} + 1)) {
					$pagination .= '<li>'
						. '<a href="'.$self->_uri_for_page($page, $arg_ref).'">'.$page.'</a>'
					. '</li>';
				}
				elsif ($first_page + 1 == $page || $last_page - 1 == $page) {
					$pagination .= '<li class="disabled">'
						. '<span>&hellip;</span>'
					. '</li>';
				}
				else {
					$page = ($page < $current_page)
						? $current_page - $arg_ref->{siblings}
						: $last_page - 1;
					next PAGE;
				}
			}
			$page++;
		}
	}

	my $version = $arg_ref->{version} || 2;
	if ($version eq '2') {
		return $self->_pagination_2($pagination, $arg_ref);
	} elsif ($version eq '3') {
		return $self->_pagination_3($pagination, $arg_ref);
	} else {
		croak('Bootstrap version ' . $version . ' not (yet) supported');
	}
}

sub _pagination_2 {
	my ($self, $pagination, $arg_ref) = @_;

	my $alignment = $arg_ref->{centered}
		? ' pagination-centered'
		: ($arg_ref->{right} ? ' pagination-right' : '');
	my $size = defined $arg_ref->{size} ? ' pagination-'.$arg_ref->{size} : '';
	my ($prev_uri, $next_uri) = $self->_prev_next_uri($arg_ref);
	return '<div class="pagination'.$alignment.$size.'">'
		. '<ul>'
			. $self->_pager_item($prev_uri, $arg_ref->{prev_text})
			. $pagination
			. $self->_pager_item($next_uri, $arg_ref->{next_text})
		. '</ul>'
	. '</div>';
}

sub _pagination_3 {
	my ($self, $pagination, $arg_ref) = @_;

	my $alignment = $arg_ref->{centered}
		? 'text-center'
		: ($arg_ref->{right} ? 'text-right' : 'text-left');
	my $size = defined $arg_ref->{size} ? ({
		'mini'  => ' pagination-sm',
		'small' => ' pagination-sm',
		'large' => ' pagination-lg',
	}->{$arg_ref->{size}} || '') : '';
	my ($prev_uri, $next_uri) = $self->_prev_next_uri($arg_ref);
	return '<div class="'.$alignment.'">'
		. '<ul class="pagination'.$size.'">'
			. $self->_pager_item($prev_uri, $arg_ref->{prev_text})
			. $pagination
			. $self->_pager_item($next_uri, $arg_ref->{next_text})
		. '</ul>'
	. '</div>';
}



sub pager {
	my ($self, $arg_ref) = @_;

	$arg_ref = {
		%{$self->{default}},
		%{$arg_ref || {}},
	};

	my $pager = $arg_ref->{pager};
	unless (blessed $pager && $pager->isa('Data::Page')) {
		$self->_throw("Required 'pager' parameter not passed or not a 'Data::Page' instance");
	}

	my ($prev_uri, $next_uri) = $self->_prev_next_uri($arg_ref);
	my $prev_page = $self->_pager_item(
		$prev_uri, $arg_ref->{prev_text}, $arg_ref->{align} ? 'previous' : ()
	);
	my $next_page = $self->_pager_item(
		$next_uri, $arg_ref->{next_text}, $arg_ref->{align} ? 'next' : ()
	);

	return '<ul class="pager">'
		. $prev_page
		. $next_page
	. '</ul>';
}


sub _pager_item {
	my ($self, $uri, $text, @item_classes) = @_;

	my $content;
	if (defined $uri) {
		$content = '<a href="'.$uri.'">'.$text.'</a>';
	}
	else {
		push @item_classes, 'disabled';
		$content = '<span>'.$text.'</span>';
	}

	my $item = '<li';
	if (scalar @item_classes) {
		$item .= ' class="'.join(' ', @item_classes).'"';
	}

	return $item.'>'.$content.'</li>';
}


sub _prev_next_uri {
	my ($self, $arg_ref) = @_;

	my $pager = $arg_ref->{pager};
	return map {
		$_ ? $self->_uri_for_page($_, $arg_ref) : undef;
	} ($pager->previous_page(), $pager->next_page());
}


sub _uri_for_page {
	my ($self, $page, $arg_ref) = @_;

	my $uri = $arg_ref->{uri};
	if (! defined $uri || $uri eq '') {
		$self->_throw("Required 'uri' parameter not passed");
	}
	$uri =~ s/__PAGE__/( $page + $arg_ref->{offset} ) * $arg_ref->{factor}/eg;
	return encode_entities($uri);
}


sub _throw {
	my ($self, $error) = @_;
	croak(Template::Exception->new('Bootstrap.Pagination', $error));
}


1;


__END__
=pod

=head1 NAME

Template::Plugin::Bootstrap::Pagination - Produce HTML suitable for the Bootstrap pagination component

=head1 VERSION

version 0.002000

=head1 SYNOPSIS

	use Template;
	use Data::Page;

	my $pagination_template_string = <<"EOTEMPLATE";
	[%- USE Bootstrap.Pagination -%]
	[%- Bootstrap.Pagination.pagination(pager = pager, uri = uri, version = 2) -%]
	EOTEMPLATE

	my $pager_template_string = <<"EOTEMPLATE";
	[%- USE Bootstrap.Pagination -%]
	[%- Bootstrap.Pagination.pager(pager = pager, uri = uri, version = 3) -%]
	EOTEMPLATE

	my $pager = Data::Page->new(42, 10, 2);
	my $uri = 'http://www.example.com/blog/__PAGE__.html';
	my $template = Template->new(STRICT => 1);
	my $output;

	my $pagination_result = $template->process(\$pagination_template_string, {
		pager => $pager,
		uri   => $uri,
	}, \$output) or die $template->error();

	my $pager_result = $template->process(\$pager_template_string, {
		pager => $pager,
		uri   => $uri,
	}, \$output) or die $template->error();

=head1 DESCRIPTION

Template::Plugin::Bootstrap::Pagination is a plugin for
L<Template::Toolkit|Template::Toolkit> which produces HTML compatible to the
Bootstrap framework's pagination component.

=head1 METHODS

=head2 new

Constructor, creates a new instance of the plugin.

=head3 Parameters

This method expects its parameters as one positional parameter and an optional
hash reference. The values passed in the hash reference will be used as default
values, and can be overridden when calling the plugin's methods.

=over

=item context

A reference to the L<Template::Context|Template::Context> which is loading the
plugin. This is the positional parameter.

=item version

Bootstrap version the HTML code should be generated for. Defaults to C<2> for
now, currently supported are the major versions C<2> and C<3> (although I have
not tested many minor releases, so maybe this is not entirely correct).

=item uri

Template for the URI to use in links. Any occurrence of C<__PAGE__> in the URI
will be replaced by the page number it should point to. Please note that the URI
will be entity encoded before adding it to the generated HTML.

=item pager

The L<Data::Page|Data::Page> object the pager should be built with.

=item prev_text

Text to use in the link to the previous page. Defaults to C<&laquo;>.

=item next_text

Text to use in the link to the next page. Defaults to C<&raquo;>.

=item offset

Offset to add to the page number. May be negative, which can be useful if the
application's first page is C<0>, not C<1>. Defaults to C<0>.

=item factor

Factor to multiply the page number with. Can be useful if the application does
not use pages, but offsets from eg. C<0> (in that case, the factor will usually
be the page size). Defaults to C<1>.

=item siblings

Number of links to display to the left and the right of the current page.
Defaults to C<3>. Only used in L<"pagination">.

=item size

Size of the pagination component. Newer versions (starting at around 2.2.0)
support sizing of the pager. Supports C<large>, C<small> and C<mini> (C<mini>
only in Bootstrap before 3.0.0 - will get mapped to C<small> if version is set
to C<3>).

=item centered

If the pager should be centered. Defaults to C<0>, i.e. C<false>. Only used in
L<"pagination">.

=item right

If the pager should be right aligned. Defaults to C<0>, i.e. C<false>. Only used
in L<"pagination">.

=item align

Don't center previous and next links, align them to the sides instead. Defaults
to C<0>, i.e. C<false>, so the links will be centered. Only used in L<"pager">.

=back

=head3 Result

The new instance.

=head2 pagination

Get HTML for a pagination. Includes a previous/next link, links to first and
last page, and links to a range of pages around the current page:

	< | 1 | ... | 8 | 9 | _10_ | 11 | 12 | ... | n | >

=head3 Parameters

This method expects positional parameters. See L<"new"> for the available
parameters, their description and their defaults. C<pager> and C<uri> are
required if they have not been passed to L<"new"> as defaults.

=head3 Result

The HTML code.

=head2 pager

Get HTML for a simple pager with only previous and next links.

=head3 Parameters

This method expects positional parameters. See L<"new"> for the available
parameters, their description and their defaults. C<pager> and C<uri> are
required if they have not been passed to L<"new"> as defaults.

=head3 Result

The HTML code.

=head1 SEE ALSO

=over

=item *

L<http://getbootstrap.com/> - The Bootstrap framework, latest version

=item *

L<http://twitter.github.com/bootstrap/> - The Bootstrap framework, version 2.3.2

=item *

L<Template::Toolkit|Template::Toolkit>

=back

=head1 AUTHOR

Manfred Stock <mstock@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Manfred Stock.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

