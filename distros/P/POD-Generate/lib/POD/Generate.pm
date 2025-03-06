package POD::Generate;
use 5.006; use strict; use warnings; our $VERSION = q|0.02|;

use overload 
	q|${}| => sub { $_[0]->generate(q|string|) },
	fallback => 1;

sub new {
	my $class = shift;
   	my $self = bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
	$self->{pod} ||= {};
	$self->{width} ||= 100;
	return $self;
}

sub pod { $_[0]->{pod} }

sub start { name(@_) }

sub end { generate(@_) }

sub name {
	my ($self, $name, $abbr) = @_;
	$self->pod->{$name} = __PACKAGE__->new(name => $name, width => $self->{width}, pod => []);
	push @{ $self->pod->{$name}->pod }, {
		identifier => q|head1|,
		title => q|NAME|,
		content =>  $name . ($abbr ? (q| - | . $abbr) : q||)
	};
	return $self->{pod}->{$name};
}

sub generate {
	my ($self, $type) = @_;
	if (ref $self->pod eq q|HASH|) {
		my %out;
		for my $key (keys %{$self->pod}) {
			$out{$key} = $self->pod->{$key}->generate();
		}
		return \%out;
	}
	$type ||= q|string|;
	my $last_identifier = _last_identifier($self);
	push @{$self->{pod}}, {
		identifier => q|back|
	} if ($last_identifier =~ m/item|over/);
	push @{$self->pod}, {
		identifier => q|cut|
	} if ($last_identifier !~ m/none|cut/);
	my $pod = q||;
	$pod .=	$self->generate_pod_section($_) for (@{ $self->pod });
	my $method = sprintf(q|to_%s|, $type);
	$self->$method($pod || q|empty|);
}

sub add {
	my ($self, $identifier, $title, $content) = @_;
	my $has_ident = defined $identifier;	
	if (defined $content && ($identifier || "p") ne 'v' && $self->{width}) {
		my @chars = split "", $content;
		my $die = 0;
		my ($string, $length) = ('',  0);
		while (@chars) {
			my $i = 0;
			$i++ while (defined $chars[$i] && $chars[$i] !~ m/(\s|\n)/);
			$length = 0 if ($i == 0 && $chars[$i] =~ m/\n/);
			$i ||= 1;
			($length + $i <= $self->{width}) ? do { 
				$string .= join "", splice @chars, 0, $i || 1;
				$length += $i;
			} : do {
				$string .= "\n" . join "", splice @chars, 0, $i || 1;
				$string =~ s/\s$//i && $i--;
				$length = $i;
			};
		}
		$content = $string;
	} elsif ($has_ident && $identifier eq 'v') {
		$identifier = $has_ident = undef;
	}

	if ($has_ident) {
		if ($identifier eq q|item|) {
			if (_last_identifier($self) !~ m/item|over/) {
				push @{$self->{pod}}, {
					identifier => q|over|
				};
			}
		} else {
			my $last_identifier = _last_identifier($self);
			if ($last_identifier =~ m/item|over/) {
				push @{$self->{pod}}, {
					identifier => q|back|
				};
			}
			push @{$self->{pod}}, {
				identifier => q|cut|
			} if ($last_identifier !~ m/cut/);
		}
	}
	push @{ $self->{pod} }, {
		(defined $identifier ? (identifier => $identifier) : ()),
		(defined $title ? (title => $title) : ()),
		(defined $content ? (content => $content) : ())
	};
}

sub p {
	my $self = shift;
	$self->add(undef, undef, @_);
	$self;
}

sub v {
	my $self = shift;
	$self->add('v', undef, @_);
	$self;
}

sub h1 {
	my $self = shift;
	$self->add(q|head1|, @_);
	$self;
}

sub h2 {
	my $self = shift;
	$self->add(q|head2|, @_);
	$self;
}

sub h3 {
	my $self = shift;
	$self->add(q|head3|, @_);
	$self;
}

sub h4 {
	my $self = shift;
	$self->add(q|head4|, @_);
	$self;
}

sub item {
	my $self = shift;
	$self->add(q|item|, @_);
	$self;
}

sub version {
	my $self = shift;
	$self->add(q|head1|, q|VERSION|, $self->_default_version_cb(@_));
	$self;
}

sub description {
	my $self = shift;
	$self->add(q|head1|, q|DESCRIPTION|, $self->_default_description_cb(@_));
	$self;
}

sub synopsis {
	my $self = shift;
	$self->add(q|head1|, q|SYNOPSIS|, undef);
	$self->add(q|v|, undef,  $self->_default_synopsis_cb(@_));
	$self;
}

sub methods {
	my $self = shift;
	$self->add(q|head1|, q|METHODS|, $self->_default_methods_cb(@_));
	$self;
}

sub exports {
	my $self = shift;
	$self->add(q|head1|, q|EXPORTS|, $self->_default_exports_cb(@_));
	$self;
}

sub footer {
	my ($self, %args) = @_;
	$self->formatted_author($args{name}, $args{email})
		->bugs($args{bugs})
		->support($args{support}, @{$args{support_items}})
		->acknowledgements($args{acknowledgements})
		->license($args{license}, $args{name});
	$self;
}

sub author {
	my $self = shift;
	$self->add(q|head1|, q|AUTHOR|, $self->_default_author_cb(@_));
	$self;
}

sub formatted_author {
	my ($self, $name, $email) = @_;
	$email =~ s/\@/ at /g;
	$self->add(q|head1|, q|AUTHOR|, sprintf(q|%s, C<< <%s> >>|, $name, $email));
	$self
}

sub bugs {
	my ($self, $content) = @_;
	$self->add(q|head1|, q|BUGS|, $self->_default_bugs_cb($content));
	$self;
}

sub support {
	my ($self, $content, @items) = @_;
	$self->add(q|head1|, q|SUPPORT|, $self->_default_support_cb($content));
	@items = $self->_default_support_items_cb(@items);
	$self->add(q|item|, @{$_}) for (@items);
	$self;
}

sub _default_version_cb {
	my ($self) = shift;
	return $self->{version_cb} && $self->{version_cb}->($self, @_) || @_;
}

sub _default_description_cb {
	my ($self) = shift;
	return $self->{description_cb} && $self->{description_cb}->($self, @_) || @_;
}

sub _default_synopsis_cb {
	my ($self) = shift;
	return $self->{synopsis_cb} && $self->{synopsis_cb}->($self, @_) || @_;
}

sub _default_methods_cb {
	my ($self) = shift;
	return $self->{methods_cb} && $self->{methods_cb}->($self, @_) || @_;
}

sub _default_exports_cb {
	my ($self) = shift;
	return $self->{exports_cb} && $self->{exports_cb}->($self, @_) || @_; 
}

sub _default_author_cb {
	my ($self) = shift;
	return $self->{author_cb} && $self->{author_cb}->($self, @_) || @_; 
}

sub _default_bugs_cb {
	my ($self, $content) = @_;
	return $self->{bugs_cb} 
		? $self->{bugs_cb}->($self, $content)
		: defined $content
			? $content  
			: $self->_default_bugs_content();
}

sub _default_bugs_content {
	my ($self) = @_;
	(my $formatted_name = $self->{name}) =~ s/\:\:/\-/g;
	my $content = sprintf(
		qq|Please report any bugs or feature requests to C<bug-%s at rt.cpan.org>, or through\n|,
		lc($formatted_name)
	);
	$content .= sprintf(
		qq|the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=%s>. I will\n|,
		$formatted_name
	);
	$content .= q|be notified, and then you'll automatically be notified of progress on your bug as I make changes.|;
	return $content;
}

sub _default_support_cb {
	my ($self, $content) = @_;
	return $self->{support_cb} 
		? $self->{support_cb}->($self, $content)
		: defined $content
			? $content
			: $self->_default_support_content();
}

sub _default_support_content {
	my ($self) = @_;
	my $content = q|You can find documentation for this module with the perldoc command.|;	
	$content .= sprintf(qq|\n\n	perldoc %s\n\n|, $self->{name});
	$content .= q|You can also look for information at:|;
	return $content;
}

sub _default_support_items_cb {
	my ($self, @items) = @_;
	return $self->{support_items_cb}
		? $self->{support_items_cb}->($self, @items)
		: scalar @items
			? @items
			: $self->_default_support_items();
}

sub _default_support_items {
	my ($self) = @_;
	my @items = ();
	(my $formatted_name = $self->{name}) =~ s/\:\:/\-/g;
	push @items, [
		q|* RT: CPAN's request tracker (report bugs here)|,
		sprintf(q|L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=%s>|, $formatted_name)
	];
	push @items, [
		q|* Search CPAN|,
		sprintf(q|L<https://metacpan.org/release/%s>|, $formatted_name)
	];
	return @items;
}

sub acknowledgements {
	my $self = shift;
	$self->add(q|head1|, q|ACKNOWLEDGEMENTS|, $self->default_acknowledgements_cb(@_));
	$self;
}

sub default_acknowledgements_cb {
	my ($self) = shift;
	return $self->{acknowledgements_cb} && $self->{acknowledgements_cb}->($self, @_) || @_;
}

sub license {
	my ($self, $license, $name) = @_;
	$self->add(q|head1|, q|LICENSE AND COPYRIGHT|, $self->default_license_cb($license, $name));
}

sub default_license_cb {
	my ($self, $license, $name) = @_;
	return $self->{license_cb} 
		? $self->{license_cb}->($self, $license, $name)
		: defined $license
			? $license
			: $self->default_license_content($name);
}

sub default_license_content {
	my ($self, $author) = @_;
	my $content = sprintf(qq|This software is Copyright (c) 2022 %s\n\n|, $author || q|by the author|);
	$content .= q|This is free software, licensed under:|;
	$content .= qq|\n\n	The Artistic License 2.0 (GPL Compatible)|;
}

sub generate_pod_section {
	my ($self, $section) = @_;
	my $pod = q||;
	$pod .= sprintf(qq|\n\n=%s|, $section->{identifier}) if $section->{identifier};
	$pod .= sprintf(q| %s|, $section->{title}) if $section->{title};
	$pod .= sprintf(qq|\n\n%s|, $section->{content}) if $section->{content};
	return $pod;
}

sub to_string { 
	my ($self, $string) = @_;
	return $_[0]->generate(q|string|) if (!$string);
	$string =~ s/^\n*//g;
	return $string;
}

sub to_file {
	my ($self, $string) = @_;
	return $_[0]->generate(q|file|) if (!$string);
	(my $file = $self->{name}) =~ s/\:\:/\//g;
	$file .= '.pm';
	require $file;
	$file = $INC{$file};
        open my $fh, "<", $file or die "Cannot open file for read/writing $file";
        my $current = do { local $/; <$fh> };
        close $fh;
        die "no \_\_END\_\_ to code bailing on writing to the .pm file" unless $current =~ s/(\_\_END\_\_).*/$1/xmsg;
        $current .= $string;
        open my $wh, ">", $file;
        print $wh $current;
	close $wh;
	return $string;
}

sub to_seperate_file { 
	my ($self, $string) = @_;
	return $_[0]->generate(q|seperate_file|) if (!$string);
	(my $file = $self->{name}) =~ s/\:\:/\//g;
	$file .= '.pm';
	require $file;
	$file = $INC{$file};
       	$file =~ s/pm$/pod/;
	$string =~ s/^\n*//g;
	open my $wh, ">", $file;
        print $wh $string;
	close $wh;
	return $string;
}

sub _last_identifier {
	my $self = shift;
	my ($i, $last_identifier) = -1;
	$self->{pod}->[$i] 
		? $self->{pod}->[$i]->{identifier}
			? do { $last_identifier = $self->{pod}->[$i]->{identifier}; 1 }
			: $i-- 
		: do { $last_identifier = q|none|; }
	while (!$last_identifier);
	return $last_identifier;
}


1;

__END__

=head1 NAME

POD::Generate - programmatically generate plain old documentation

=cut

=head1 VERSION

v0.02

=cut

=head1 SYNOPSIS

	use POD::Generate;
	
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


        =cut

=cut

=head1 DESCRIPTION

This module purpose is to assist with programmatically generating plain old documentation from code.

=cut

=head1 METHODS

=cut

=head2 new

Instantiate a new L<POD::Generate> object. This accepts the following parameters most of which are 
callbacks which are called when you set a specific plain old document command/identifier.

	POD::Generate->new(
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
	);

=cut

=head3 pod

An existing internal pod struct which can either be a hash reference if it's the parent object or an
array ref if it is a child object which relates to a specific single package.

=cut

=head3 p_cb

A callback called each time the p method is called, it should be used to manipulate the data which 
is added to the pod array.

=cut

=head3 h1_cb

A callback called each time the h1 method is called, it should be used to manipulate the data which 
is added to the pod array.

=cut

=head3 h2_cb

A callback called each time the h2 method is called, it should be used to manipulate the data which 
is added to the pod array.

=cut

=head3 h3_cb

A callback called each time the h3 method is called, it should be used to manipulate the data which 
is added to the pod array.

=cut

=head3 h4_cb

A callback called each time the h4 method is called, it should be used to manipulate the data which 
is added to the pod array.

=cut

=head3 item_cb

A callback called each time the item method is called, it should be used to manipulate the data 
which is added to the pod array.

=cut

=head3 versioncb

A callback triggered each time the version method is called, it should be used to manipulate the 
data which is added to the pod array.

=cut

=head3 description_cb

A callback triggered each time the description method is called, it should be used to manipulate the
data which is added to the pod array.

=cut

=head3 synopsis_cb

A callback triggered each time the synopsis method is called, it should be used to manipulate the 
data which is added to the pod array.

=cut

=head3 methods_cb

A callback triggered each time the methods method is called, it should be used to manipulate the 
data which is added to the pod array.

=cut

=head3 exports_cb

A callback triggered each time the exports method is called, it should be used to manipulate the 
data which is added to the pod array.

=cut

=head3 author_cb

A callback triggered each time the author method is called, it should be used to manipulate the data
which is added to the pod array.

=cut

=head3 bugs_cb

A callback triggered each time the bugs method is called, it should be used to manipulate the data 
which is added to the pod array.

=cut

=head3 support_cb

A callback triggered each time the support method is called, it should be used to manipulate the 
data which is added to the pod array.

=cut

=head3 support_items_cb

A callback triggered each time the support method is called, it should be used to manipulate the 
data which is added to the pod array.

=cut

=head3 acknowledgements_cb

A callback triggered each time the acknowledgements method is called, it should be used to 
manipulate the data which is added to the pod array.

=cut

=head3 license_cb

A callback triggered each time the license method is called, it should be used to manipulate the 
data which is added to the pod array.

=cut

=head2 pod

A reference to the internal pod struct which can either be a hash reference if it's the parent 
object or an array reference if it is a child object which relates to a specific single package.

	$pg->pod;

=cut

=head2 start

Start documentation for a new module/package/thing, it is equivalent to calling the ->name. method.

	$pg->start($name, $abbr);

=cut

=head2 end

End the documentation for a new module/package/thing, it is equivalent to calling the ->generate 
method.

	$pg->end($type);

=cut

=head2 name

Start documentation for a new module/package/thing, name accepts two parameteres a name of the thing
and an summary of what the thing does. The summary is prepended to the name in the NAME section of 
the plain old documentation.

	$pg->name($module, $summary)

=cut

=head2 generate

End documentation for a new module/package/thing, generate accepts a single param which is the type 
of generation you would like. Currently there are three options they are string, file and 
seperate_file.

	$pg->generate($type)

=cut

=head2 add

This is a generic method to add a new section to the POD array, many of the following methods are 
just wrappers around this add method. It accepts three parameters the identifier/command, the title 
for the section and the content. All params are optional and undefs can be passed if that is what 
you desire to do.

	$pg->add($identifier, $title, $content)

=cut

=head2 p

Add a new paragraph to the current section, this method will format the text to be fixed width of 
100 characters.

	$pg->p($content)

=cut

=head2 v

Add a new verbose paragraph to the current section, this method does not format the width of the 
content input so will render as passed.

	$pg->v($content)

=cut

=head2 h1

Add a new head1 section.

	$pg->h1($title, $content)

=cut

=head2 h2

Add a new head2 section.

	$pg->h2($title, $content)

=cut

=head2 h3

Add a new head3 section.

	$pg->h3($title, $content)

=cut

=head2 h4

Add a new head4 section.

	$pg->h4($title, $content)

=cut

=head2 item

Add a new item section, this will automatically add the over and back identifiers/commands.

	$pg->item($title, $content)

=cut

=head2 version

Add a new head1 VERSION section.

	$pg->version($content)

=cut

=head2 description

Add a new head1 DESCRIPTION section.

	$pg->item($content)

=cut

=head2 synopsis

Add a new head1 SYNOPSIS section.

	$pg->synopsis($content)

=cut

=head2 methods

Add a new head1 METHODS section.

	$pg->methods($content)

=cut

=head2 exports

Add a new head1 EXPORTS section.

	$pg->exports($content)

=cut

=head2 footer

Add the footer to a module/packages POD, this will call formatted_author, bugs, support, 
acknowledgements and license in that order using there default values or values set in callbacks.

	$pg->footer(
		name => "LNATION",
		email => "email\@lnation.org",
		bugs => "...",
		support => "...",
		support_items => "...",
		acknowledgements => "...",
		license => "...",
	);

=cut

=head2 author

Add a new head1 AUTHOR section.

	$pg->author($content)

=cut

=head2 formatted_author

Add a new head1 AUTHOR section, this accepts two parameters the authors name and the authors email.

	$pg->author($author_name, $author_email)

=cut

=head2 bugs

Add a new head1 BUGS section.

	$pg->bugs($content)

=cut

=head2 support

Add a new head1 SUPPORT section.

	$pg->support($content)

=cut

=head2 acknowledgements

Add a new head1 ACKNOWLEDGEMENTS section.

	$pg->acknowledgements($content)

=cut

=head2 license

Add a new head1 LICENSE section.

	$pg->license($content)

=cut

=head2 to_string

Generate the current plain old documentation using what is stored in the pod attribute and return it
as a string.

	$pg->to_string()

=cut

=head2 to_file

Generate the current plain old documentation using what is stored in the pod attribute and write it 
to the end of the modules file. The module must have an __END__ tag and anything which comes after 
will be re-written.

	$pg->to_file()

=cut

=head2 to_seperate_file

Generate the current plain old documentation using what is stored in the pod attribute and write it 
to a new .pod file for the given named module. Each run this file will be re-written.

	$pg->to_seperate_file()

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=cut

=head1 BUGS

Please report any bugs or feature requests to C<bug-pod-generate at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=POD-Generate>. I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=cut

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc POD::Generate

You can also look for information at:

=over

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=POD-Generate>

=item * Search CPAN

L<https://metacpan.org/release/POD-Generate>

=back

=cut

=head1 ACKNOWLEDGEMENTS

=cut

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 LNATION

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut
