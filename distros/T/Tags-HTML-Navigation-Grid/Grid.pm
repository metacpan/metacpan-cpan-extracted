package Tags::HTML::Navigation::Grid;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use Scalar::Util qw(blessed);

our $VERSION = 0.02;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['css_class'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# CSS class.
	$self->{'css_class'} = 'navigation';

	# Process params.
	set_params($self, @{$object_params_ar});

	if (! defined $self->{'css_class'}) {
		err "Parameter 'css_class' is required.";
	}

	# Object.
	return $self;
}

sub _cleanup {
	my $self = shift;

	delete $self->{'_items'};

	return;
}

sub _init {
	my ($self, $items_ar) = @_;

	if (ref $items_ar ne 'ARRAY') {
		err "Bad reference to array with items.";
	}

	foreach my $item (@{$items_ar}) {
		if (! defined $item
			|| ! blessed($item)
			|| ! $item->isa('Data::Navigation::Item')) {

			err "Item object must be a 'Data::Navigation::Item' instance.";
		}
	}

	$self->{'_items'} = $items_ar;

	return;
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	if (! exists $self->{'_items'}) {
		return;
	}

	$self->{'tags'}->put(
		['b', 'nav'],
		['a', 'class', $self->{'css_class'}],
	);
	foreach my $item (@{$self->{'_items'}}) {
		$self->{'tags'}->put(
			['b', 'div'],
			defined $item->class ? (
				['a', 'class', $item->class],
			) : (
				['a', 'class', 'nav-item'],
			),
			defined $item->location ? (
				['b', 'a'],
				['a', 'href', $item->location],
			) : (),
			defined $item->image ? (
				['b', 'img'],
				['a', 'src', $item->image],
				['a', 'alt', $item->title],
				['e', 'img'],
			) : (),
			['b', 'div'],
			['a', 'class', 'title'],
			['d', $item->title],
			['e', 'div'],
			defined $item->location ? (
				['e', 'a'],
			) : (),
			defined $item->desc ? (
				['b', 'p'],
				['d', $item->desc],
				['e', 'p'],
			) : (),
			['e', 'div'],
		);
	}
	$self->{'tags'}->put(
		['e', 'nav'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	if (! exists $self->{'_items'}) {
		return;
	}

	$self->{'css'}->put(
		['s', '.'.$self->{'css_class'}],
		['d', 'display', 'flex'],
		['d', 'flex-wrap', 'wrap'],
		['d', 'gap', '20px'],
		['d', 'padding', '20px'],
		['d', 'justify-content', 'center'],
		['e'],

		['s', '.nav-item'],
		['d', 'display', 'flex'],
		['d', 'flex-direction', 'column'],
		['d', 'align-items', 'center'],
		['d', 'border', '2px solid #007BFF'],
		['d', 'border-radius', '15px'],
		['d', 'padding', '15px'],
		['d', 'width', '200px'],
		['e'],

		['s', '.nav-item img'],
		['d', 'width', '100px'],
		['d', 'height', '100px'],
		['e'],

		['s', '.nav-item div.title'],
		['d', 'margin', '10px 0'],
		['d', 'font-family', 'sans-serif'],
		['d', 'font-weight', 'bold'],
		['e'],

		['s', '.nav-item '],
		['d', 'text-align', 'center'],
		['d', 'font-family', 'sans-serif'],
		['e'],
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Navigation::Grid - Tags helper for navigation grid.

=head1 SYNOPSIS

 use Tags::HTML::Navigation::Grid;

 my $obj = Tags::HTML::Navigation::Grid->new(%params);
 $obj->cleanup;
 $obj->init($items_ar);
 $obj->prepare;
 $obj->process;
 $obj->process_css;

=head1 DESCRIPTION

L<Tags> helper to print HTML page of navigation grid.

The page contains multiple boxes with title and optional image and description in box.
Each box could have link to other page.

Items are defined by L<Data::Navigation::Item> instances.

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Navigation::Grid->new(%params);

Constructor.

=over 8

=item * C<css>

L<CSS::Struct::Output> object for L<process_css> processing.

Default value is undef.

=item * C<css_class>

CSS class for navigation grid.

Default value is 'navigation'.

=item * C<tags>

L<Tags::Output> object.

Default value is undef.

=back

Returns instance of object.

=head2 C<cleanup>

 $obj->cleanup;

Process cleanup after page run.

Returns undef.

=head2 C<init>

 $obj->init($items_ar);

Initialize object.
Variable C<$items_ar> is reference to array with L<Data::Navigation::Item>
instances.

Returns undef.

=head2 C<prepare>

 $obj->prepare;

Prepare object.
Do nothing in this object.

Returns undef.

=head2 C<process>

 $obj->process;

Process L<Tags> structure for navigation grid.

Returns undef.

=head2 C<process_css>

 $obj->process_css;

Process L<CSS::Struct> structure for navigation grid.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 init():
         Bad reference to array with items.
         Item object must be a 'Data::Navigation::Item' instance.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.

=head1 EXAMPLE1

=for comment filename=print_grid_html_and_css.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Data::Navigation::Item;
 use Tags::HTML::Navigation::Grid;
 use Tags::Output::Indent;

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new;
 my $obj = Tags::HTML::Navigation::Grid->new(
         'css' => $css,
         'tags' => $tags,
 );

 my @items = (
         Data::Navigation::Item->new(
                 'class' => 'nav-item1',
                 'desc' => 'This is description #1',
                 'id' => 1,
                 'image' => '/img/foo.png',
                 'location' => '/first',
                 'title' => 'First',
         ),
         Data::Navigation::Item->new(
                 'class' => 'nav-item2',
                 'desc' => 'This is description #2',
                 'id' => 2,
                 'image' => '/img/bar.png',
                 'location' => '/second',
                 'title' => 'Second',
         ),
 );
 $obj->init(\@items);

 # Process login b.
 $obj->process_css;
 $obj->process;

 # Print out.
 print "CSS\n";
 print $css->flush."\n\n";
 print "HTML\n";
 print $tags->flush."\n";

 # Output:
 # CSS
 # .navigation {
 #         display: flex;
 #         flex-wrap: wrap;
 #         gap: 20px;
 #         padding: 20px;
 #         justify-content: center;
 # }
 # .nav-item {
 #         display: flex;
 #         flex-direction: column;
 #         align-items: center;
 #         border: 2px solid #007BFF;
 #         border-radius: 15px;
 #         padding: 15px;
 #         width: 200px;
 # }
 # .nav-item img {
 #         width: 100px;
 #         height: 100px;
 # }
 # .nav-item div.title {
 #         margin: 10px 0;
 #         font-family: sans-serif;
 #         font-weight: bold;
 # }
 # .nav-item  {
 #         text-align: center;
 #         font-family: sans-serif;
 # }
 # 
 # HTML
 # <nav class="navigation">
 #   <div class="nav-item1">
 #     <a href="/first">
 #       <img src="/img/foo.png" alt="First">
 #       </img>
 #       <div class="title">
 #         First
 #       </div>
 #     </a>
 #     <p>
 #       This is description #1
 #     </p>
 #   </div>
 #   <div class="nav-item2">
 #     <a href="/second">
 #       <img src="/img/bar.png" alt="Second">
 #       </img>
 #       <div class="title">
 #         Second
 #       </div>
 #     </a>
 #     <p>
 #       This is description #2
 #     </p>
 #   </div>
 # </nav>

=head1 EXAMPLE2

=for comment filename=plack_app_nav_grid.pl

 use strict;
 use warnings;
 
 use CSS::Struct::Output::Indent;
 use Data::Navigation::Item;
 use Plack::App::Tags::HTML;
 use Plack::Builder;
 use Plack::Runner;
 use Tags::Output::Indent;

 # Plack application with foo SVG file.
 my $svg_foo = <<'END';
 <?xml version="1.0" ?>
 <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="-1 -1 2 2">
   <polygon points="0,-0.5 0.433,0.25 -0.433,0.25" fill="#FF6347"/>
   <polygon points="0,-0.5 0.433,0.25 0,0.75" fill="#4682B4"/>
   <polygon points="0.433,0.25 -0.433,0.25 0,0.75" fill="#32CD32"/>
   <polygon points="0,-0.5 -0.433,0.25 0,0.75" fill="#FFD700"/>
 </svg>
 END
 my $app_foo = sub {
         return [
                 200,
                 ['Content-Type' => 'image/svg+xml'],
                 [$svg_foo],
         ];
 };

 # Plack application with bar SVG file.
 my $svg_bar = <<'END';
 <?xml version="1.0" ?>
 <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
   <polygon points="100,30 50,150 150,150" fill="#4682B4"/>
   <polygon points="100,30 150,150 130,170" fill="#4682B4" opacity="0.9"/>
   <polygon points="100,30 50,150 70,170" fill="#4682B4" opacity="0.9"/>
   <polygon points="70,170 130,170 100,150" fill="#4682B4" opacity="0.8"/>
 </svg>
 END
 my $app_bar = sub {
         return [
                 200,
                 ['Content-Type' => 'image/svg+xml'],
                 [$svg_bar],
         ];
 };

 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'xml' => 1,
         'preserved' => ['style'],
 );

 # Navigation items.
 my @items = (
         Data::Navigation::Item->new(
                 'class' => 'nav-item',
                 'desc' => 'This is description #1',
                 'id' => 1,
                 'image' => '/img/foo.svg',
                 'location' => '/first',
                 'title' => 'First',
         ),
         Data::Navigation::Item->new(
                 'class' => 'nav-item',
                 'desc' => 'This is description #2',
                 'id' => 2,
                 'image' => '/img/bar.svg',
                 'location' => '/second',
                 'title' => 'Second',
         ),
 );

 # Plack application for grid.
 my $app_grid = Plack::App::Tags::HTML->new(
         'component' => 'Tags::HTML::Navigation::Grid',
         'data_init' => [\@items],
         'css' => $css,
         'tags' => $tags,
 )->to_app;

 # Runner.
 my $builder = Plack::Builder->new;
 $builder->mount('/img/foo.svg' => $app_foo);
 $builder->mount('/img/bar.svg' => $app_bar);
 $builder->mount('/' => $app_grid);
 Plack::Runner->new->run($builder->to_app);

 # Output screenshot is in images/ directory.

=begin html

<a href="https://raw.githubusercontent.com/michal-josef-spacek/Tags-HTML-Navigation-Grid/master/images/plack_app_nav_grid.png">
  <img src="https://raw.githubusercontent.com/michal-josef-spacek/Tags-HTML-Navigation-Grid/master/images/plack_app_nav_grid.png" alt="Web app example" width="300px" height="300px" />
</a>

=end html

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Scalar::Util>,
L<Tags::HTML>.

=head1 SEE ALSO

=over

=item L<Tags::HTML::Login::Access>

Tags helper for login access.

=item L<Tags::HTML::Login::Button>

Tags helper for login button.

=item L<Tags::HTML::Login::Register>

Tags helper for login register.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Navigation-Grid>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
