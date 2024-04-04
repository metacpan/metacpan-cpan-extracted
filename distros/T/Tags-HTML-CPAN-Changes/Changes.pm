package Tags::HTML::CPAN::Changes;

use base qw(Tags::HTML);
use strict;
use warnings;

use Class::Utils qw(set_params split_params);
use CPAN::Version;
use English;
use Error::Pure qw(err);
use Scalar::Util qw(blessed);

our $VERSION = 0.03;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my ($object_params_ar, $other_params_ar) = split_params(
		['css_class'], @params);
	my $self = $class->SUPER::new(@{$other_params_ar});

	# CSS class.
	$self->{'css_class'} = 'changes';

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

	delete $self->{'_changes'};

	return;
}

sub _init {
	my ($self, $changes) = @_;

	if (! defined $changes
		|| ! blessed($changes)
		|| ! $changes->isa('CPAN::Changes')) {

		err "Data object must be a 'CPAN::Changes' instance.";
	}

	if (CPAN::Version->vlt($changes->VERSION, '0.500002')) {
		err "Minimal version of supported CPAN::Changes is 0.500002.",
			'Version', $changes->VERSION,
		;
	}

	$self->{'_changes'} = $changes;

	return;
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	if (! exists $self->{'_changes'}) {
		return;
	}

	$self->{'tags'}->put(
		['b', 'div'],
		['a', 'class', $self->{'css_class'}],
	);
	if ($self->{'_changes'}->preamble ne '') {
		$self->{'tags'}->put(
			['b', 'h1'],
			['d', $self->{'_changes'}->preamble],
			['e', 'h1'],
		);
	}
	foreach my $changes_rel (sort { $b->version <=> $a->version } $self->{'_changes'}->releases) {
		my $version = $changes_rel->version;
		if (defined $changes_rel->date) {
			$version .= ' - '.$changes_rel->date;
		}
		if (defined $changes_rel->note) {
			$version .= ' '.$changes_rel->note;
		}
		$self->{'tags'}->put(
			['b', 'div'],
			['a', 'class', 'version'],
			['b', 'h2'],
			['d', $version],
			['e', 'h2'],
		);
		$self->{'tags'}->put(
			['b', 'ul'],
			['a', 'class', 'version-changes'],
		);
		foreach my $entry (@{$changes_rel->entries}) {
			if (defined $entry->text && $entry->text ne '') {
				$self->{'tags'}->put(
					['b', 'h3'],
					['d', '['.$entry->text.']'],
					['e', 'h3'],
				);
			}
			foreach my $change (@{$entry->entries}) {
				$self->{'tags'}->put(
					['b', 'li'],
					['a', 'class', 'version-change'],
					['d', $change->text],
					['e', 'li'],
				);
			}
		}
		$self->{'tags'}->put(
			['e', 'ul'],
		);
		$self->{'tags'}->put(
			['e', 'div'],
		);
	}
	$self->{'tags'}->put(
		['e', 'div'],
	);

	return;
}

sub _process_css {
	my $self = shift;

	if (! exists $self->{'_changes'}) {
		return;
	}

	$self->{'css'}->put(
		['s', '.'.$self->{'css_class'}],
		['d', 'max-width', '800px'],
		['d', 'margin', 'auto'],
		['d', 'background', '#fff'],
		['d', 'padding', '20px'],
		['d', 'border-radius', '8px'],
		['d', 'box-shadow', '0 2px 4px rgba(0, 0, 0, 0.1)'],
		['e'],

		['s', '.'.$self->{'css_class'}.' .version'],
		['d', 'border-bottom', '2px solid #eee'],
		['d', 'padding-bottom', '20px'],
		['d', 'margin-bottom', '20px'],
		['e'],

		['s', '.'.$self->{'css_class'}.' .version:last-child'],
		['d', 'border-bottom', 'none'],
		['e'],

		['s', '.'.$self->{'css_class'}.' .version h2'],
		['s', '.'.$self->{'css_class'}.' .version h3'],
		['d', 'color', '#007BFF'],
		['d', 'margin-top', 0],
		['e'],

		['s', '.'.$self->{'css_class'}.' .version-changes'],
		['d', 'list-style-type', 'none'],
		['d', 'padding-left', 0],
		['e'],

		['s', '.'.$self->{'css_class'}.' .version-change'],
		['d', 'background-color', '#f8f9fa'],
		['d', 'margin', '10px 0'],
		['d', 'padding', '10px'],
		['d', 'border-left', '4px solid #007BFF'],
		['d', 'border-radius', '4px'],
		['e'],
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::CPAN::Changes - Tags helper for CPAN changes.

=head1 SYNOPSIS

 use Tags::HTML::CPAN::Changes;

 my $obj = Tags::HTML::CPAN::Changes->new(%params);
 $obj->cleanup;
 $obj->init($changes);
 $obj->prepare;
 $obj->process;
 $obj->process_css;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::CPAN::Changes->new(%params);

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

 $obj->init($changes);

Set L<CPAN::Changes> instance defined by C<$changes> to object.

Minimal version of L<CPAN::Changes> is 0.500002.

Returns undef.

=head2 C<prepare>

 $obj->prepare;

Process initialization before page run.

Do nothing in this module.

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
         Data object must be a 'CPAN::Changes' instance.
         Minimal version of supported CPAN::Changes is 0.500002.",
                 Version: %s

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.

=head1 EXAMPLE1

=for comment filename=example_change_raw.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Raw;
 use CPAN::Changes;
 use Tags::HTML::CPAN::Changes;
 use Tags::HTML::Page::Begin;
 use Tags::HTML::Page::End;
 use Tags::Output::Raw;
 use Unicode::UTF8 qw(decode_utf8 encode_utf8);

 my $css = CSS::Struct::Output::Raw->new;
 my $tags = Tags::Output::Raw->new(
         'xml' => 1,
 );

 my $begin = Tags::HTML::Page::Begin->new(
         'author' => decode_utf8('Michal Josef Špaček'),
         'css' => $css,
         'generator' => 'EXAMPLE1',
         'lang' => {
                 'title' => 'Hello world!',
         },
         'tags' => $tags,
 );
 my $end = Tags::HTML::Page::End->new(
         'tags' => $tags,
 );
 my $obj = Tags::HTML::CPAN::Changes->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Example changes object.
 my $changes = CPAN::Changes->new(
         'preamble' => 'Revision history for perl module Foo::Bar',
         'releases' => [
                 CPAN::Changes::Release->new(
                         'date' => '2009-07-06',
                         'entries' => [
                                 CPAN::Changes::Entry->new(
                                         'entries' => [
                                                 'item #1',
                                         ],
                                 ),
                         ],
                         'version' => 0.01,
                 ),
         ],
 );

 # Init.
 $obj->init($changes);

 # Process CSS.
 $obj->process_css;

 # Process HTML.
 $begin->process;
 $obj->process;
 $end->process;

 # Print out.
 print encode_utf8($tags->flush);

 # Output:
 # <!DOCTYPE html>
 # <html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /><meta name="author" content="Michal Josef Špaček" /><meta name="generator" content="EXAMPLE1" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><title>Hello world!</title><style type="text/css">.changes{max-width:800px;margin:auto;background:#fff;padding:20px;border-radius:8px;box-shadow:0 2px 4px rgba(0, 0, 0, 0.1);}.changes .version{border-bottom:2px solid #eee;padding-bottom:20px;margin-bottom:20px;}.changes .version:last-child{border-bottom:none;}.changes .version h2,.changes .version h3{color:#007BFF;margin-top:0;}.changes .version-changes{list-style-type:none;padding-left:0;}.changes .version-change{background-color:#f8f9fa;margin:10px 0;padding:10px;border-left:4px solid #007BFF;border-radius:4px;}
 # </style></head><body><div class="changes"><div class="version"><h2>0.01 - 2009-07-06</h2><ul class="version-changes"><li class="version-change">item #1</li></ul></div></div></body></html>

=head1 EXAMPLE2

=for comment filename=example_change_indent.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use CPAN::Changes;
 use CPAN::Changes::Entry;
 use CPAN::Changes::Release;
 use Tags::HTML::CPAN::Changes;
 use Tags::HTML::Page::Begin;
 use Tags::HTML::Page::End;
 use Tags::Output::Indent;
 use Unicode::UTF8 qw(decode_utf8 encode_utf8);

 my $css = CSS::Struct::Output::Indent->new;
 my $tags = Tags::Output::Indent->new(
         'preserved' => ['style'],
         'xml' => 1,
 );

 my $begin = Tags::HTML::Page::Begin->new(
         'author' => decode_utf8('Michal Josef Špaček'),
         'css' => $css,
         'generator' => 'EXAMPLE2',
         'lang' => {
                 'title' => 'Hello world!',
         },
         'tags' => $tags,
 );
 my $end = Tags::HTML::Page::End->new(
         'tags' => $tags,
 );

 my $obj = Tags::HTML::CPAN::Changes->new(
         'css' => $css,
         'tags' => $tags,
 );

 # Example changes object.
 my $changes = CPAN::Changes->new(
         'preamble' => 'Revision history for perl module Foo::Bar',
         'releases' => [
                 CPAN::Changes::Release->new(
                         'date' => '2009-07-06',
                         'entries' => [
                                 CPAN::Changes::Entry->new(
                                         'entries' => [
                                                 'item #1',
                                         ],
                                 ),
                         ],
                         'version' => 0.01,
                 ),
         ],
 );

 # Init.
 $obj->init($changes);

 # Process CSS.
 $obj->process_css;

 # Process HTML.
 $begin->process;
 $obj->process;
 $end->process;

 # Print out.
 print encode_utf8($tags->flush);

 # Output:
 # <!DOCTYPE html>
 # <html lang="en">
 #   <head>
 #     <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
 #     <meta name="author" content="Michal Josef Špaček" />
 #     <meta name="generator" content="EXAMPLE2" />
 #     <meta name="viewport" content="width=device-width, initial-scale=1.0" />
 #     <title>
 #       Hello world!
 #     </title>
 #     <style type="text/css">
 # .changes {
 # 	max-width: 800px;
 # 	margin: auto;
 # 	background: #fff;
 # 	padding: 20px;
 # 	border-radius: 8px;
 # 	box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
 # }
 # .changes .version {
 # 	border-bottom: 2px solid #eee;
 # 	padding-bottom: 20px;
 # 	margin-bottom: 20px;
 # }
 # .changes .version:last-child {
 # 	border-bottom: none;
 # }
 # .changes .version h2, .changes .version h3 {
 # 	color: #007BFF;
 # 	margin-top: 0;
 # }
 # .changes .version-changes {
 # 	list-style-type: none;
 # 	padding-left: 0;
 # }
 # .changes .version-change {
 # 	background-color: #f8f9fa;
 # 	margin: 10px 0;
 # 	padding: 10px;
 # 	border-left: 4px solid #007BFF;
 # 	border-radius: 4px;
 # }
 # </style>
 #   </head>
 #   <body>
 #     <div class="changes">
 #       <div class="version">
 #         <h2>
 #           0.01 - 2009-07-06
 #         </h2>
 #         <ul class="version-changes">
 #           <li class="version-change">
 #             item #1
 #           </li>
 #         </ul>
 #       </div>
 #     </div>
 #   </body>
 # </html>

=head1 DEPENDENCIES

L<Class::Utils>,
L<CPAN::Version>,
L<English>,
L<Error::Pure>,
L<Scalar::Util>,
L<Tags::HTML>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-CPAN-Changes>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
