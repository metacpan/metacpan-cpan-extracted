package Tags::HTML::Table::View;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use List::MoreUtils qw(none);
use Scalar::Util qw(blessed);
use Tags::HTML::Element::A;

our $VERSION = 0.04;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['css_table', 'header'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# Main CSS class.
	$self->{'css_table'} = 'table';

	# Header is in first line.
	$self->{'header'} = 1;

	# Process params.
	set_params($self, @{$object_params_ar});

	# Object.
	return $self;
}

sub _cleanup {
	my $self = shift;

	delete $self->{'_data'};
	delete $self->{'_no_data'};
	delete $self->{'_tags_html_a'};

	return;
}

sub _init {
	my ($self, $data_ar, $no_data_value) = @_;

	$self->{'_data'} = $data_ar;
	$self->{'_no_data'} = $no_data_value;
	$self->{'_tags_html_a'} = Tags::HTML::Element::A->new(
		'css' => $self->{'css'},
		'tags' => $self->{'tags'},
	);

	return;
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	if (! exists $self->{'_data'}) {
		return;
	}

	# Main content.
	$self->{'tags'}->put(
		['b', 'table'],
		['a', 'class', $self->{'css_table'}],
	);
	my $columns_count = 0;
	if ($self->{'header'}) {
		$self->{'tags'}->put(
			['b', 'tr'],
		);
		my $header_ar = shift @{$self->{'_data'}};
		foreach my $value (@{$header_ar}) {
			$self->{'tags'}->put(
				['b', 'th'],
				['d', $value],
				['e', 'th'],
			);
			$columns_count++;
		}
		$self->{'tags'}->put(
			['e', 'tr'],
		);
	} else {
		$columns_count++;
	}
	foreach my $row_ar (@{$self->{'_data'}}) {
		$self->{'tags'}->put(
			['b', 'tr'],
		);
		foreach my $value (@{$row_ar}) {
			$self->{'tags'}->put(
				['b', 'td'],
			);
			$self->_value($value);
			$self->{'tags'}->put(
				['e', 'td'],
			);
		}
		$self->{'tags'}->put(
			['e', 'tr'],
		);
	}

	# No data row.
	if (! @{$self->{'_data'}} && defined $self->{'_no_data'}) {
		$self->{'tags'}->put(
			['b', 'tr'],
			['b', 'td'],
			['a', 'colspan', $columns_count],
		);
		$self->_value($self->{'_no_data'});
		$self->{'tags'}->put(
			['e', 'td'],
			['e', 'tr'],
		);
	}

	$self->{'tags'}->put(
		['e', 'table'],
	);

	return;
}

# Process 'CSS::Struct'.
sub _process_css {
	my $self = shift;

	$self->{'css'}->put(
		['s', '.'.$self->{'css_table'}],
		['s', '.'.$self->{'css_table'}.' td'],
		['s', '.'.$self->{'css_table'}.' th'],
		['d', 'border', '1px solid #ddd'],
		['d', 'text-align', 'left'],
		['e'],

		['s', '.'.$self->{'css_table'}],
		['d', 'border-collapse', 'collapse'],
		['d', 'width', '100%'],
		['e'],

		['s', '.'.$self->{'css_table'}.' th'],
		['s', '.'.$self->{'css_table'}.' td'],
		['d', 'padding', '15px'],
		['e'],
	);

	return;
}

sub _tags_a {
	my ($self, $value) = @_;

	$self->{'tags'}->put(
		['b', 'a'],
		defined $value->css_class ? (
			['a', 'class', $value->css_class],
		) : (),
		defined $value->url ? (
			['a', 'href', $value->url],
		) : (),
	);
	if ($value->data_type eq 'plain') {
		$self->{'tags'}->put(
			['d', @{$value->data}],
		);
	} elsif ($value->data_type eq 'tags') {
		$self->{'tags'}->put($value->data);
	}
	$self->{'tags'}->put(
		['e', 'a'],
	);

	return;
}

sub _value {
	my ($self, $value) = @_;

	if (ref $value eq '') {
		$self->{'tags'}->put(
			['d', $value],
		);
	} elsif (ref $value eq 'ARRAY') {
		$self->{'tags'}->put(@{$value});
	} elsif (blessed($value) && $value->isa('Data::HTML::Element::A')) {
		$self->{'_tags_html_a'}->init($value);
		$self->{'_tags_html_a'}->process;
	} else {
		err 'Bad value object.';
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Table::View - Tags helper for table view.

=head1 SYNOPSIS

 use Tags::HTML::Table::View;

 my $obj = Tags::HTML::Table::View->new(%params);
 $obj->cleanup;
 $obj->init($data_ar, $no_data_value);
 $obj->process;
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Table::View->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<css>

'L<CSS::Struct::Output>' object for L</process_css> processing.

Default value is undef.

=item * C<css_table>

CSS class for table.

Default value is 'table'.

=item * C<header>

Boolean flag, that means that header is in first line.

Default value is 1.

=item * C<tags>

'L<Tags::Output>' object for L</process> processing.

Default value is undef.

=back

=head2 C<cleanup>

 $obj->cleanup;

Process cleanup after page run.

Returns undef.

=head2 C<init>

 $obj->init($data_ar, $no_data_value);

Process initialization before page run.

Variable C<$data_ar> are data for table. Each item in array could be scalar,
array with scalars or L<Data::HTML::Element::A> instance.

Variable C<$no_data_value> contain information for situation when data in table not
exists.

Returns undef.

=head2 C<process>

 $obj->process;

Process L<Tags> structure for table view.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process L<CSS::Struct> structure for output.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.
         Bad value object.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.

=head1 EXAMPLE1

=for comment filename=print_table_with_data.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::Table::View;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::Table::View->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Table data.
 my $table_data_ar = [
         ['Country', 'Capital'],
         ['Czech Republic', 'Prague'],
         ['Russia', 'Moscow'],
 ];

 # Process login button.
 $obj->init($table_data_ar, 'No data.');
 $obj->process_css;
 $tags->put(['b', 'body']);
 $obj->process;
 $tags->put(['e', 'body']);
 $obj->cleanup;

 # Print out.
 print "CSS\n";
 print $css->flush."\n\n";
 print "HTML\n";
 print $tags->flush."\n";

 # Output:
 # CSS
 # .table, .table td, .table th {
 #         border: 1px solid #ddd;
 #         text-align: left;
 # }
 # .table {
 #         border-collapse: collapse;
 #         width: 100%;
 # }
 # .table th, .table td {
 #         padding: 15px;
 # }
 #
 # HTML
 # <body>
 #   <table class="table">
 #     <tr>
 #       <th>
 #         Country
 #       </th>
 #       <th>
 #         Capital
 #       </th>
 #     </tr>
 #     <tr>
 #       <td>
 #         Czech Republic
 #       </td>
 #       <td>
 #         Prague
 #       </td>
 #     </tr>
 #     <tr>
 #       <td>
 #         Russia
 #       </td>
 #       <td>
 #         Moscow
 #       </td>
 #     </tr>
 #   </table>
 # </body>

=head1 EXAMPLE2

=for comment filename=print_table_without_data.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::Table::View;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::Table::View->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Table data.
 my $table_data_ar = [
         ['Country', 'Capital'],
 ];

 # Process login button.
 $obj->init($table_data_ar, 'No data.');
 $obj->process_css;
 $tags->put(['b', 'body']);
 $obj->process;
 $tags->put(['e', 'body']);
 $obj->cleanup;

 # Print out.
 print "CSS\n";
 print $css->flush."\n\n";
 print "HTML\n";
 print $tags->flush."\n";

 # Output:
 # CSS
 # .table, .table td, .table th {
 #         border: 1px solid #ddd;
 #         text-align: left;
 # }
 # .table {
 #         border-collapse: collapse;
 #         width: 100%;
 # }
 # .table th, .table td {
 #         padding: 15px;
 # }
 #
 # HTML
 # <body>
 #   <table class="table">
 #     <tr>
 #       <th>
 #         Country
 #       </th>
 #       <th>
 #         Capital
 #       </th>
 #     </tr>
 #     <tr>
 #       <td colspan="2">
 #         No data.
 #       </td>
 #     </tr>
 #   </table>
 # </body>

=head1 EXAMPLE3

=for comment filename=print_table_with_data_object.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Data::HTML::Element::A;
 use Tags::HTML::Table::View;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::Table::View->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Table data.
 my $prague = Data::HTML::Element::A->new(
         'data' => ['Prague'],
         'url' => 'https://prague.cz',
 );
 my $table_data_ar = [
         ['Country', 'Capital'],
         ['Czech Republic', $prague],
         ['Russia', 'Moscow'],
 ];

 # Process login button.
 $obj->init($table_data_ar, 'No data.');
 $obj->process_css;
 $tags->put(['b', 'body']);
 $obj->process;
 $tags->put(['e', 'body']);
 $obj->cleanup;

 # Print out.
 print "CSS\n";
 print $css->flush."\n\n";
 print "HTML\n";
 print $tags->flush."\n";

 # Output:
 # CSS
 # .table, .table td, .table th {
 #         border: 1px solid #ddd;
 #         text-align: left;
 # }
 # .table {
 #         border-collapse: collapse;
 #         width: 100%;
 # }
 # .table th, .table td {
 #         padding: 15px;
 # }
 # 
 # HTML
 # <body>
 #   <table class="table">
 #     <tr>
 #       <th>
 #         Country
 #       </th>
 #       <th>
 #         Capital
 #       </th>
 #     </tr>
 #     <tr>
 #       <td>
 #         Czech Republic
 #       </td>
 #       <td>
 #         <a href="https://prague.cz">
 #           Prague
 #         </a>
 #       </td>
 #     </tr>
 #     <tr>
 #       <td>
 #         Russia
 #       </td>
 #       <td>
 #         Moscow
 #       </td>
 #     </tr>
 #   </table>
 # </body>

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<List::MoreUtils>,
L<Scalar::Util>,
L<Tags::HTML>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Table-View>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
