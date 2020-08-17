package Tags::HTML::Page::End;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);

our $VERSION = 0.04;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# 'Tags' object.
	$self->{'tags'} = undef;

	# Process params.
	set_params($self, @params);

	# Check to 'Tags' object.
	if (! $self->{'tags'} || ! $self->{'tags'}->isa('Tags::Output')) {
		err "Parameter 'tags' must be a 'Tags::Output::*' class.";
	}

	# Object.
	return $self;
}

# Process 'Tags'.
sub process {
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
         Parameter 'tags' must be a 'Tags::Output::*' class.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use CSS::Struct::Output::Indent;
 use Tags::HTML::Page::Begin;
 use Tags::HTML::Page::End;
 use Tags::Output::Indent;

 # Object.
 my $tags = Tags::Output::Indent->new(
         'preserved' => ['style'],
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
 $begin->process_css;
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
 # <html>
 #   <head>
 #     <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
 #     </meta>
 #     <title>
 #       Page title
 #     </title>
 #     <style type="text/css">
 # .okay {
 # 	background: #9f9;
 # }
 # .warning {
 # 	background: #ff9;
 # }
 # .alert {
 # 	background: #f99;
 # }
 # .offline {
 # 	color: #999;
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

L<Class::Utils>,
L<Error::Pure>.

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

© Michal Josef Špaček 2020

BSD 2-Clause License

=head1 VERSION

0.04

=cut
