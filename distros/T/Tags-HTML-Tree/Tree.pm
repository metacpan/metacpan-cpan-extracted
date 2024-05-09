package Tags::HTML::Tree;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use English;
use Error::Pure qw(err);
use Mo::utils 0.01 qw(check_required);
use Mo::utils::CSS 0.06 qw(check_css_class check_css_unit);
use Scalar::Util qw(blessed);
use Unicode::UTF8 qw(decode_utf8);

our $VERSION = 0.03;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['css_class', 'indent'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# CSS class.
	$self->{'css_class'} = 'tree';

	# Tree indent.
	$self->{'indent'} = '2em';

	# Process params.
	set_params($self, @{$object_params_ar});

	check_required($self, 'css_class');
	check_css_class($self, 'css_class');

	check_css_unit($self, 'indent');

	# Object.
	return $self;
}

sub _cleanup {
	my $self = shift;

	delete $self->{'_tree'};

	return;
}

sub _init {
	my ($self, $tree) = @_;

	if (! defined $tree
		|| ! blessed($tree)
		|| ! $tree->isa('Tree')) {

		err "Data object must be a 'Tree' instance.";
	}

	$self->{'_tree'} = $tree;

	return;
}

sub _prepare {
	my $self = shift;

	$self->script_js([<<"END"]);
window.addEventListener('load', (event) => {
    let toggler = document.getElementsByClassName("caret");
    for (let i = 0; i < toggler.length; i++) {
        toggler[i].addEventListener("click", function() {
            this.parentElement.querySelector(".nested").classList.toggle("active");
            this.classList.toggle("caret-down");
        });
    }
});
END

	return;
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	if (! exists $self->{'_tree'}) {
		return;
	}

	$self->{'tags'}->put(
		['b', 'ul'],
		['a', 'class', $self->{'css_class'}],
	);
	$self->_li($self->{'_tree'});
	$self->{'tags'}->put(
		['e', 'ul'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	$self->{'css'}->put(
		['s', 'ul, .'.$self->{'css_class'}],
		['d', 'list-style-type', 'none'],
		['d', 'padding-left', $self->{'indent'}],
		['e'],

		['s', '.caret'],
		['d', 'cursor', 'pointer'],
		['d', '-webkit-user-select', 'none'],
		['d', '-moz-user-select', 'none'],
		['d', '-ms-user-select', 'none'],
		['d', 'user-select', 'none'],
		['e'],

		['s', '.caret::before'],
		['d', 'content', decode_utf8('"⯈"')],
		['d', 'color', 'black'],
		['d', 'display', 'inline-block'],
		['d', 'margin-right', '6px'],
		['e'],

		['s', '.caret-down::before'],
		['d', 'transform', 'rotate(90deg)'],
		['e'],

		['s', '.nested'],
		['d', 'display', 'none'],
		['e'],

		['s', '.active'],
		['d', 'display', 'block'],
		['e'],
	);

	return;
}

sub _li {
	my ($self, $tree) = @_;

	my $meta_hr = $tree->meta;
	$self->{'tags'}->put(
		['b', 'li'],
	);
	my @children = $tree->children;
	if (@children) {
		$self->{'tags'}->put(
			['b', 'span'],
			['a', 'class', 'caret'],
			['d', $tree->value],
			['e', 'span'],

			['b', 'ul'],
			['a', 'class', 'nested'],
		);
		foreach my $child (@children) {
			$self->_li($child);
		}
		$self->{'tags'}->put(
			['e', 'ul'],
		);
	} else {
		$self->{'tags'}->put(
			['d', $tree->value],
		);
	}
	$self->{'tags'}->put(
		['e', 'li'],
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Tree - Tags helper for Tree.

=head1 SYNOPSIS

 use Tags::HTML::Tree;

 my $obj = Tags::HTML::Tree->new(%params);
 $obj->cleanup;
 $obj->init($tree);
 $obj->prepare;
 $obj->process;
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Tree->new(%params);

Constructor.

=over 8

=item * C<css>

'L<CSS::Struct::Output>' object for L<process_css> processing.

Default value is undef.

=item * C<no_css>

No CSS support flag.
If this flag is set to 1, L<process_css()> returns undef.

Default value is 0.

=item * C<tags>

'L<Tags::Output>' object.

Default value is undef.

=back

=head2 C<cleanup>

 $obj->cleanup;

Cleanup module to init state.

Returns undef.

=head2 C<init>

 $obj->init($tree);

Set L<Tree> instance defined by C<$tree> to object.

Returns undef.

=head2 C<prepare>

 $obj->prepare;

Process initialization before page run.

Preparing is about adding javascript used in helper to L<Tags::HTML/script_js>
method.

Returns undef.

=head2 C<process>

 $obj->process;

Process L<Tags> structure for output with message.

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
                 Parameter 'tags' must be a 'Tags::Output::*' class.
         Parameter 'css_class' is required.

 init():
         Data object must be a 'Tree' instance.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.

=head1 EXAMPLE1

=for comment filename=example_tree_raw.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Raw;
 use Tags::HTML::Tree;
 use Tags::HTML::Page::Begin;
 use Tags::HTML::Page::End;
 use Tags::Output::Raw;
 use Tree;
 use Unicode::UTF8 qw(decode_utf8 encode_utf8);

 my $css = CSS::Struct::Output::Raw->new;
 my $tags = Tags::Output::Raw->new(
         'preserved' => ['style', 'script'],
         'xml' => 1,
 );

 my $tags_tree = Tags::HTML::Tree->new(
         'css' => $css,
         'tags' => $tags,
 );
 $tags_tree->prepare;

 my $begin = Tags::HTML::Page::Begin->new(
         'author' => decode_utf8('Michal Josef Špaček'),
         'css' => $css,
         'generator' => 'Tags::HTML::Tree',
         'lang' => {
                 'title' => 'Tree',
         },
         'script_js' => $tags_tree->script_js,
         'tags' => $tags,
 );
 my $end = Tags::HTML::Page::End->new(
         'tags' => $tags,
 );

 # Example tree object.
 my $tree = Tree->new('Root');
 $tree->meta({'uid' => 0});
 my $count = 0;
 my %node;
 foreach my $node_string (qw/H I J K L M N O P Q/) {
          $node{$node_string} = Tree->new($node_string);
          $node{$node_string}->meta({'uid' => ++$count});
 }
 $tree->add_child($node{'H'});
 $node{'H'}->add_child($node{'I'});
 $node{'I'}->add_child($node{'J'});
 $node{'H'}->add_child($node{'K'});
 $node{'H'}->add_child($node{'L'});
 $tree->add_child($node{'M'});
 $tree->add_child($node{'N'});
 $node{'N'}->add_child($node{'O'});
 $node{'O'}->add_child($node{'P'});
 $node{'P'}->add_child($node{'Q'});

 # Init.
 $tags_tree->init($tree);

 # Process CSS.
 $tags_tree->process_css;

 # Process HTML.
 $begin->process;
 $tags_tree->process;
 $end->process;

 # Print out.
 print encode_utf8($tags->flush);

 # Output:
 # <!DOCTYPE html>
 # <html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /><meta name="author" content="Michal Josef Špaček" /><meta name="generator" content="Tags::HTML::Tree" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><script type="text/javascript">
 # window.addEventListener('load', (event) => {
 #     let toggler = document.getElementsByClassName("caret");
 #     for (let i = 0; i < toggler.length; i++) {
 #         toggler[i].addEventListener("click", function() {
 #             this.parentElement.querySelector(".nested").classList.toggle("active");
 #             this.classList.toggle("caret-down");
 #         });
 #     }
 # });
 # </script><title>Tree</title><style type="text/css">
 # ul, .tree{list-style-type:none;padding-left:2em;}.caret{cursor:pointer;-webkit-user-select:none;-moz-user-select:none;-ms-user-select:none;user-select:none;}.caret::before{content:"⯈";color:black;display:inline-block;margin-right:6px;}.caret-down::before{transform:rotate(90deg);}.nested{display:none;}.active{display:block;}
 # </style></head><body><ul class="tree"><li><span class="caret">Root</span><ul class="nested"><li><span class="caret">H</span><ul class="nested"><li><span class="caret">I</span><ul class="nested"><li>J</li></ul></li><li>K</li><li>L</li></ul></li><li>M</li><li><span class="caret">N</span><ul class="nested"><li><span class="caret">O</span><ul class="nested"><li><span class="caret">P</span><ul class="nested"><li>Q</li></ul></li></ul></li></ul></li></ul></li></ul></body></html>

=head1 EXAMPLE2

=for comment filename=example_tree_indent.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::Tree;
 use Tags::HTML::Page::Begin;
 use Tags::HTML::Page::End;
 use Tags::Output::Indent;
 use Tree;
 use Unicode::UTF8 qw(decode_utf8 encode_utf8);

 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'preserved' => ['style', 'script'],
         'xml' => 1,
 );

 my $tags_tree = Tags::HTML::Tree->new(
         'css' => $css,
         'tags' => $tags,
 );
 $tags_tree->prepare;

 my $begin = Tags::HTML::Page::Begin->new(
         'author' => decode_utf8('Michal Josef Špaček'),
         'css' => $css,
         'generator' => 'Tags::HTML::Tree',
         'lang' => {
                 'title' => 'Tree',
         },
         'script_js' => $tags_tree->script_js,
         'tags' => $tags,
 );
 my $end = Tags::HTML::Page::End->new(
         'tags' => $tags,
 );

 # Example tree object.
 my $tree = Tree->new('Root');
 $tree->meta({'uid' => 0});
 my $count = 0;
 my %node;
 foreach my $node_string (qw/H I J K L M N O P Q/) {
          $node{$node_string} = Tree->new($node_string);
          $node{$node_string}->meta({'uid' => ++$count});
 }
 $tree->add_child($node{'H'});
 $node{'H'}->add_child($node{'I'});
 $node{'I'}->add_child($node{'J'});
 $node{'H'}->add_child($node{'K'});
 $node{'H'}->add_child($node{'L'});
 $tree->add_child($node{'M'});
 $tree->add_child($node{'N'});
 $node{'N'}->add_child($node{'O'});
 $node{'O'}->add_child($node{'P'});
 $node{'P'}->add_child($node{'Q'});

 # Init.
 $tags_tree->init($tree);

 # Process CSS.
 $tags_tree->process_css;

 # Process HTML.
 $begin->process;
 $tags_tree->process;
 $end->process;

 # Print out.
 print encode_utf8($tags->flush);

 # Output:
 # <!DOCTYPE html>
 # <html lang="en">
 #   <head>
 #     <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
 #     <meta name="author" content="Michal Josef Špaček" />
 #     <meta name="generator" content="Tags::HTML::Tree" />
 #     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
 #     <script type="text/javascript">
 # window.addEventListener('load', (event) => {
 #     let toggler = document.getElementsByClassName("caret");
 #     for (let i = 0; i < toggler.length; i++) {
 #         toggler[i].addEventListener("click", function() {
 #             this.parentElement.querySelector(".nested").classList.toggle("active");
 #             this.classList.toggle("caret-down");
 #         });
 #     }
 # });
 # </script>    <title>
 #       Tree
 #     </title>
 #     <style type="text/css">
 # ul, .tree {
 # 	list-style-type: none;
 # 	padding-left: 2em;
 # }
 # .caret {
 # 	cursor: pointer;
 # 	-webkit-user-select: none;
 # 	-moz-user-select: none;
 # 	-ms-user-select: none;
 # 	user-select: none;
 # }
 # .caret::before {
 # 	content: "⯈";
 # 	color: black;
 # 	display: inline-block;
 # 	margin-right: 6px;
 # }
 # .caret-down::before {
 # 	transform: rotate(90deg);
 # }
 # .nested {
 # 	display: none;
 # }
 # .active {
 # 	display: block;
 # }
 # </style>
 #   </head>
 #   <body>
 #     <ul class="tree">
 #       <li>
 #         <span class="caret">
 #           Root
 #         </span>
 #         <ul class="nested">
 #           <li>
 #             <span class="caret">
 #               H
 #             </span>
 #             <ul class="nested">
 #               <li>
 #                 <span class="caret">
 #                   I
 #                 </span>
 #                 <ul class="nested">
 #                   <li>
 #                     J
 #                   </li>
 #                 </ul>
 #               </li>
 #               <li>
 #                 K
 #               </li>
 #               <li>
 #                 L
 #               </li>
 #             </ul>
 #           </li>
 #           <li>
 #             M
 #           </li>
 #           <li>
 #             <span class="caret">
 #               N
 #             </span>
 #             <ul class="nested">
 #               <li>
 #                 <span class="caret">
 #                   O
 #                 </span>
 #                 <ul class="nested">
 #                   <li>
 #                     <span class="caret">
 #                       P
 #                     </span>
 #                     <ul class="nested">
 #                       <li>
 #                         Q
 #                       </li>
 #                     </ul>
 #                   </li>
 #                 </ul>
 #               </li>
 #             </ul>
 #           </li>
 #         </ul>
 #       </li>
 #     </ul>
 #   </body>
 # </html>

=head1 EXAMPLE3

=for comment filename=plack_app_tree.pl

 use strict;
 use warnings;
 
 use CSS::Struct::Output::Indent;
 use Plack::App::Tags::HTML;
 use Plack::Runner;
 use Tags::HTML::Tree;
 use Tags::Output::Indent;
 use Tree;

 # Example tree object.
 my $data_tree = Tree->new('Root');
 my %node;
 foreach my $node_string (qw/H I J K L M N O P Q/) {
          $node{$node_string} = Tree->new($node_string);
 }
 $data_tree->add_child($node{'H'});
 $node{'H'}->add_child($node{'I'});
 $node{'I'}->add_child($node{'J'});
 $node{'H'}->add_child($node{'K'});
 $node{'H'}->add_child($node{'L'});
 $data_tree->add_child($node{'M'});
 $data_tree->add_child($node{'N'});
 $node{'N'}->add_child($node{'O'});
 $node{'O'}->add_child($node{'P'});
 $node{'P'}->add_child($node{'Q'});
 
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'xml' => 1,
         'preserved' => ['script', 'style'],
 );
 my $app = Plack::App::Tags::HTML->new(
         'component' => 'Tags::HTML::Tree',
         'data_init' => [$data_tree],
         'css' => $css,
         'tags' => $tags,
 )->to_app;
 Plack::Runner->new->run($app);

 # Output screenshot is in images/ directory.

=begin html

<a href="https://raw.githubusercontent.com/michal-josef-spacek/Tags-HTML-Tree/master/images/plack_app_tree.png">
  <img src="https://raw.githubusercontent.com/michal-josef-spacek/Tags-HTML-Tree/master/images/plack_app_tree.png" alt="Web app example" width="300px" height="300px" />
</a>

=end html

=head1 DEPENDENCIES

L<Class::Utils>,
L<English>,
L<Error::Pure>,
L<Mo::utils>,
L<Mo::utils::CSS>,
L<Scalar::Util>,
L<Unicode::UTF8>,
L<Tags::HTML>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Tree>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
