package Mojo::DOM::Role::Restrict;
use strict; use warnings; our $VERSION = 0.05;
use Mojo::Base -role;
use Mojo::Util qw(xml_escape);
use File::Spec;

sub to_string { $_[1] ? ${$_[0]}->render : $_[0]->render; }

sub render { _render($_[0]->tree, $_[0]->xml, $_[0]->restrict_spec) }

around parse => sub {
	my ($orig, $self) = (shift, shift);
	$self->restrict_spec($_[1] || $self->restrict_spec || {
		'*' => { '*' => 1 }
	});
	return $self->$orig(@_);
};

sub restrict_spec {
	if ( $_[1] ) {
		$_[1]->{$_} && ! ref $_[1]->{$_} && do { $_[1]->{$_} = { '*' => 1 } } for (keys %{$_[1]});
		${$_[0]}->{restrict_spec} = $_[1];
	}
	${$_[0]}->{restrict_spec};
}

sub valid { _valid($_[0]->tree, $_[0]->restrict_spec($_[1])) }

sub restrict { _restrict($_[0]->tree, $_[0]->restrict_spec($_[1])) && $_[0] }

sub diff_module {
	if ( $_[1] && $_[0]->diff_module_name !~ $_[1]) {
		$_[0]->diff_module_name($_[1]);
		$_[0]->diff_module_loaded(0);
	}
	$_[0]->diff_module_method($_[2]) if $_[2];
	$_[0]->diff_module_params($_[3]) if defined $_[3];
	return (
		$_[0]->diff_module_name,
		$_[0]->diff_module_method,
		$_[0]->diff_module_params
	);
}

has diff_module_name => 'Text::Diff';

has diff_module_loaded => 0;

has diff_module_method => 'diff';

has diff_module_params => sub {  { style => 'Unified' } };

sub diff {
	my ($self, $spec) = ($_[0], (shift)->restrict_spec(shift));
	my ($module, $method, $params) = $self->diff_module(@_);
	unless ( $self->diff_module_loaded ) {
		my @parts = split /::|'/, $module, -1;
    		shift @parts if @parts && !$parts[0];
    		my $file  =  File::Spec->catfile( @parts );
		LOAD_DIFF_MODULE: {
		    my $err;
		    for my $flag ( qw[1 0] ) {
			my $load = $file . ($flag ? '.pm' : '');
			eval { require $load };
			$@ ? $err .= $@ : last LOAD_DIFF_MODULE;
		    }
		    die $err if $err;
		}
		$self->diff_module_loaded(1)
	}
	{
		no strict 'refs';
		return *{"${module}::${method}"}->(\$self->to_string(1), \$self->to_string(), $params);
	}
}

# copy, paste and edit via Mojo::DOM::HTML::_render

my %EMPTY = map { $_ => 1 } qw(area base br col embed hr img input keygen link menuitem meta param source track wbr);

sub _render {
	my ($tree, $xml, $spec) = @_;
	
	# Tag
	my $type = $tree->[0];
	if ($type eq 'tag') {

		# Start tag
		my ($tag, $attrs) = _valid_tag($spec, $tree->[1], {%{$tree->[2]}});
		
		return '' unless $tag;
	
		my $result = "<$tag";

		# Attributes
		for (sort keys %{$attrs}) {
			my ($key, $value) = _valid_attribute($spec, $tag, $_, $attrs->{$_});
			$result .= defined $value 
				? qq{ $key="} . xml_escape($value) . '"'
				: $xml 
					? qq{ $key="$key"} 
					: " $key"
			if $key;
		}

		# No children
		return $xml ? "$result />" : $EMPTY{$tag} ? "$result>" : "$result></$tag>" unless $tree->[4];

		# Children
		no warnings 'recursion';
		$result .= '>' . join '', map { _render($_, $xml, $spec) } @$tree[4 .. $#$tree];

		# End tag
		return "$result</$tag>";
	}

	# Text (escaped)
	return xml_escape $tree->[1] if $type eq 'text';

	# Raw text
	return $tree->[1] if $type eq 'raw';

	# Root
	return join '', map { _render($_, $xml, $spec) } @$tree[1 .. $#$tree] if $type eq 'root';

	# DOCTYPE
	return '<!DOCTYPE' . $tree->[1] . '>' if $type eq 'doctype';

	# Comment
	return '<!--' . $tree->[1] . '-->' if $type eq 'comment';

	# CDATA
	return '<![CDATA[' . $tree->[1] . ']]>' if $type eq 'cdata';

	# Processing instruction
	return '<?' . $tree->[1] . '?>' if $type eq 'pi';

	# Everything else
	return '';
}

sub _valid_tag {
	my ($spec, $tag, $attrs) = @_;
	my $valid = $spec->{$tag} // $spec->{'*'};
	return ref $valid && $valid->{validate_tag} 
		? $valid->{validate_tag}($tag, $attrs)
		: $valid
			? ($tag, $attrs)
			: 0;
}

sub _valid_attribute {
	my ($spec, $tag, $attr, $value) = @_;
	my $valid = $spec->{$tag}->{$attr} // $spec->{$tag}->{'*'} // $spec->{'*'}->{$attr} // $spec->{'*'}->{'*'};
	return ref $valid 
		? $valid->($attr, $value) 
		: ($valid and $valid =~ m/1/ || $value =~ m/$valid/) 
			? ( $attr, $value ) 
			: 0;
}

sub _valid {
	my ($tree, $spec) = @_;
	if ($tree->[0] eq 'tag') {
		my ($tag, $attrs) = _valid_tag($spec, $tree->[1], {%{$tree->[2]}});
		return 0 unless $tag;
		_valid_attribute($spec, $tag, $_, $attrs->{$_}) or return 0
			for (sort keys %{$attrs});
		if ($tree->[4]) {
			_valid($_, $spec) or return 0 for ( @$tree[4 .. $#$tree]  );
		}
	} elsif ($tree->[0] eq 'root') {
		_valid($_, $spec) or return 0 for ( @$tree[1 .. $#$tree] );
	}
	return 1;
}

sub _restrict {
	my ($tree, $spec) = @_;
	if ($tree->[0] eq 'tag') {
		my ($tag, $attrs) = _valid_tag($spec, $tree->[1], $tree->[2]);
		return 0 unless $tag;
		$tree->[1] = $tag;
		for (sort keys %{$attrs}) {
			my ($key, $value) = _valid_attribute($spec, $tag, $_, delete $attrs->{$_});
			$attrs->{$key} = $value if $key;
		}
		if ($tree->[4]) {
			my $i = 4;
			_restrict($_, $spec) ? $i++ : splice(@{$tree}, $i, 1) 
				for ( @$tree[$i .. $#$tree]  );
		}
	} elsif ($tree->[0] eq 'root') {
		my $i = 1;
		_restrict($_, $spec) ? $i++ : splice(@{$tree}, $i, 1)  
			for ( @$tree[$i .. $#$tree] );
	}
	return 1;
}


1;

# TODO pretty print (for diff) and minmize.

__END__

=encoding UTF-8

=head1 NAME

Mojo::DOM::Role::Restrict - Restrict tags and attributes

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

	use Mojo::DOM;

	my $html = q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|;

	my $spec = {
		script => 0, # remove all script tags
		'*' => { # apply to all tags
			'*' => 1, # allow all attributes by default
			'onclick' => 0 # disable onclick attributes
		},
		span => {
			class => 0 # disable class attributes on span's
		}
	};

	#<html><head></head><body><p class="okay" id="allow">Restrict <span>HTML</span></p></body></html>
	print Mojo::DOM->with_roles('+Restrict')->new($html, $spec);

	.....

	my $dom = Mojo::DOM->with_roles('+Restrict')->new;

	my $html = q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|;

	my $spec = {
		script => 0, # no script tags
		'*' => { # allow all tags
			'*' => 1, # allow all attributes
			onclick => sub { 0 }, # disable onclick attributes
			id => sub { return @_ }, # enable id attributes
			class => sub { # allow only 1 class 'okay'
				my ($attr, $val) = @_;
				my $match = $val =~ m/^okay$/;
				return $match ? ($attr, $val) : 0;
			}
		},
		span => {
			validate_tag => sub { # replace span tags with b tags
				return ('b', $_[1]);
			}
		},
		p => {
			validate_tag => sub {
				$_[1]->{id} = "prefixed-" . $_[1]->{id}; # prefix all p tag IDs
				$_[1]->{'data-unknown'} = 'abc';  # extend all p tags with a data-unknown attribute
				return @_;
			}
		},
	};
	
	$dom->parse($html, $spec);
	
	# <html><head></head><body><p class="okay" data-unknown="abc" id="prefixed-allow">Restrict <b>HTML</b></p></body></html>
	$dom->to_string;

	# you can change the spec and then re-render
	$spec = {
		'*' => { # allow all tags
			'*' => '^not', # where any attr value matches the regex
		},
	};

	$dom->restrict_spec($spec);
	
	# <html><head><script>...</script></head><body><p onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>
	$dom->to_string;

	# check whether the spec is valid
	$dom->valid; # 0

	# apply spec changess to the Mojo::DOM object
	$dom->restrict;

	# re-check whether the spec is valid
	$dom->valid; # 1

	# render using original render function (Mojo::DOM::HTML::render)
	# <html><head><script>...</script></head><body><p onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>
	$dom->to_string(1);

	$dom->parse(q|<p class="okay" data-unknown="abc" id="prefixed-allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p>|);

	# <p onclick="not-allow">Restrict <span class="not-okay">HTML</span></p>
	$dom->to_string;


=head1 SUBROUTINES/METHODS

=head2 restrict_spec

Retrieve/Set the specification used to restrict the HTML.

	my $spec = $self->restrict_spec;

	$dom->restrict_spec($spec);

=cut

=head2 valid

Validate the current DOM against the specification. Returns true(1) if valud returns false(0) if invalid.

	my $html = q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|;

	my $spec = {
		html => 1,
		head => 1,
		script => 1,
		body => 1,
		p => 1,
		span => 1
	};

	my $dom = Mojo::DOM->with_roles('+Restrict')->new($html, $spec); 

	$dom->valid; # 1;

	$spec = {
		html => 1,
		head => 1,
		script => 1,
		body => 1,
		p => 1,
		span => 0
	};

	$dom->valid($spec); # 0;

=cut

=head2 restrict 

Restrict the current DOM against the specification, after calling restrict the specification changes applied become irreversible.

	my $html = q|<html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>|;

	my $spec = {
		script => 0, # no script tags
		'*' => { # allow all tags
			'*' => 1, # allow all attributes
			onclick => sub { 0 }, # disable onclick attributes
			id => sub { return @_ }, # enable id attributes
			class => sub { # allow only 1 class 'okay'
				my ($attr, $val) = @_;
				my $match = $val =~ m/^okay$/;
				return $match ? ($attr, $val) : 0;
			}
		},
		span => {
			validate_tag => sub { # replace span tags with b tags
				return ('b', $_[1]);
			}
		},
		p => {
			validate_tag => sub {
				$_[1]->{id} = "prefixed-" . $_[1]->{id}; # prefix all p tag IDs
				$_[1]->{'data-unknown'} = 'abc';  # extend all p tags with a data-unknown attribute
				return @_;
			}
		},
	};
	
	$dom->parse($html, $spec);

	# render without spec validation
	# <html><head><script>...</script></head><body><p class="okay" id="allow" onclick="not-allow">Restrict <span class="not-okay">HTML</span></p></body></html>
	$dom->to_string(1);
	
	# restrict the DOM
	$dom->restrict;
	
	# render without spec validation
	# <html><head></head><body><p class="okay" data-unknown="abc" id="prefixed-allow">Restrict <b>HTML</b></p></body></html>
	$dom->to_string(1);

=cut

=head2 diff

Perform a diff comparing the original HTML and the restricted HTML.

	my $html = q|<html>
		<head>
			<script>...</script>
		</head>
		<body>
			<p class="okay" id="allow" onclick="not-allow">
				Restrict
				<span class="not-okay">HTML</span>
			</p>
		</body>
	</html>|;

	my $spec = {
		script => 0, # remove all script tags
		'*' => { # apply to all tags
			'*' => 1, # allow all attributes by default
			'onclick' => 0 # disable onclick attributes
		},
		span => {
			class => 0 # disable class attributes on span's
		}
	};

	my $dom = Mojo::DOM->with_roles('+Restrict')->new($html, $spec); 

	#@@ -1,11 +1,11 @@
	# <html>
	#	<head>
	#-		<script>...</script>
	#+		
	#	</head>
	#	<body>
	#-		<p class="okay" id="allow" onclick="not-allow">
	#+		<p class="okay" id="allow">
	#			Restrict
	#-			<span class="not-okay">HTML</span>
	#+			<span>HTML</span>
	#		</p>
	#	</body>
	# </html>
	#\\ No newline at end of file
	my $diff = $dom->diff;

	....

	$dom->diff($spec, 'Text::Diff', 'diff', { style => 'Unified' });

=cut

=head2 diff_module

Configure the module used to perform the diff. The default is Text::Diff::diff.

	$dom->diff_module('Text::Diff', 'diff', { style => 'Unified' });

=cut

=head2 diff_module_name

Get or Set the diff module. The default is Text::Diff.

	$dom->diff_module_name('Text::Diff');

=cut

=head2 diff_module_method

Get or Set the diff module method. The default is diff.

	$dom->diff_module_method('diff');

=cut

=head2 diff_module_params

Get or Set the diff module params that are passed as the third argument when calling the diff_module_method. The default is { style => 'Unified' }.

	$dom->diff_module_method({ style => 'Unified' });

=cut

=head2 diff_module_loaded

Get or Set whether the diff module needs to be loaded. If false the next time the diff method is called on the Mojo::DOM object the module will be required. 

	$dom->diff_module_loaded(1|0);

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojo-dom-role-restrict at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojo-DOM-Role-Restrict>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojo::DOM::Role::Restrict

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojo-DOM-Role-Restrict>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Mojo-DOM-Role-Restrict>

=item * Search CPAN

L<https://metacpan.org/release/Mojo-DOM-Role-Restrict>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Mojo::DOM::Role::Restrict
