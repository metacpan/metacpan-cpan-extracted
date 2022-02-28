use POD::Generate;
use strict;
use warnings;
use lib 'lib';

my $pg = POD::Generate->new();

my $version = 'v0.01';

my $string = $pg->start('POD::Generate', 'programmatically generate plain old documentation')
	->version($version)
	->synopsis(q{	use POD::Generate;
	
	my $pg = POD::Generate->new();

	my $data = $pg->start("Test::Memory")
		->synopsis(qq|This is a code snippet.\n\n\tuse Test::Memory;\n\n\tmy \$memory = Test::Memory->new();|)
		->description(q|A test of ones memory.|)
		->methods
		->h2("Mind", "The element of a person that enables them to be aware of the world and their experiences, to think, and to feel; the faculty of consciousness and thought.")
		->v(q|	$memory->Mind();|)
		->h3("Intelligence", "A person or being with the ability to acquire and apply knowledge and skills.")
		->v(q|	$memory->Mind->Intelligence();|)
		->h4("Factual", "Concerned with what is actually the case.")
		->v(q|	$memory->Mind->Intelligence->Factual(%params);|)
		->item("one", "Oxford, Ticehurst and Potters Bar.")
		->item("two", "Koh Chang, Zakynthos and Barbados.")
		->item("three", "An event or occurrence which leaves an impression on someone.")
		->footer(
			name => "LNATION",
			email => 'email@lnation.org'
		)
	->end("string");


produces...

	=head1 NAME

	Test::Memory

	=cut

	=head1 SYNOPSIS

	This is a code snippet.

		use Test::Memory;

		my $memory = Test::Memory->new();

	=cut

	=head1 DESCRIPTION

	A test of ones memory.

	=cut

	=head1 METHODS

	=cut

	=head2 Mind

	The element of a person that enables them to be aware of the world and their experiences, to think,
	and to feel; the faculty of consciousness and thought.

		$memory->Mind();

	=cut

	=head3 Intelligence

	A person or being with the ability to acquire and apply knowledge and skills.

		$memory->Mind->Intelligence();

	=cut

	=head4 Factual

	Concerned with what is actually the case.

		$memory->Mind->Intelligence->Factual(%params);

	=over

	=item one

	Oxford, Ticehurst and Potters Bar.

	=item two

	Koh Chang, Zakynthos and Barbados.

	=item three

	An event or occurrence which leaves an impression on someone.

	=back

	=cut

	=head1 AUTHOR

	LNATION, C<< <email at lnation.org> >>

	=cut

	=head1 BUGS

	Please report any bugs or feature requests to C<bug-test-memory at rt.cpan.org>, or through
	the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Memory>. I will
	be notified, and then you'll automatically be notified of progress on your bug as I make changes.

	=cut

	=head1 SUPPORT

	You can find documentation for this module with the perldoc command.

		perldoc Test::Memory

	You can also look for information at:

	=over

	=item * RT: CPAN's request tracker (report bugs here)

	L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Memory

	=item * CPAN Ratings

	L<https://cpanratings.perl.org/d/Test-Memory>

	=item * Search CPAN

	L<https://metacpan.org/release/Test-Memory>

	=back

	=cut

	=head1 ACKNOWLEDGEMENTS

	=cut

	=head1 LICENSE AND COPYRIGHT

	This software is Copyright (c) 2022 LNATION

	This is free software, licensed under:

		The Artistic License 2.0 (GPL Compatible)

	=cut


        =cut})->description(q|This module purpose is to assist with programmatically generating plain old documentation from code.|)
	->methods
	->h2(q|new|, q|Instantiate a new L<POD::Generate> object. This accepts the following parameters most of which are callbacks which are called when you set a specific plain old document command/identifier.|)
	->p(q|	POD::Generate->new(
		pod => [ ... ],
		p_cb => sub { ... },
		h1_cb => sub { ... },
		h2_cb => sub { ... },
		h3_cb => sub { ... },
		h4_cb => sub { ... },
		item_cb => sub { ... },
		version_cb => sub { ... },
		description_cb => sub { ... },
		synopsis_cb => sub { ... },
		methods_cb => sub { ... },
		exports_cb => sub { ... },
		author_cb => sub { ... },
		bugs_cb => sub { ... },
		support_cb => sub { ... },
		acknowledgements_cb => sub { ... },
		license_cb => sub { ... }
	);|)
	->h3(q|pod|, q|An existing internal pod struct which can either be a hash reference if it's the parent object or an array ref if it is a child object which relates to a specific single package.|)
	->h3("p_cb", "A callback called each time the p method is called, it should be used to manipulate the data which is added to the pod array.")
	->h3("h1_cb", "A callback called each time the h1 method is called, it should be used to manipulate the data which is added to the pod array.")
	->h3("h2_cb", "A callback called each time the h2 method is called, it should be used to manipulate the data which is added to the pod array.")
	->h3("h3_cb", "A callback called each time the h3 method is called, it should be used to manipulate the data which is added to the pod array.")
	->h3("h4_cb", "A callback called each time the h4 method is called, it should be used to manipulate the data which is added to the pod array.")
	->h3("item_cb", "A callback called each time the item method is called, it should be used to manipulate the data which is added to the pod array.")
	->h3("versioncb", "A callback triggered each time the version method is called, it should be used to manipulate the data which is added to the pod array.")
	->h3("description_cb", "A callback triggered each time the description method is called, it should be used to manipulate the data which is added to the pod array.")
	->h3("synopsis_cb", "A callback triggered each time the synopsis method is called, it should be used to manipulate the data which is added to the pod array.")
	->h3("methods_cb", "A callback triggered each time the methods method is called, it should be used to manipulate the data which is added to the pod array.")
	->h3("exports_cb", "A callback triggered each time the exports method is called, it should be used to manipulate the data which is added to the pod array.")
	->h3("author_cb", "A callback triggered each time the author method is called, it should be used to manipulate the data which is added to the pod array.")
	->h3("bugs_cb", "A callback triggered each time the bugs method is called, it should be used to manipulate the data which is added to the pod array.")
	->h3("support_cb", "A callback triggered each time the support method is called, it should be used to manipulate the data which is added to the pod array.")
	->h3("support_items_cb", "A callback triggered each time the support method is called, it should be used to manipulate the data which is added to the pod array.")
	->h3("acknowledgements_cb", "A callback triggered each time the acknowledgements method is called, it should be used to manipulate the data which is added to the pod array.")
	->h3("license_cb", "A callback triggered each time the license method is called, it should be used to manipulate the data which is added to the pod array.")
	->h2("pod", "A reference to the internal pod struct which can either be a hash reference if it's the parent object or an array reference if it is a child object which relates to a specific single package.")
	->v(q|	$pg->pod;|)
	->h2("start", "Start documentation for a new module/package/thing, it is equivalent to calling the ->name. method.")
	->v(q|	$pg->start($name, $abbr);|)
	->h2("end", "End the documentation for a new module/package/thing, it is equivalent to calling the ->generate method.")
	->v(q|	$pg->end($type);|)
	->h2("name", "Start documentation for a new module/package/thing, name accepts two parameteres a name of the thing and an summary of what the thing does. The summary is prepended to the name in the NAME section of the plain old documentation.")
	->v(q|	$pg->name($module, $summary)|)
	->h2("generate", "End documentation for a new module/package/thing, generate accepts a single param which is the type of generation you would like. Currently there are three options they are string, file and seperate_file.")
	->v(q|	$pg->generate($type)|)
	->h2("add", "This is a generic method to add a new section to the POD array, many of the following methods are just wrappers around this add method. It accepts three parameters the identifier/command, the title for the section and the content. All params are optional and undefs can be passed if that is what you desire to do.")
	->v(q|	$pg->add($identifier, $title, $content)|)
	->h2("p", "Add a new paragraph to the current section, this method will format the text to be fixed width of 100 characters.")
	->v(q|	$pg->p($content)|)
	->h2("v", "Add a new verbose paragraph to the current section, this method does not format the width of the content input so will render as passed.")
	->v(q|	$pg->v($content)|)
	->h2("h1", "Add a new head1 section.")
	->v(q|	$pg->h1($title, $content)|)
	->h2("h2", "Add a new head2 section.")
	->v(q|	$pg->h2($title, $content)|)
	->h2("h3", "Add a new head3 section.")
	->v(q|	$pg->h3($title, $content)|)
	->h2("h4", "Add a new head4 section.")
	->v(q|	$pg->h4($title, $content)|)
	->h2("item", "Add a new item section, this will automatically add the over and back identifiers/commands.")
	->v(q|	$pg->item($title, $content)|)
	->h2("version", "Add a new head1 VERSION section.")
	->v(q|	$pg->version($content)|)
	->h2("description", "Add a new head1 DESCRIPTION section.")
	->v(q|	$pg->item($content)|)
	->h2("synopsis", "Add a new head1 SYNOPSIS section.")
	->v(q|	$pg->synopsis($content)|)
	->h2("methods", "Add a new head1 METHODS section.")
	->v(q|	$pg->methods($content)|)
	->h2("exports", "Add a new head1 EXPORTS section.")
	->v(q|	$pg->exports($content)|)
	->h2("footer", "Add the footer to a module/packages POD, this will call formatted_author, bugs, support, acknowledgements and license in that order using there default values or values set in callbacks.")
	->v(q|	$pg->footer(
		name => "LNATION",
		email => "email\@lnation.org",
		bugs => "...",
		support => "...",
		support_items => "...",
		acknowledgements => "...",
		license => "...",
	);|)
	->h2("author", "Add a new head1 AUTHOR section.")
	->v(q|	$pg->author($content)|)
	->h2("formatted_author", "Add a new head1 AUTHOR section, this accepts two parameters the authors name and the authors email.")
	->v(q|	$pg->author($author_name, $author_email)|)
	->h2("bugs", "Add a new head1 BUGS section.")
	->v(q|	$pg->bugs($content)|)
	->h2("support", "Add a new head1 SUPPORT section.")
	->v(q|	$pg->support($content)|)
	->h2("acknowledgements", "Add a new head1 ACKNOWLEDGEMENTS section.")
	->v(q|	$pg->acknowledgements($content)|)
	->h2("license", "Add a new head1 LICENSE section.")
	->v(q|	$pg->license($content)|)
	->h2("to_string", "Generate the current plain old documentation using what is stored in the pod attribute and return it as a string.")
	->v(q|	$pg->to_string()|)
	->h2("to_file", "Generate the current plain old documentation using what is stored in the pod attribute and write it to the end of the modules file. The module must have an __END__ tag and anything which comes after will be re-written.")
	->v(q|	$pg->to_file()|)
	->h2("to_seperate_file", "Generate the current plain old documentation using what is stored in the pod attribute and write it to a new .pod file for the given named module. Each run this file will be re-written.")
	->v(q|	$pg->to_seperate_file()|)
	->footer(name => "LNATION", email => "email\@lnation.org")
->end('file');
