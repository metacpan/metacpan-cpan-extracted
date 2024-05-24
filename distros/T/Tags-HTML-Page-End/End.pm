package Tags::HTML::Page::End;

use base qw(Tags::HTML);
use strict;
use warnings;

our $VERSION = 0.06;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# No CSS support.
	push @params, 'no_css', 1;

	my $self = $class->SUPER::new(@params);

	# Object.
	return $self;
}

# Process 'Tags'.
sub _process {
	my $self = shift;

	# End of page.
	$self->{'tags'}->put(
		['e', 'body'],
		['e', 'html'],
	);

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Tags::HTML::Page::End - Tags helper for HTML page end.

=head1 SYNOPSIS

 use Tags::HTML::Page::End;

 my $obj = Tags::HTML::Page::End->new(%params);
 $obj->process;

=head1 METHODS

=head2 C<new>

 my $obj = Tags::HTML::Page::End->new(%params);

Constructor.

=over 8

=item * C<tags>

'Tags::Output' object.

It's required.

Default value is undef.

=back

=head2 C<process>

 $obj->process;

Process Tags structure for output.

Returns undef.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Tags::HTML::new():
                 Parameter 'tags' must be a 'Tags::Output::*' class.

 process():
         From Tags::HTML::process():
                 Parameter 'tags' isn't defined.

=head1 EXAMPLE

=for comment filename=page_example.pl

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::Page::Begin;
 use Tags::HTML::Page::End;
 use Tags::Output::Indent;

 # Object.
 my $tags = Tags::Output::Indent->new(
         'preserved' => ['style'],
         'xml' => 1,
 );
 my $css = CSS::Struct::Output::Indent->new;
 my $begin = Tags::HTML::Page::Begin->new(
         'css' => $css,
         'tags' => $tags,
 );
 my $end = Tags::HTML::Page::End->new(
         'tags' => $tags,
 );

 # Process page
 $css->put(
        ['s', 'div'],
        ['d', 'color', 'red'],
        ['d', 'background-color', 'black'],
        ['e'],
 );
 $begin->process;
 $tags->put(
        ['b', 'div'],
        ['d', 'Hello world!'],
        ['e', 'div'],
 );
 $end->process;

 # Print out.
 print $tags->flush;

 # Output:
 # <!DOCTYPE html>
 # <html lang="en">
 #   <head>
 #     <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
 #     <meta name="generator" content=
 #       "Perl module: Tags::HTML::Page::Begin, Version: 0.13" />
 #     <title>
 #       Page title
 #     </title>
 #     <style type="text/css">
 # div {
 #         color: red;
 #         background-color: black;
 # }
 # </style>
 #   </head>
 #   <body>
 #     <div>
 #       Hello world!
 #     </div>
 #   </body>
 # </html>

=head1 DEPENDENCIES

L<Tags::HTML>.

=head1 SEE ALSO

=over

=item L<Tags::HTML::Page::Begin>

Tags helper for HTML page begin.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Tags-HTML-Page-End>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.06

=cut
