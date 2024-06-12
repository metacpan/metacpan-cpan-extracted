package Tags::HTML::Footer;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use Error::Pure qw(err);
use Mo::utils::Language 0.05 qw(check_language_639_2);
use Readonly;
use Scalar::Util qw(blessed);
use Unicode::UTF8 qw(decode_utf8);

Readonly::Array our @TEXT_KEYS => qw(version);
Readonly::Scalar our $DEFAULT_HEIGHT => '40px';

our $VERSION = 0.02;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['lang', 'text'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# Language.
	$self->{'lang'} = 'eng';

	# Language texts.
	$self->{'text'} = {
		'eng' => {
			'version' => 'Version',
		},
	};

	# Process params.
	set_params($self, @{$object_params_ar});

	# Check lang.
	check_language_639_2($self, 'lang');

	# Check text.
	if (! defined $self->{'text'}) {
		err "Parameter 'text' is required.";
	}
	if (ref $self->{'text'} ne 'HASH') {
		err "Parameter 'text' must be a hash with language texts.";
	}
	if (! exists $self->{'text'}->{$self->{'lang'}}) {
		err "Texts for language '$self->{'lang'}' doesn't exist.";
	}
	if (@TEXT_KEYS != keys %{$self->{'text'}->{$self->{'lang'}}}) {
		err "Number of texts isn't same as expected.";
	}
	foreach my $req_text_key (@TEXT_KEYS) {
		if (! exists $self->{'text'}->{$self->{'lang'}}->{$req_text_key}) {
			err "Text for lang '$self->{'lang'}' and key '$req_text_key' doesn't exist.";
		}
	}

	# Object.
	return $self;
}

sub _cleanup {
	my $self = shift;

	delete $self->{'_footer'};

	return;
}

sub _init {
	my ($self, $footer) = @_;

	# Check a.
	if (! defined $footer
		|| ! blessed($footer)
		|| ! $footer->isa('Data::HTML::Footer')) {

		err "Footer object must be a 'Data::HTML::Footer' instance.";
	}

	$self->{'_footer'} = $footer;

	return;
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	if (! exists $self->{'_footer'}) {
		return;
	}

	$self->{'tags'}->put(
		['b', 'footer'],

		defined $self->{'_footer'}->version ? (
			['b', 'span'],
			['a', 'class', 'version'],
			defined $self->{'_footer'}->version_url ? (
				['b', 'a'],
				['a', 'href', $self->{'_footer'}->version_url],
			) : (),
			['d', $self->_text('version').': '.$self->{'_footer'}->version],
			defined $self->{'_footer'}->version_url ? (
				['e', 'a'],
			) : (),
			['e', 'span'],
		) : (),

		defined $self->{'_footer'}->copyright_years ? (
			defined $self->{'_footer'}->version ? ['d', ',&nbsp;'] : (),
			['d', decode_utf8('©').' '.$self->{'_footer'}->copyright_years],
			defined $self->{'_footer'}->author ? ['d', ' '] : (),
		) : (),

		defined $self->{'_footer'}->author ? (
			['b', 'span'],
			['a', 'class', 'author'],
			defined $self->{'_footer'}->author_url ? (
				['b', 'a'],
				['a', 'href', $self->{'_footer'}->author_url],
			) : (),
			['d', $self->{'_footer'}->author],
			defined $self->{'_footer'}->author_url ? (
				['e', 'a'],
			) : (),
			['e', 'span'],
		) : (),

		['e', 'footer'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	if (! exists $self->{'_footer'}) {
		return;
	}

	my $height = $self->{'_footer'}->height;
	if (! defined $height) {
		$height = $DEFAULT_HEIGHT;
	}
	$self->{'css'}->put(
		['s', '#main'],
		['d', 'padding-bottom', $height],
		['e'],

		['s', 'footer'],
		['d', 'text-align', 'center'],
		['d', 'padding', '10px 0'],
		['d', 'background-color', '#f3f3f3'],
		['d', 'color', '#333'],
		['d', 'position', 'fixed'],
		['d', 'bottom', 0],
		['d', 'width', '100%'],
		['d', 'height', $height],
		['e'],
	);

	return;
}

sub _text {
	my ($self, $key) = @_;

	return $self->{'text'}->{$self->{'lang'}}->{$key};
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Footer - Tags helper for HTML footer.

=head1 SYNOPSIS

 use Tags::HTML::Footer;

 my $obj = Tags::HTML::Footer->new(%params);
 $obj->cleanup;
 $obj->init($footer);
 $obj->prepare;
 $obj->process;
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Footer->new(%params);

Constructor.

=over 8

=item * C<css>

L<CSS::Struct::Output> object for L<process_css> processing.

Default value is undef.

=item * C<lang>

Language in ISO 639-2 code.

Default value is 'eng'.

=item * C<tags>

L<Tags::Output> object.

Default value is undef.

=item * C<text>

Hash reference with keys defined language in ISO 639-2 code and value with hash
reference with texts.

Required key is 'version' only.

Default value is:

 {
 	'eng' => {
 		'version' => 'Version',
 	},
 }

=back

=head2 C<cleanup>

 $obj->cleanup;

Process cleanup after page run.

In this case cleanup internal representation of a set by L<init>.

Returns undef.

=head2 C<init>

 $obj->init($footer);

Process initialization in page run.

Accepted C<$footer> is L<Data::HTML::Footer>.

Returns undef.

=head2 C<prepare>

 $obj->prepare;

Process initialization before page run.

Do nothing in this object.

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
         From Tags::HTML::new():
                 Parameter 'css' must be a 'CSS::Struct::Output::*' class.
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 init():
         Footer object must be a 'Data::HTML::Footer' instance.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.

 process_css():
         From Tags::HTML::process_css():
                 Parameter 'css' isn't defined.

=head1 EXAMPLE1

=for comment filename=create_and_print_footer.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Data::HTML::Footer;
 use Tags::HTML::Footer;
 use Tags::Output::Indent;
 use Unicode::UTF8 qw(encode_utf8);

 # Object.
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'xml' => 1,
 );
 my $obj = Tags::HTML::Footer->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Data object for footer.
 my $footer = Data::HTML::Footer->new(
         'author' => 'John',
         'author_url' => 'https://example.com',
         'copyright_years' => '2022-2024',
         'height' => '40px',
         'version' => '0.07',
         'version_url' => '/changes',
 );

 # Initialize.
 $obj->init($footer);

 # Process a.
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
 # <footer>
 #   <span class="version">
 #     <a href="/changes">
 #       Version: 0.07
 #     </a>
 #   </span>
 #   ,&nbsp;
 #   © 2022-2024
 # 
 #   <span class="author">
 #     <a href="https://example.com">
 #       John
 #     </a>
 #   </span>
 # </footer>
 # 
 # CSS:
 # #main {
 #         padding-bottom: 40px;
 # }
 # footer {
 #         text-align: center;
 #         padding: 10px 0;
 #         background-color: #f3f3f3;
 #         color: #333;
 #         position: fixed;
 #         bottom: 0;
 #         width: 100%;
 #         height: 40px;
 # }

=head1 EXAMPLE2

=for comment filename=plack_app_table_with_footer.pl

 use strict;
 use warnings;

 package Example;

 use base qw(Plack::Component::Tags::HTML);

 use Data::HTML::Footer;
 use Tags::HTML::Table::View;
 use Tags::HTML::Footer;

 sub _cleanup {
         my ($self, $env) = @_;

         $self->{'_tags_table'}->cleanup;
         $self->{'_tags_footer'}->cleanup;

         return;
 }

 sub _css {
         my ($self, $env) = @_;

         $self->{'_tags_table'}->process_css;
         $self->{'_tags_footer'}->process_css;

         return;
 }

 sub _prepare_app {
         my $self = shift;

         $self->SUPER::_prepare_app();

         my %p = (
                 'css' => $self->{'css'},
                 'tags' => $self->{'tags'},
         );
         $self->{'_tags_table'} = Tags::HTML::Table::View->new(%p);
         $self->{'_tags_footer'} = Tags::HTML::Footer->new(%p);

         # Data object for footer.
         $self->{'_footer_data'} = Data::HTML::Footer->new(
                 'author' => 'John',
                 'author_url' => 'https://example.com',
                 'copyright_years' => '2022-2024',
                 'height' => '40px',
                 'version' => '0.07',
                 'version_url' => '/changes',
         );

         # Data for table.
         $self->{'_table_data'} = [
                 ['name', 'surname'],
                 ['John', 'Wick'],
                 ['Jan', 'Novak'],
         ];

         return;
 }

 sub _process_actions {
         my ($self, $env) = @_;

         # Init.
         $self->{'_tags_footer'}->init($self->{'_footer_data'});
         $self->{'_tags_table'}->init($self->{'_table_data'}, 'no data');

         return;
 }

 sub _tags_middle {
         my ($self, $env) = @_;

         $self->{'tags'}->put(
                 ['b', 'div'],
                 ['a', 'id', '#main'],
         );
         $self->{'_tags_table'}->process;
         $self->{'tags'}->put(
                 ['e', 'div'],
         );

         $self->{'_tags_footer'}->process;

         return;
 }

 package main;

 use CSS::Struct::Output::Indent;
 use Plack::Runner;
 use Tags::Output::Indent;
 
 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'xml' => 1,
         'preserved' => ['style'],
 );
 my $app = Example->new(
         'css' => $css,
         'tags' => $tags,
 )->to_app;
 Plack::Runner->new->run($app);

 # Output screenshot is in images/ directory.

=begin html

<a href="https://raw.githubusercontent.com/michal-josef-spacek/Tags-HTML-Footer/master/images/plack_app_table_with_footer.png">
  <img src="https://raw.githubusercontent.com/michal-josef-spacek/Tags-HTML-Footer/master/images/plack_app_table_with_footer.png" alt="Web app example" width="300px" height="300px" />
</a>

=end html

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Mo::utils::Language>,
L<Readonly>,
L<Scalar::Util>,
L<Tags::HTML>,
L<Unicode::UTF8>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Footer>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
