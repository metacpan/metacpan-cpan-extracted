package Template::Flute::Specification;

use strict;
use warnings;

use Template::Flute::Iterator;

=head1 NAME

Template::Flute::Specification - Specification class for Template::Flute

=head1 SYNOPSIS

    $xml_spec = new Template::Flute::Specification::XML;
    $spec = $xml_spec->parse_file('spec.xml');
    $spec->set_iterator('cart', $cart);

    $conf_spec = new Template::Flute::Specification::Scoped;
    $spec = $conf_spec->parse_file('spec.conf);

=head1 DESCRIPTION

Specification class for L<Template::Flute>.

=head1 CONSTRUCTOR

=head2 new

Creates Template::Flute::Specification object.

=cut

# Constructor

sub new {
	my ($class, $self);
	my (%params);

	$class = shift;
	%params = (encoding => 'utf8', @_);

	$self = \%params;

	# lookup hash for elements by class
	$self->{classes} = {};

	# lookup hash for elements by id
	$self->{ids} = {};

	# lookup hash for elements by name attribute
	$self->{names} = {};

	$self->{pagings} = {};

    # named patterns
    $self->{patterns} = {};

	bless $self, $class;
}

sub _ids {
    return keys %{shift->{ids}};
}

sub _classes {
    return keys %{shift->{classes}};
}

sub _names {
    return keys %{shift->{names}};
}

=head1 METHODS

=head2 name NAME

Set or get the name of the specification.

=cut

sub name {
	my $self = shift;

	if (scalar @_ > 0) {
		$self->{name} = shift;
	}

	return $self->{name};
}

=head2 encoding ENCODING

Set or get the encoding of the HTML template
which is parsed according to this specification.

=cut
	
sub encoding {
	my $self = shift;

	if (scalar @_ > 0) {
		$self->{encoding} = shift;
	}

	return $self->{encoding};
}

=head2 container_add CONTAINER

Add container specified by hash reference CONTAINER.

=cut

sub container_add {
	my ($self, $new_containerref) = @_;
	my ($containerref, $container_name, $id, $class);

	$container_name = $new_containerref->{container}->{name};

	$containerref = $self->{containers}->{$new_containerref->{container}->{name}} = {input => {}};

	$class = $new_containerref->{container}->{class} || $container_name;

	if ($id = $new_containerref->{container}->{id}) {
	    push @{$self->{ids}->{$id}}, {%{$new_containerref->{container}}, type => 'container'};
	}
	else {
	    $self->{classes}->{$class} = [{%{$new_containerref->{container}}, type => 'container'}];
	}

	# loop through values for this container
	for my $value (@{$new_containerref->{value}}) {
        if ($value->{id}) {
            push @{$self->{ids}->{$value->{id}}}, {%{$value}, type => 'value', container => $container_name};
        }
        else {
            $class = $value->{class} || $value->{name};
            unless ($class) {
                die "Neither class nor name for value within container $container_name.\n";
            }
            push @{$self->{classes}->{$class}}, {%{$value}, type => 'value', container => $container_name};
        }
	}

	return $containerref;
}

=head2 list_add LIST

Add list specified by hash reference LIST.

=cut
	
sub list_add {
	my ($self, $new_listref) = @_;
	my ($listref, $list_name, $class);

	$list_name = $new_listref->{list}->{name};

	$listref = $self->{lists}->{$new_listref->{list}->{name}} = {input => {}};

	$class = $new_listref->{list}->{class} || $list_name;

	$self->{classes}->{$class} = [{%{$new_listref->{list}}, type => 'list'}];

	if (exists $new_listref->{list}->{iterator}) {
		$listref->{iterator} = $new_listref->{list}->{iterator};
	}

	# loop through filters for this list
	for my $filter (@{$new_listref->{filter}}) {
		$listref->{filter}->{$filter->{name}} = $filter;
	}

	# loop through inputs for this list
	for my $input (@{$new_listref->{input}}) {
		$listref->{input}->{$input->{name}} = $input;
	}

	# loop through sorts for this list
	for my $sort (@{$new_listref->{sort}}) {
		$listref->{sort}->{$sort->{name}} = $sort;
	}

    # loop through containers for this list
    for my $container (@{$new_listref->{container}}) {
		$class = $container->{class} || $container->{name};
		unless ($class) {
			die "Neither class nor name for container within list $list_name.\n";
		}

		push @{$self->{classes}->{$class}}, {%{$container}, type => 'container', list => $list_name};
	}

	# loop through separators for this list
	for my $separator (@{$new_listref->{separator}}) {
	        $class = $separator->{class} || $separator->{name};
		unless ($class) {
			die "Neither class nor name for separator within list $list_name.\n";
		}
		$listref->{separator}->{$separator->{name}} = $separator;
		push @{$self->{classes}->{$class}}, {%{$separator}, type => 'separator', list => $list_name};
	}

	# loop through params for this list
	for my $param (@{$new_listref->{param}}) {
		$class = $param->{class} || $param->{name};
		unless ($class) {
			die "Neither class nor name for param within list $list_name.\n";
		}
		push @{$self->{classes}->{$class}}, {%{$param}, type => 'param', list => $list_name};
	}

	# loop through paging for this list
	for my $paging (@{$new_listref->{paging}}) {
		if (exists $listref->{paging}) {
			die "Only one paging allowed per list\n";
		}
		$listref->{paging} = $paging;
		$class = $paging->{class} || $paging->{name};
		$self->{classes}->{$class} = [{%{$paging}, type => 'paging', list => $list_name}];
	}
	
	return $listref;
}

=head2 paging_add PAGING

=cut

sub paging_add {
    my ($self, $new_pagingref) = @_;
    my ($name, $class, $pagingref);

	$name = $new_pagingref->{paging}->{name};

	$pagingref = $self->{pagings}->{$name} = {elements => $new_pagingref->{paging}->{elements}, list => $new_pagingref->{paging}->{list}};

    # loop through paging elements
    for my $element (values %{$new_pagingref->{paging}->{elements}}) {
        $class = $element->{class} || $element->{name};
        push @{$self->{classes}->{$class}}, {%{$element}, element_type => $element->{type}, type => 'element', list => $new_pagingref->{paging}->{list}, paging => $name};
    }
    
	$class = $new_pagingref->{paging}->{class} || $name;

	push @{$self->{classes}->{$class}}, {%{$new_pagingref->{paging}}, type => 'paging'};

    return $pagingref;
}

=head2 form_add FORM

Add form specified by hash reference FORM.

=cut
	
sub form_add {
	my ($self, $new_formref) = @_;
	my ($formref, $form_name, $form_link, $form_loc, $field_loc, $id, $class);

	$form_name = $new_formref->{form}->{name};
	$form_link = $new_formref->{form}->{link} || '';
	
	$formref = $self->{forms}->{$new_formref->{form}->{name}} = {input => {}};

	my @checks = qw/id class/;

	$form_loc = {%{$new_formref->{form}}, type => 'form'};
	
	if ($id = $new_formref->{form}->{id}) {
	    $self->{ids}->{$id} = [$form_loc];
	}
	elsif ($class = $new_formref->{form}->{class}) {
	    $class = $new_formref->{form}->{class};

	    $self->{classes}->{$class} = [$form_loc];
	}
	elsif ($form_link eq 'name') {
	    $self->{names}->{$form_name} = [$form_loc];
	}
	else {
	    $class = $form_name;
	    
	    $self->{classes}->{$class} = [$form_loc];
	}
	
	# loop through inputs for this form
	for my $input (@{$new_formref->{input}}) {
		$formref->{input}->{$input->{name}} = $input;
	}
	
	# loop through params for this form
	for my $param (@{$new_formref->{param}}) {
		$class = $param->{class} || $param->{name};

		push @{$self->{classes}->{$class}}, {%{$param}, type => 'param', form => $form_name};	
	}

	# loop through fields for this form
	for my $field (@{$new_formref->{field}}) {
	    $field_loc = {%{$field}, type => 'field', form => $form_name};

	    if (exists $field->{id}) {
		push @{$self->{ids}->{$field->{id}}}, $field_loc;
	    }
	    elsif (exists $field->{class}) {
		push @{$self->{classes}->{$field->{class}}}, $field_loc;
	    }
	    elsif ($form_link eq 'name') {
		push @{$self->{names}->{$field->{name}}}, $field_loc;
	    }
	    else {
		push @{$self->{classes}->{$field->{name}}}, $field_loc;
	    }
	}
	
	return $formref;
}

=head2 value_add VALUE

Add value specified by hash reference VALUE.

=cut
	
sub value_add {
	my ($self, $new_valueref) = @_;
	my ($valueref, $value_name, $id, $class);

	$value_name = $new_valueref->{value}->{name};

    unless (defined $value_name && $value_name =~ /\S/) {
        die "Value needs a name attribute.";
    }

    if (exists $new_valueref->{value}->{include}) {
		# include implies hooking resulting value
		$new_valueref->{value}->{op} = 'hook';
	}
	elsif (exists $new_valueref->{value}->{field}
           && $new_valueref->{value}->{field} =~ /\./) {
        $new_valueref->{value}->{field} = [split /\./, $new_valueref->{value}->{field}];
    }

	$valueref = $self->{values}->{$new_valueref->{value}->{name}} = {};
	
	if ($id = $new_valueref->{value}->{id}) {
		push @{$self->{ids}->{$id}}, {%{$new_valueref->{value}}, type => 'value'};
	}
	else {
		$class = $new_valueref->{value}->{class} || $value_name;

		push @{$self->{classes}->{$class}}, {%{$new_valueref->{value}}, type => 'value'};
	}

	return $valueref;
}	

=head2 i18n_add I18N

Add i18n specified by hash reference I18N.

=cut
	
sub i18n_add {
	my ($self, $new_i18nref) = @_;
	my ($i18nref, $i18n_name, $id, $class);

	$i18n_name = $new_i18nref->{value}->{name}
	  || $new_i18nref->{value}->{class};
	
	$i18nref = $self->{i18n}->{$i18n_name} = {};
	
	if ($id = $new_i18nref->{value}->{id}) {
		push @{$self->{ids}->{$id}}, {%{$new_i18nref->{value}}, type => 'i18n'};
	}
	else {
		$class = $new_i18nref->{value}->{class} || $i18n_name;

		push @{$self->{classes}->{$class}}, {%{$new_i18nref->{value}}, type => 'i18n'};
	}
	
	return $i18nref;
}

=head2 pattern_add({ name => 'pxt', regexp => qr/\Qmy string\E/ });

Add a pattern to the specification. The two keys C<name> and
C<regexp> are mandatory.

=head2 patterns

Returns a plain hash with name => regexp pairs of the patterns set in
the specification.

=cut

sub pattern_add {
    my ($self, $pattern) = @_;
    my $name   = $pattern->{name} or die "Couldn't add pattern: missing name";
    my $regexp = $pattern->{regexp} or die "Missing regexp for pattern $name";
    # print "Adding $name $regexp\n";
    $self->{patterns}->{$name} = $regexp;
    # print Dumper($self->{patterns});
}

sub patterns {
    return %{shift->{patterns}};
}



=head2 list_iterator NAME

Returns iterator for list named NAME or undef.

=cut

sub list_iterator {
	my ($self, $list_name) = @_;

	if (exists $self->{lists}->{$list_name}) {
		return $self->{lists}->{$list_name}->{iterator};
	}
}

=head2 list_inputs NAME

Returns inputs for list named NAME or undef.

=cut
	
sub list_inputs {
	my ($self, $list_name) = @_;

	if (exists $self->{lists}->{$list_name}) {
		return $self->{lists}->{$list_name}->{input};
	}
}

=head2 list_sorts NAME

Return sorts for list named NAME or undef.

=cut

sub list_sorts {
	my ($self, $list_name) = @_;

	if (exists $self->{lists}->{$list_name}) {
		return $self->{lists}->{$list_name}->{sort};
	}
}

=head2 list_filters NAME

Return filters for list named NAME or undef.

=cut

sub list_filters {
	my ($self, $list_name) = @_;

	if (exists $self->{lists}->{$list_name}) {
		return $self->{lists}->{$list_name}->{filter};
	}
}

=head2 form_inputs NAME

Return inputs for form named NAME or undef.

=cut

sub form_inputs {
	my ($self, $form_name) = @_;

	if (exists $self->{forms}->{$form_name}) {
		return $self->{forms}->{$form_name}->{input};
	}
}

=head2 iterator NAME

Returns iterator identified by NAME.

=cut

sub iterator {
	my ($self, $name) = @_;

	if (exists $self->{iters}->{$name}) {
		return $self->{iters}->{$name};
	}
}

=head2 set_iterator NAME ITER

Sets iterator for NAME to ITER. ITER can be a iterator
object like L<Template::Flute::Iterator> or a reference
to an array containing hash references.

=cut

sub set_iterator {
	my ($self, $name, $iter) = @_;
	my ($iter_ref);

	$iter_ref = ref($iter);

	if ($iter_ref eq 'ARRAY') {
		$iter = new Template::Flute::Iterator($iter);
	}
	
	$self->{iters}->{$name} = $iter;
}

=head2 resolve_iterator INPUT

Resolves iterator INPUT.

=cut

sub resolve_iterator {
	my ($self, $input) = @_;
	my ($input_ref, $iter);

	$input_ref = ref($input);

	if ($input_ref eq 'ARRAY') {
		$iter = new Template::Flute::Iterator($input);
	}
	elsif ($input_ref) {
		# iterator already resolved
		$iter = $input_ref;
	}
	elsif (exists $self->{iters}->{$input}) {
		$iter = $self->{iters}->{$input};
	}
	else {
		die "Failed to resolve iterator $input.\n";
	}

	return $iter;
}

=head2 elements_by_class NAME

Returns element(s) of the specification tied to HTML class NAME or undef.

=cut

sub elements_by_class {
	my ($self, $class) = @_;

	if (exists $self->{classes}->{$class}) {
		return $self->{classes}->{$class};
	}

	return;
}

=head2 elements_by_name NAME

Returns element(s) of the specification tied to HTML attribute name or undef.

=cut

sub elements_by_name {
	my ($self, $name) = @_;

	if (exists $self->{names}->{$name}) {
		return $self->{names}->{$name};
	}

	return;
}

=head2 elements_by_id NAME

Returns element(s) of the specification tied to HTML id NAME or undef.

=cut

sub elements_by_id {
	my ($self, $id) = @_;

	if (exists $self->{ids}->{$id}) {
		return $self->{ids}->{$id};
	}

	return;
}

=head2 list_paging NAME

Returns paging for list NAME.

=cut
	
sub list_paging {
	my ($self, $list_name) = @_;
    my ($name, $paging_ref);

	if (exists $self->{lists}->{$list_name}) {
        while (($name, $paging_ref) = each %{$self->{pagings}}) {
            if ($paging_ref->{list} eq $list_name) {
                return $paging_ref;
            }
        }
	}	
}

=head2 dangling

Method to check if the template is consistent with the specification.
The method retrieves the list of ids, classes and names, and check if
there are template elements attached.

For each specification element without template elements attached,
it produces a hash reference with the name, type and a dump of the element.

It returns a list of these hash references, so you can check the template with

    my $flute = Template::Flute->new(....);
    my @bad_elts = $flute->specification->dangling;

    if (@bad_elts) {
        warn "empty elements" . Dumper(\@bad_elts);
    }
    else {
        print "all ok\n";
    }

Each hashref returned has the following keys set:

=over 4

=item name

=item type

=item dump

=back

Beware that to call this method successfully, the specification must
already be processed, so it's safer to call it after C<$flute-E<gt>process>.

=cut


sub dangling {
    my $self = shift;
    my @empty;
    my %methods = (
                   id => {
                          list => '_ids',
                          elts => 'elements_by_id',
                         },
                   name => {
                            list => '_names',
                            elts => 'elements_by_name',
                           },
                   class => {
                             list => '_classes',
                             elts => 'elements_by_class',
                            },
                 );
    foreach my $internal (keys %methods) {
        my $method       = $methods{$internal}{list};
        my $get_elements = $methods{$internal}{elts};

        my @structs = $self->$method;
        foreach my $struct (@structs) {
            # here we have to look in the internals
            if (my $arrayref = $self->$get_elements($struct)) {
                foreach my $el (@$arrayref) {
                    unless (exists ($el->{elts})) {
                        push @empty, {
                                      type => $internal,
                                      name => $struct,
                                      dump => $el,
                                     }
                    }
                }
            }
        }
    }
    return @empty;
}

=head1 AUTHOR

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

=head1 BUGS

Please report any bugs or feature requests at L<https://github.com/racke/Template-Flute/issues>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
	
1;
