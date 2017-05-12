package Template::Recall;

use 5.008001;
use strict;
use warnings;

use base qw(Template::Recall::Base);

# This version: only single file template or template string
our $VERSION='0.21';


sub new {

	my $class = shift;
	my $self = {};
	bless $self, $class;

	my ( %h ) = @_;

	# Default values
	$self->{'secpat'} = qr/\[\s*=+\s*(\w+)\s*=+\s*\]/;
	$self->{'val_delims'} = [ qr/\['/, qr/'\]/ ];
	$self->{'trim'} = undef;		# undef=off


    if (exists $h{'secpat'} and ref $h{'secpat'}) {
        $self->{'secpat'} = $h{'secpat'};
    }

    if (exists $h{'val_delims'} and ref $h{'val_delims'} eq 'ARRAY') {
        $self->{'val_delims'} = $h{'val_delims'};
    }

	# User supplied the template from a string

	if ( defined($h{'template_str'}) ) {
		$self->init_template($h{'template_str'});
		return $self;
	}

    die 'Path to template not defined or missing'
        unless defined($h{'template_path'}) and -e $h{'template_path'};


    $self->init_template_from_file($h{'template_path'});

	return $self;

} # new()


sub init_template_from_file {

	my ($self, $tpath) = @_;

	my $s;
    open my $fh, $tpath or die "Couldn't open $tpath: $!";
	while(<$fh>) { $s .= $_; }
	close $fh;
    $self->init_template($s);

}

# Handle template passed by user as string
sub init_template {

    my ($self, $template) = @_;

    my $sec = [ split( /($self->{'secpat'})/, $template ) ];

    my %h;
    my $curr = '';

    # Top-down + only one 'body' follows section, why this parse hack works
    for (my $i=0; $i <= $#{$sec} ; $i++) {
        my $el = $$sec[$i];
        next if $el =~ /^$/;
        if ($el =~ /$self->{'secpat'}/) {
            $curr = $1;
            $h{$curr} = '';
            $i++; # Skip next, it's the section name (an artifact)
        }
        else {
            $h{$curr} = $el;
        }
    }

    $self->{'template_secs'} = \%h;

} # init_template()


sub render {

	my ( $self, $section, $hash_ref ) = @_;

	die "Error: no section to render: $section\n" if !defined($section);

    return if !exists $self->{'template_secs'}->{$section};

    return $self->SUPER::render(
        $self->{'template_secs'}->{$section}, $hash_ref, $self->{'val_delims'});

} # render()


# Set trim flags
sub trim {
	my ($self, $flag) = @_;

	# trim() with no params defaults to trimming both ends
	if (!defined $flag) {
		$self->{'trim'} = 'both';
		return;
	}

	# Turn trimming off
	if ($flag =~ /^(off|o)$/i) {
		$self->{'trim'} = undef;
		return;
	}

	# Make sure we get something valid
	if ($flag !~ /^(off|left|right|both|l|r|b|o)$/i) {
		$self->{'trim'} = undef;
		return;
	}

	$self->{'trim'} = $flag;
	return;


} # trim()



1;


__END__

=head1 NAME

Template::Recall - "Reverse callback" templating system


=head1 SYNOPSIS

	use Template::Recall;

	# Load template sections from file
	my $tr = Template::Recall->new( template_path => '/path/to/template_file.htmt' );

	my @prods = (
		'soda,sugary goodness,$.99',
		'energy drink,jittery goodness,$1.99',
		'green tea,wholesome goodness,$1.59'
		);

	print $tr->render('header');

	for (@prods)
	{
		my %h;
		my @a = split(/,/, $_);

		$h{'product'} = $a[0];
		$h{'description'} = $a[1];
		$h{'price'} = $a[2];

		print $tr->render('prodrow', \%h);
	}

	print $tr->render('footer');

=head1 DESCRIPTION

Template::Recall works using what I call a "reverse callback" approach. A
"callback" templating system (i.e. Mason, Apache::ASP) generally includes
template markup and code in the same file. The template "calls" out to the code
where needed. Template::Recall works in reverse. Rather than inserting code
inside the template, the template remains separate, but broken into sections.
The sections are called from within the code at the appropriate times.

A template section, such as C<prodrow> above, looks something like

    [=== prodrow ===]
	<tr>
		<td>[' product ']</td>
		<td>[' description ']</td>
		<td>['price']</td>
	</tr>

The C<render()> method is used to "call" back to the template sections. Simply
create a hash of name/value pairs that represent the template tags you wish to
replace, and pass a reference of it along with the template section, i.e.

	$tr->render('prodrow', \%h);

=head1 METHODS

=head3 C<new( [ template_path =E<gt> $path, secpat =E<gt> $section_pattern, delims =E<gt> ['opening', 'closing'] ] )>

Instantiates the object. You must pass either C<template_path> or
C<template_str> as the first parameter.

C<secpat>, by default, is C<qr/[\s*=+\s*(\w+)\s*=+\s*]/>. So if you put all your
template sections in one file, the way Template::Recall knows where to get the
sections is via this pattern, e.g.

	[ ==================== header ==================== ]
	<html
		<head><title>Untitled</title></head>
	<body>

	<table>

	[ ==================== prodrow ==================== ]
	<tr>
		<td>[' product ']</td>
		<td>[' description ']</td>
		<td>[' price ']</td>
	</tr>

	[==================== footer ==================== ]

	</table>

	</body>
	</html>

You may set C<secpat> to any pattern you wish, but you probably shouldn't
unless you have some legitimate reason to do so. It needs to be a compiled
regex too: C<qr//>.

The default delimeters for variables in Template::Recall are C<['> (opening)
and C<']> (closing). This tells Template::Recall that C<[' price ']> is
different from "price" in the same template, e.g.

	What is the price? It's [' price ']

You can change C<delims> by passing a two element array to C<new()>
representing the opening and closing delimiters, such as C<delims =E<gt> [
'E<lt>%', '%E<gt>' ]>. If you don't want to use delimiters at all, simply set
C<delims =E<gt> 'none'>.

The C<template_str> parameter allows you to pass in a string that contains the
template data, instead of reading it from disk:

C<new( template_str =E<gt> $str )>

For example, this enables you to store templates in the C<__DATA__> section of
the calling script

=head3 C<render( $section [, $reference_to_hash ] );>

You must specify C<$section>, which tells C<render()> what template
"section" to load. C<$reference_to_hash> is optional. Sometimes you just want
to return a template section without any variables. Usually,
C<$reference_to_hash> will be used, and C<render()> iterates through the hash,
replacing the F<key> found in the template with the F<value> associated with 
F<key>. A reference was chosen for efficiency.

=head3 C<trim( 'off|left|right|both' );>

You may want to control whitespace in your section output. You could use
C<s///> on the returned text, of course, but C<trim()>is included for
convenience and clarity. Simply pass the directive you want when you call it,
e.g.

	$tr->trim('right');
	print $tr->render('sec1', \%values);
	$tr->trim('both')
	print $tr->render('sec2', \%values2);
	$tr->trim('off');
	# ...etc...

If you just do

	$tr->trim();

it will default to trimming both ends of the template. Note that you can also
use abbreviations, i.e. C<$tr-E<gt>trim( 'o|l|r|b' )> to save a few keystrokes.

=head1 AUTHOR

James Robson E<lt>arbingersys F<AT> gmail F<DOT> comE<gt>

=head1 SEE ALSO

Some context -- L<http://perl.apache.org/docs/tutorials/tmpl/comparison/comparison.html>

Tutorial -- L<http://www.perl.com/pub/2008/03/14/reverse-callback-templating.html>

Performance comparison -- L<http://soundly.me/template-recall-vs-template-toolkit>
