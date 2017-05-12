package Template::Flute::HTML;

use strict;
use warnings;

use Encode;
use Path::Tiny ();
use XML::Twig;
use HTML::Entities;

use Template::Flute::Increment;
use Template::Flute::Container;
use Template::Flute::List;
use Template::Flute::Form;
use Template::Flute::UriAdjust;

use Scalar::Util qw/blessed/;

=head1 NAME

Template::Flute::HTML - HTML Template Parser

=head1 SYNOPSIS

    $html_object = new Template::Flute::HTML;

    $html_object->parse('<div class="example">Hello world</div>');
    $html_object->parse_file($html_file, $spec);

=head1 CONSTRUCTOR

=head2 new

Create a Template::Flute::HTML object.

=cut

# constructor

sub new {
	my ($class, $self);

	$class = shift;

    my %args = @_;

	$self = {%args, containers => {}, lists => {}, pagings => {}, forms => {},
			 params => {}, values => {}, query => {}, file => undef};
	
	bless $self, $class;
}

=head1 METHODS

=head2 containers

Returns list of L<Template::Flute::Container> objects for this template.

=cut

# containers method - return list of Template::Flute::Container objects for this# template

sub containers {
	my ($self) = @_;

	return values %{$self->{containers}};
}

=head2 container NAME

Returns container object named NAME.

=cut

sub container {
	my ($self, $name) = @_;

	if (exists $self->{containers}->{$name}) {
		return $self->{containers}->{$name};
	}
}

=head2 lists

Returns list of L<Template::Flute::List> objects for this template.

=cut

sub lists {
	my ($self) = @_;

	return values %{$self->{lists}};
}

=head2 list NAME

Returns list object named NAME.

=cut

# list method - returns specific list object
sub list {
	my ($self, $name) = @_;

	if (exists $self->{lists}->{$name}) {
		return $self->{lists}->{$name};
	}
}

=head2 forms

Returns list of L<Template::Flute::Form> objects for this template.

=cut

sub forms {
	my ($self) = @_;

	return values %{$self->{forms}};
}

=head2 form NAME

Returns form object named NAME.

=cut

# form method - returns specific form object
sub form {
	my ($self, $name) = @_;

	if (exists $self->{forms}->{$name}) {
		return $self->{forms}->{$name};
	}
}

=head2 values

Returns list of values for this template.

=cut

sub values {
	my ($self) = @_;

	return values %{$self->{values}};
}

=head2 iterators

Returns hash with iterator names as keys and iterator objects
as values.

=cut

sub iterators {
	my ($self) = @_;
	my (%iterators, $name, $object);

	for my $list (CORE::values %{$self->{lists}}) {
		$name = $list->iterator('name');
		next unless $name;
		$iterators{$name} = $list->iterator();
	}

	wantarray ? %iterators : \%iterators;
}

=head2 root

Returns root of HTML/XML tree.

=cut

# root method - returns root of HTML/XML tree
sub root {
	my ($self) = @_;

	return $self->{xml}->root();
}

=head2 translate I18NOBJECT

Localizes static text inside the HTML template through
the I18NOBJECT.

=cut

sub _translate_string {
    my ($self, $i18n, $text) = @_;

    # remove surrounding whitespace before passing
    # to translation function
    my ($ws_before, $ws_after);
    if ($text =~ s/^(\s+)//s) {
        $ws_before = $1;
    }
    else {
        $ws_before = '';
    }

    if ($text =~ s/(\s+)$//s) {
        $ws_after = $1;
    }
    else {
        $ws_after = '';
    }
    # return undef if no text is left
    return unless length($text);

    # collapse the whitespace inside, discarding it for the
    # purpose of localization.
    my $original = $text;
    $text =~ s/\s+/ /g;
    my $translated = $i18n->localize($text);
    if ($translated eq $text) {
        $text = $original;
    }
    else {
        $text = $translated;
    }
    # translate and restore spaces
    return $ws_before . $text . $ws_after;
}

sub _translate_attribute {
    my ($self, $i18n, $elt, $attribute) = @_;
    die unless ($i18n && $elt && $attribute);
    # here the i18n-key doesn't make sense, because we can't know
    # exactly which attribute has to be translated.

    if (my $string = $elt->att($attribute)) {
        my $translated = $self->_translate_string($i18n, $string);
        if (defined $translated) {
            $elt->set_att($attribute, $translated);
        }
    }
}


sub translate {
	my ($self, $i18n, @translate_attributes) = @_;
	my ($root, @text_elts, $i18n_ret, $parent_gi, $parent_i18n,
	    %parents, $text, $ws_before, $ws_after);

	$root = $self->root();

	@text_elts = $root->descendants('#TEXT');

	for my $elt (@text_elts) {
		$parent_gi = $elt->parent->gi();
        my %exclude = (
                       style => 1,
                       script => 1,
                       textarea => 1,
                      );
        next if $exclude{$parent_gi};
        
		$parent_i18n = $elt->parent->att('i18n-key');
		
		if ($parent_i18n) {
			$i18n_ret = $i18n->localize($parent_i18n);
		}
		else {
            $text = $elt->text;
            $i18n_ret = $self->_translate_string($i18n, $text);
            next unless defined $i18n_ret;
		}

		$elt->set_text($i18n_ret);
	}

    foreach my $attr (@translate_attributes) {
        if ($attr =~ m/\./) {
            my ($tag, $el_att, %conditions) = split(/\./, $attr);
            if ($tag && $el_att) {
                my $xpath = $tag . '[@' . $el_att . ']';
                my @elements = $root->descendants($xpath);
              TRX_ATT_EL:
                foreach my $el (@elements) {
                    foreach my $att_cond (keys %conditions) {
                        my $cond_val = $conditions{$att_cond};
                        die "undefined condition on translate attribute $attr"
                          unless defined $cond_val;
                        my $el_val = $el->att($att_cond);
                        next TRX_ATT_EL unless defined $el_val;
                        next TRX_ATT_EL unless $el_val eq $cond_val;
                    }
                    # still here? good.
                    $self->_translate_attribute($i18n, $el, $el_att);
                }
            }
            else {
                die "Invalid translate_attributes configuration: $attr";
            }
        }
        else {
            my @elements = $root->descendants('*[@'. $attr . ']');
            foreach my $el (@elements) {
                $self->_translate_attribute($i18n, $el, $attr);
            }
        }
    }

	# cleanup
	if ($self->{_i18n_key_elts}) {
	    for my $elt (@{$self->{_i18n_key_elts}}) {
		$elt->del_att('i18n-key');
	    }

	    delete $self->{_i18n_key_elts};
	}

	return;
}

=head2 file

Returns name of template file.

=cut

sub file {
	my $self = shift;
	
	return $self->{file};
}

=head2 parse [ STRING | SCALARREF ] SPECOBJECT

Parses HTML template from STRING or SCALARREF with the help
of a L<Template::Flute::Specification> object SPECOBJECT.

=cut

sub parse {
	my ($self, $template, $spec_object, $snippet) = @_;
	my ($object);
	
	if (ref($template) eq 'SCALAR') {
		$object = $self->_parse_template($template, $spec_object, $snippet);
	}
	else {
		$object = $self->_parse_template(\$template, $spec_object, $snippet);
	}

	return $object;
}

=head2 parse_file FILENAME SPECOBJECT

Parses HTML template from file FILENAME with the help
of a L<Template::Flute::Specification> object SPECOBJECT.

=cut
	
sub parse_file {
	my ($self, $template_file, $spec_object, $snippet) = @_;

	return $self->_parse_template($template_file, $spec_object, $snippet);
}

sub _parse_template {
	my ($self, $template, $spec_object, $snippet) = @_;
	my ($twig, %twig_args, $xml, $object, $list, $html_content, $encoding);

	$object = {specs => {}, lists => {}, forms => {}, params => {}};
		
	%twig_args = (twig_handlers => {_all_ => sub {$self->_parse_handler($_[1], $spec_object)}});

	if ($XML::Twig::VERSION > 3.39) {
	    $twig_args{output_html_doctype} = 1;
	}
	
	$twig = new XML::Twig (%twig_args);

	if (ref($template) eq 'SCALAR') {
		$self->{file} = '';
		$html_content = decode_entities($$template);
	}
	else {
		$self->{file} = $template;
		$encoding = $spec_object->encoding();
		$html_content = Path::Tiny::path($template)->slurp({binmode => ":encoding($encoding)"});
        my $first_char = substr($html_content, 0, 1);
        if ($first_char eq "\x{feff}") {
            substr($html_content, 0, 1, '');
        }
		unless ($encoding eq 'utf8') {
			$html_content = encode('utf8', $html_content);
		}
	}
	$xml = $snippet ? $twig->safe_parse($html_content) : $twig->safe_parse_html($html_content);

	unless ($xml) {
        my $failure = '';
        if ($@ =~ /, byte ([0-9]+) at/) {
            $failure = '...' . substr($html_content, $1, 50) . '...';
        }
		die "Invalid HTML template: $html_content: $@ $failure\n";
	}
	
        _fix_script_tags($xml);

	$self->{xml} = $object->{xml} = $xml;

	return $object;
}

# parse_handler - Callback for HTML elements

sub _parse_handler {
	my ($self, $elt, $spec_object) = @_;
	my ($gi, @classes, @static_classes, $class_names, $id, $elt_name, $name, $sob, $sob_ref);

	$gi = $elt->gi();
	$class_names = $elt->class();
	$id = $elt->id();
	$elt_name = $elt->att('name');

    if ($self->{uri}) {
        my %targets = (a => {link_att => 'href'},
                       base => {link_att => 'href'},
                       img => {link_att => 'src'},
                       link => {link_att => 'href'},
                       script => {link_att => 'src'},
                       form => {link_att => 'action'},
                   );

        # adjust links to static files
        if (exists $targets{$gi}) {
            my $link_att = $targets{$gi}->{link_att};
	    my $link_value = $elt->att($link_att);
	    my $uri_adjust;

	    if (defined $link_value) {
		$uri_adjust = Template::Flute::UriAdjust->new(uri => $link_value,
							      adjust => $self->{uri},
		    );

		if (my $result = $uri_adjust->result) {
		    $elt->set_att($link_att, $result);
		}
	    }
        }
    }
	# don't act on elements without class, id or name attribute
	return unless $class_names || $id || $elt_name;
	
	# weed out "static" classes
	if ($class_names) {
		for my $class (split(/\s+/, $class_names)) {
			if ($spec_object->elements_by_class($class)) {
				push @classes, $class;
			}
			else {
				push @static_classes, $class;
			}
		}
	}
	
	if ($id) {
        $sob_ref = $spec_object->elements_by_id($id);
        for my $sob (@$sob_ref) {
			$name = $sob->{name} || $id;
			$self->_elt_handler($sob, $elt, $gi, $spec_object, $name);
		}
	}

	if ($elt_name) {
	    $sob_ref = $spec_object->elements_by_name($elt_name);
	
	    for my $sob (@$sob_ref) {
		$name = $sob->{name} || $elt_name;
		$self->_elt_handler($sob, $elt, $gi, $spec_object, $name);
	    }
	}
	
	for my $class (@classes) {
		$sob_ref = $spec_object->elements_by_class($class);
		for my $sob (@$sob_ref) {
			$name = $sob->{name} || $class;
			$self->_elt_handler($sob, $elt, $gi, $spec_object, $name, \@static_classes);
		}
	}

	return $self;
}

sub _elt_handler {
	my ($self, $sob, $elt, $gi, $spec_object, $name, $static_classes) = @_;

	if ($sob->{type} eq 'container') {
	    if (exists $self->{containers}->{$name}) {
		push @{$self->{containers}->{$name}->{sob}->{elts}}, $elt;
	    }
	    else {
		$sob->{elts} = [$elt];
		$self->{containers}->{$name} = new Template::Flute::Container ($sob, $spec_object, $name);
	    }

	    return $self;
	}
	
	if ($sob->{type} eq 'list') {
		my $iter;
		
		if (exists $self->{lists}->{$name}) {
		    # record static classes
		    my ($list, $first_static, $first_classes);
		    
		    $list = $self->{lists}->{$name};

		    if ($first_static = $list->static_class(0)) {
			# remove static class from initial list element
			$first_classes = $list->elt->att('class');
			#$first_classes =~ s/\s*\b$first_static\b//;
			$list->elt->set_att('class', $first_classes);
		    }

		    $list->set_static_class(@$static_classes);
				
		    # discard repeated lists
		    $elt->cut();
		    return;
		}
			
		$sob->{elts} = [$elt];

		# weed out parameters which aren't descendants of list element
		for my $p (@{$self->{params}->{$name}->{array}}) {
			my @p_new;
			
			for my $p_elt (@{$p->{elts}}) {
				for my $a ($p_elt->ancestors()) {
					if ($a eq $elt) {
						push (@p_new, $p_elt);
						last;
					}
				}
			}

			$p->{elts} = \@p_new;
		}
		
		$self->{lists}->{$name} = new Template::Flute::List ($sob, [join(' ', @$static_classes)], $spec_object, $name);
		$self->{lists}->{$name}->params_add($self->{params}->{$name}->{array});
        $self->{lists}->{$name}->paging_add($self->{paging}->{$name});
		$self->{lists}->{$name}->separators_add($self->{separators}->{$name}->{array});
		$self->{lists}->{$name}->increments_add($self->{increments}->{$name}->{array});
			
		if (exists $sob->{iterator}) {
			if ($iter = $spec_object->iterator($sob->{iterator})) {
				$self->{lists}->{$name}->set_iterator($iter);
			}
		}

		if (exists $sob->{filter}) {
			$self->{lists}->{$name}->set_filter($sob->{filter});
		}
		
		return $self;
	}

	if ($sob->{type} eq 'separator') {
		push (@{$sob->{elts}}, $elt);
		$self->_elt_indicate_replacements($sob, $elt, $gi, $name, $spec_object);

		if (exists $self->{lists}->{$sob->{list}}) {
		    $self->{lists}->{$sob->{list}}->separators_add([$sob]);
		}
		else {
		    $self->{separators}->{$sob->{list}}->{hash}->{$name} = $sob;
		    push(@{$self->{separators}->{$sob->{list}}->{array}}, $sob);
		}
	}
    elsif ($sob->{type} eq 'paging') {
        # go through paging elements and record corresponding HTML elements
        for my $element_ref (CORE::values %{$sob->{elements}}) {
            if (exists $self->{paging_elements}->{$name}->{$element_ref->{type}}) {
                $element_ref->{elts} = $self->{paging_elements}->{$name}->{$element_ref->{type}}->{elts};
            }
        }

        push (@{$sob->{elts}}, $elt);
		$self->_elt_indicate_replacements($sob, $elt, $gi, $name, $spec_object);

        if (exists $self->{lists}->{$sob->{list}}) {
            $self->{lists}->{$sob->{list}}->paging_add($sob);
        }
        else {
		    $self->{paging}->{$sob->{list}} = $sob;
        }
    }
    
	if ($sob->{type} eq 'form') {
        # only HTML <form> elements can be tied to 'form'
        return $self if $elt->tag ne 'form';

		$sob->{elts} = [$elt];

		$self->{forms}->{$name} = new Template::Flute::Form ($sob);

		$self->{forms}->{$name}->fields_add($self->{fields}->{$name}->{array});
		$self->{forms}->{$name}->params_add($self->{params}->{$name}->{array});
			
		$self->{forms}->{$name}->inputs_add($spec_object->form_inputs($name));
			
		return $self;
	}
	
	if ($sob->{type} eq 'param') {
		push (@{$sob->{elts}}, $elt);

		$self->_elt_indicate_replacements($sob, $elt, $gi, $name, $spec_object);

		if ($sob->{increment}) {
			# create increment object and record it for increment updates
			my $inc = new Template::Flute::Increment (increment => $sob->{increment});
			
			$sob->{increment} = $inc;
			push(@{$self->{increments}->{$sob->{list}}->{array}}, $inc);
		}

		$self->{params}->{$sob->{list} || $sob->{form}}->{hash}->{$name} = $sob;
		push(@{$self->{params}->{$sob->{list} || $sob->{form}}->{array}}, $sob);
    } elsif ($sob->{type} eq 'element') {
        push (@{$sob->{elts}}, $elt);
		$self->_elt_indicate_replacements($sob, $elt, $gi, $name, $spec_object);
        $self->{paging_elements}->{$sob->{paging}}->{$sob->{element_type}} = $sob;
	} elsif ($sob->{type} eq 'value') {
		push (@{$sob->{elts}}, $elt);

		$self->_elt_indicate_replacements($sob, $elt, $gi, $name, $spec_object);
		
		$self->{values}->{$name} = $sob;
	} elsif ($sob->{type} eq 'field') {
         # HTML <form> elements can't be tied to 'field'
        return $self if $elt->tag eq 'form';
        
		# match for form field found in HTML
		push (@{$sob->{elts}}, $elt);

		if ($gi eq 'select') {
			if ($sob->{iterator}) {
				$elt->{"flute_$name"}->{rep_sub} = sub {
					_set_selected($_[0], $_[1],
								 $spec_object->resolve_iterator($sob->{iterator}),
								 $sob,
								 );
				};
			}
			else {
				$elt->{"flute_$name"}->{rep_sub} = \&_set_selected;
			}
		}
		push(@{$self->{fields}->{$sob->{form}}->{array}}, $sob);
	} elsif ($sob->{type} eq 'i18n') {

		$elt->set_att('i18n-key', $sob->{'key'});
		push(@{$self->{_i18n_key_elts}}, $elt);
	} else {
		return $self;
	}
}

# _elt_indicate_replacements - indicate location of replacements

sub _elt_indicate_replacements {
	my ($self, $sob, $elt, $gi, $name, $spec_object) = @_;
	my ($elt_text, $att_orig);
    
	if (exists $sob->{op}) {
		if ($sob->{op} eq 'hook') {
			$elt->{"flute_$name"}->{rep_sub} = \&hook_html;
			return;
		}
        elsif (($sob->{op} eq 'prepend' || $sob->{op} eq 'append') && ! $sob->{target}) {
            $elt->{"flute_$name"}->{rep_text_orig} = $elt->text_only;
            my $joiner = '';
            if (exists $sob->{joiner}) {
                $joiner = $sob->{joiner};
            }
            if ($sob->{op} eq 'append') {
                $elt->{"flute_$name"}->{rep_sub} = sub {
                    my ($elt, $str) = @_;
                    $str ||= '';
                    if (! $joiner || $str =~ /\S/) {
                        $elt->set_text($elt->{"flute_$name"}->{rep_text_orig} . $joiner . $str);
                    }
                };
            }
            else {
                $elt->{"flute_$name"}->{rep_sub} = sub {
                    my ($elt, $str) = @_;
                    $str ||= '';
                    if (! $joiner || $str =~ /\S/) {
                        $elt->set_text($str . $joiner . $elt->{"flute_$name"}->{rep_text_orig});
                    }
                };
             };
        }
        elsif ($sob->{op} eq 'toggle' && exists $sob->{args}
               && $sob->{args} eq 'tree') {
            $elt->{"flute_$name"}->{rep_sub} = sub {
                my ($elt, $value) = @_;
                unless (defined $value && $value =~ /\S/) {
                    $elt->cut;
                }

                return;
            };
        }
        elsif ($sob->{op} eq 'keep') {
            $elt->{"flute_$name"}->{rep_sub} = \&_keep;
        }
	}

	if ($sob->{target}) {
		if (exists $sob->{op}) {
			if ($sob->{op} eq 'append' || $sob->{op} eq 'prepend') {
				# keep original values around. The target could be a
				# wildcard.
				foreach my $attribute (keys %{ $elt->atts }) {
					my $att_orig = $elt->att($attribute);
					unless (defined $att_orig) {
						$att_orig = '';
					}
					$elt->{"flute_$name"}->{rep_att_orig}->{$attribute} = $att_orig;
				}
			}
		}
			
		$elt->{"flute_$name"}->{rep_att} = $sob->{target};
	} elsif ($gi eq 'img') {
		# replace src attribute instead of text
		$elt->{"flute_$name"}->{rep_att} = 'src';
	} elsif ($gi eq 'input') {
		my $type = $elt->att('type');
		# replace value attribute instead of text
		$elt->{"flute_$name"}->{rep_att} = 'value';
			
	} elsif ($gi eq 'select') {
		if ($sob->{iterator}) {
			$elt->{"flute_$name"}->{rep_sub} = sub {
				_set_selected($_[0], $_[1],
							  $spec_object->resolve_iterator($sob->{iterator}),
							  $sob,
							 );
			};
		} else {
			$elt->{"flute_$name"}->{rep_sub} = \&_set_selected;
		}
	} elsif (! $elt->contains_only_text()) {
		# contains real elements, so we have to be careful with
		# set text and apply it only to the first PCDATA element
		if ($elt_text = $elt->first_descendant('#PCDATA')) {
			$elt->{"flute_$name"}->{rep_elt} = $elt_text;
		}
	}
}

# _set_selected - Set selected value in a dropdown menu

sub _set_selected {
	my ($elt, $value, $iter, $sob) = @_;
	my (@children, $eltval, $optref, $cond);

	@children = $elt->children('option');
	
	if ($iter) {
		# remove existing children
		if (exists $sob->{keep} && $sob->{keep} eq 'empty_value') {
			$cond = 'option[@value=~/\S/]';
		}
		else {
			$cond = '';
		}
		
		$elt->cut_children($cond);

		if (! $value) {
            # check whether there is a default in the specification
            if (exists $sob->{iterator_default} && $sob->{iterator_default}) {
                $value = $sob->{iterator_default};
            }
        }

        # determine where to look for labels and values in the iterator
        my $value_k = "value";
        my $label_k = "label";
        if (exists $sob->{iterator_value_key} && $sob->{iterator_value_key}) {
            $value_k = $sob->{iterator_value_key};
        }
        if (exists $sob->{iterator_name_key} && $sob->{iterator_name_key}) {
            $label_k = $sob->{iterator_name_key};
        }

		# get options from iterator		
		$iter->reset();
		while ($optref = $iter->next()) {

            # check the record if is an object
            my $is_an_object = blessed($optref);

			my (%att, $text);
            my ($record_value, $record_label);

            if ($is_an_object) {
                # here we could also peek inside the object, but hey,
                # if it's an object the correct practise is not to
                # look inside it.
                if ($optref->can("$value_k")) {
                    $record_value = $optref->$value_k;
                }
                if ($optref->can("$label_k")) {
                    $record_label = $optref->$label_k;
                }
            }
            else {
                if (exists $optref->{$value_k}) {
                    $record_value = $optref->{$value_k};
                }
                if (exists $optref->{$label_k}) {
                    $record_label = $optref->{$label_k};
                }
            }

            if (defined $record_label) {
                $text = $record_label;
                $att{value} = $record_value;
            }
            else {
                $text = $record_value;
            }
            if (defined $value and
                defined $record_value) {
                if (ref($value) eq 'ARRAY') {
                    $att{selected} = 'selected' if grep { $record_value eq $_ } @$value;
                }
                elsif ($record_value eq $value) {
                    $att{selected} = 'selected';
                }
            }
			
			$elt->insert_new_elt('last_child', 'option',
									 \%att, $text);
		}

        # reset iterator in case we use it multiple times
        $iter->reset;
	}
	else {
		for my $node (@children) {
			$eltval = $node->att('value');

			unless (length($eltval)) {
				$eltval = $node->text();
			}
		
			if ($eltval eq $value) {
				$node->set_att('selected', 'selected');
			}
			else {
				$node->del_att('selected', '');
			}
		}
	}
}

=head2 hook_html ELT VALUE

Parse HTML provided by VALUE and replace any children of ELT
with the result.

=cut
	
sub hook_html {
	my ($elt, $value) = @_;
	my ($parser, $html, $body, @children, @ret, $elt_hook);

	unless (defined $value && $value =~ /\S/) {
        $elt->cut_children;
		return '';
	}
	
	$parser = new XML::Twig ();
	unless ($html = $parser->safe_parse_html($value)) {
        my $failure = '';
        if ($@ =~ /, byte ([0-9]+) at/) {
            $failure = '...' . substr($value, $1, 40)
              . '...';
        }
		die "Failed to parse HTML snippet: $@. $failure\n";
	}
        _fix_script_tags($html);

	$elt->cut_children();

    if (my $head_elt = $html->root->first_child('head')) {
        # preserve useful elements like <script> inside HTML snippets (GH #99).
        @children = $head_elt->cut_children;
        for my $h_elt (@children) {
            $h_elt->paste(last_child => $elt);
        }
    }

    my $fc = $html->root()->first_child('body');

    if ($elt->gi eq 'select' && $fc->first_child->gi eq 'select') {
        $fc = $fc->first_child;
    }

    @children = $fc->cut_children();

	for my $elt_hook (@children) {
		$elt_hook->paste(last_child => $elt);
	}
	
	return;
}

sub _keep {
    my ($elt, $value) = @_;

    if ($value) {
        $elt->set_text($value);
    }

    return;
}

sub _fix_script_tags {
    my $parsed = shift;
    # script tags should not be escaped. Please note that this should
    # be safe. It affects only the *content* of the <script> tags. If
    # your values contains injected JS, having the & escaped as &amp;
    # or > as &gt; will not save you.
    my @elts = $parsed->get_xpath('//script');
    foreach my $el (@elts) {
        $el->set_asis;
    }
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

