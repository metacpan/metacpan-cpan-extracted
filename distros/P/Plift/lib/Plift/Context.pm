package Plift::Context;

use Moo;
use Carp;
use XML::LibXML::jQuery;
use JSON 'to_json';
use Encode 'encode';
use namespace::clean;
use Ref::Util qw/ is_hashref is_blessed_ref /;


has 'helper', is => 'ro';
has 'wrapper', is => 'ro';
has 'template', is => 'ro', required => 1;
has 'encoding', is => 'ro', default => 'UTF-8';
has 'loop_var', is => 'ro', default => 'loop';
has 'metadata_key', is => 'ro', default => 'meta';
has 'handlers', is => 'ro', default => sub { [] };
has 'active_handlers', is => 'rw';
has 'inactive_handlers', is => 'rw';
has 'internal_id_attribute', is => 'ro', default => 'data-plift-id';
has '_load_template', is => 'ro', required => 1, init_arg => 'load_template';
has '_load_snippet', is => 'ro', required => 1, init_arg => 'load_snippet';
has '_run_hooks', is => 'ro', required => 1, init_arg => 'run_hooks';


has 'document', is => 'rw', init_arg => undef;
has 'is_rendering', is => 'rw', init_arg => undef, default => 0;
has 'is_aborted', is => 'rw', init_arg => undef, default => '';

has '_data_stack',   is => 'ro', init_arg => 'data_stack', default => sub { [] };
has '_directive_stack',   is => 'ro', init_arg => undef, default => sub { [] };


sub AUTOLOAD {
    my $self = shift;

    my ($package, $method) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
    Carp::croak "Undefined subroutine &${package}::$method called"
        unless is_blessed_ref $self && $self->isa(__PACKAGE__);

    return if $method eq 'DESTROY';

    Carp::croak qq{Can't locate object method "$method" via package "$package"}
        unless $self->helper && $self->helper->can($method);

    $self->helper->$method(@_);
}

sub BUILD {
    my $self = shift;

    # coerse array indo hash
    foreach my $attr (qw/ active_handlers inactive_handlers/) {

        $self->$attr({ map { $_ => 1 } @{ $self->$attr } })
            if $self->$attr;
    }
}

sub metadata {
    my $self = shift;
    my $key = $self->metadata_key;
    my $data = $self->data;
    $data->{$key} = {} unless exists $data->{$key};
    $data->{$key};
}


sub data {
    my $self = shift;
    my $stack = $self->_data_stack;
    push @$stack, +{} if @$stack == 0;
    $stack->[-1];
}

sub _push_stack {
    my ($self, $data_point) = @_;
    my $data = $self->get($data_point) || {};
    push @{$self->_data_stack}, $data;
    $self;
}

sub _pop_stack {
    my ($self) = @_;
    pop @{$self->_data_stack};
    $self;
}

sub directives {
    my $self = shift;
    my $stack = $self->_directive_stack;
    push @$stack, +{
        directives => [],
        selector => '',
    } if @$stack == 0;
    $stack->[-1];
}

sub rewind_directive_stack {
    my ($self, $element) = @_;

    # rewind all
    unless (defined $element) {

        my $directive_stack = $self->_directive_stack;
        pop @$directive_stack while (@$directive_stack > 1);
        return;
    }

    # rewind until parent is found
    # pop stack until we find a parent or reach the root of stack
    my $stack = $self->_directive_stack;
    while (@$stack > 1) {

        my $parent = $element->parent;
        my $parent_selector = $stack->[-1]->{selector};

        # remove modifiers
        $self->_parse_matchspec_modifiers($parent_selector);

        while ($parent->get(0)->nodeType != 9) {

            return if $parent->filter($parent_selector)->size == 1;

            $parent = $parent->parent;
        }

        pop @$stack;
    }
}

sub push_at {
    my ($self, $selector, $data_point) = @_;

    my $inner_directives = [];
    $self->at($selector => { $data_point => $inner_directives });
    push @{$self->_directive_stack}, {
        selector   => $selector,
        directives => $inner_directives
    };

    # p $self->_directive_stack;

    $self;
}

sub pop_at {
    my $self = shift;
    pop @{$self->_directive_stack};
    $self;
}



sub internal_id {
    my ($self, $node) = @_;

    $node = $node->get(0)
        if $node->isa('XML::LibXML::jQuery');

    unless ($node->hasAttribute($self->internal_id_attribute)) {
        $node->setAttribute($self->internal_id_attribute, $node->unique_key);
    }

    $node->getAttribute($self->internal_id_attribute);
}

sub selector_for {
    my ($self, $element) = @_;
    my $id = $self->internal_id($element);
    sprintf '*[%s="%s"]', $self->internal_id_attribute, $id;
}




sub at {
    my $self = shift;
    my $directives = $self->directives->{directives};
    if (my $reftype = ref $_[0]) {

        push @$directives, @{$_[0]}
            if $reftype eq 'ARRAY';

        push @$directives, %{$_[0]}
            if $reftype eq 'HASH';
    }
    else {
        push @$directives, @_;
    }

    $self;
}



sub set {
    my $self = shift;

    confess "set() what?"
        unless defined $_[0];

    my $data   = $self->data;

    # set(hashref)
    if (my $reftype = ref $_[0]) {

        confess "Invalid parameter given to set(data): data must be a hashref."
            unless $reftype eq 'HASH';

        # copy data
        $data->{$_} = $_[0]->{$_}
            for keys %{$_[0]};

        return $self;
    }

    # set(key, value)
    $data->{$_[0]} = $_[1];

    $self;
}


sub get {
    my ($self, $reference) = @_;

    my $data = $self->data;
    return $data if $reference eq '.';

    my @keys = split /\./, $reference;

    # empty key
    die "invalid reference '$reference'"
        if grep { !defined } @keys;

    # traverse data, valid reference formats:
    # - foo
    # - foo.bar
    # - foo.0
    # - foo.0.bar

    my $current_path = '';
    while (defined (my $key = shift @keys)) {

        # undefined data
        confess "get('$reference') error: '$current_path' is undefined."
            unless defined $data;

        # cant traverse non-ref data
        die "get('$reference') error: can't traverse key '$key': '$current_path' is a non-ref value."
            unless ref $data;


        my $next_data;

        # hash key
        if (ref $data eq 'HASH') {

            $next_data = $data->{$key};
        }

        # array: numeric keys only
        elsif (ref $data eq 'ARRAY') {

            confess "get('$reference') error: '$current_path' is an array and '$key' is not a numeric index."
                unless $key =~ /^\-?\d+$/;

            $next_data = $data->[$key];
        }

        elsif (is_blessed_ref $data) {

            if ($data->can($key)) {
                $next_data = $data->$key;
            }
            elsif (is_hashref $data && exists $data->{$key}) {
                $next_data = $data->{$key};
            }
            else {
                die sprintf("get('%s') error: '%s' is an '%s' instance and '%s' is not a existing method or property.",
                    $reference, $current_path, ref $data, $key);
            }
        }

        elsif (ref $data) {

            die sprintf "get('%s') error: can't traverse key '%s': '%s' is a unsupported ref value (%s).",
                $reference, $key, $current_path, ref $data;
        }

        # next data is code, replace by its rv
        $next_data = $next_data->($self, $data)
            if ref $next_data eq 'CODE';

        $data = $next_data;

        # append path
        $current_path .= length $current_path ? ".$key" : $key;
    }


    $data = '' unless defined $data;
    return $data;
}

sub abort { shift->is_aborted(1) }

sub process_template {
    my ($self, $template_name) = @_;

    # TODO this is an action at a distance... find a better solution
    # localize current_file and current_path
    # load_template sets it, process_element can recurse into load_template
    # thats for related paths to work
    local $self->{current_file} = $self->{current_file};
    local $self->{current_path} = $self->{current_path};

    my $element = $self->load_template($template_name);
    $self->_run_hooks->('after_load_template', [$self, $element, $template_name]);
    $self->_run_hooks->('before_process_template', [$self, $element, $template_name]);
    $self->process_element($element);
    $self->_run_hooks->('after_process_template', [$self, $element, $template_name]);

    $element;
}


# load a template from the paths contained in the _load_template closure
sub load_template {
    my ($self, $name) = @_;
    $self->_load_template->($self, $name);
}

sub process_element {
    my ($self, $element) = @_;

    # match elements
    my $callback = sub {
        $self->_dispatch_handlers(@_, $element->_new_nodes([$_[1]]));
    };

    # get handlers
    my @handlers = @{ $self->handlers };
    @handlers = grep { exists $self->active_handlers->{$_->{name}} } @handlers
        if defined $self->active_handlers;

    @handlers = grep { !exists $self->inactive_handlers->{$_->{name}} } @handlers
        if defined $self->inactive_handlers;

    # build xpath
    my $find_xpath = join ' | ', map { $_->{xpath} } @handlers;
    my $filter_xpath = $find_xpath;
    $filter_xpath =~ s{\.//}{./}g;

    foreach my $node (
        @{ $element->xfilter($filter_xpath)->{nodes} },
        @{ $element->xfind($find_xpath)->{nodes} }
    ) {

        last if $self->is_aborted;
        $self->_dispatch_handlers($node, $element->_new_nodes([$node]));
    }

    # printf STDERR "# afer filter: %s\n", $element->as_html;
}

sub _dispatch_handlers {
    my ($self, $node, $el) = @_;
    my $tagname = $node->localname;

    foreach my $handler (@{ $self->handlers }) {

        last if $self->is_aborted;

        # dispatch by tagname
        my $handler_match = 0;
        if ($handler->{tag} && scalar grep { $_ eq $tagname } @{$handler->{tag}}) {

            $handler_match = 1;
        }

        # dispatch by attribute
        elsif ($handler->{attribute}) {

            foreach my $attr (@{$handler->{attribute}}) {

                if ($node->hasAttribute($attr)) {

                    $handler_match = 1;
                    last;
                }
            }
        }

        # dispatch
        $handler->{sub}->($el, $self)
            if $handler_match;
    }
}


sub render  {
    my ($self, $data) = @_;

    @{ $self->_data_stack } = ( $data )
        if defined $data;

    # already rendering
    die "Can't call render() now. We are already rendering."
        if $self->is_rendering;

    $self->is_rendering(1);
    $self->is_aborted(0);

    # vivify metadata
    my $meta = $self->metadata;

    # process template
    my $element = $self->process_template($self->template);

    # aborted
    return $element->document if $self->is_aborted;

    # apply wrapper
    if ($self->wrapper) {

        my $wrapper = $self->process_template($self->wrapper);
        $wrapper->insert_after($element);
        $wrapper->find('#content')->append($element);
        $element = $wrapper;
    }

    # rewind directive stack, then render
    $self->rewind_directive_stack;
    $self->_run_hooks->('before_render_directives', [$self, $element]);
    $self->_render_directives($element, $self->directives->{directives});
    $self->_run_hooks->('after_render_directives', [$self, $element]);

    # TODO output filters

    # remove internal id attribute
    $element->xfind(sprintf '//*[@%s]', $self->internal_id_attribute)
            ->remove_attr($self->internal_id_attribute);

    # return the document
    $self->is_rendering(0);
    $element->document;
}

sub _render_directives {
    my ($self, $el, $directives) = @_;

    for (my $i = 0; $i < @$directives; $i += 2) {

        last if $self->is_aborted;

        my $match_spec = $directives->[$i];

        # modifiers
        my $mod = $self->_parse_matchspec_modifiers($match_spec);

        my ($selector, $attribute) = split '@', $match_spec;
        my $action = $directives->[$i+1];

        my $target_element = $selector eq '.' ? $el : $el->find($selector);
        $target_element = $el->filter($selector) if $target_element->size == 0;
        next unless $target_element->size > 0;

        # Scalar
        if (!ref $action) {

            my $value = $self->get($action);

            $target_element->remove unless defined $value;

            # to_json
            $value = to_json($value, { convert_blessed => 1 }) if ref $value eq 'HASH';

            # encode
            $value = encode 'UTF-8', $value;

            if (defined $attribute && $attribute ne 'HTML') {

                # TODO append prepend attribute
                $target_element->attr($attribute, $value);
            }
            else {

                # render Text by default (i.e. escaped HTML)
                $value = [$target_element->{document}->createTextNode($value)]
                    unless defined $attribute && $attribute eq 'HTML';

                # replace contents by default
                $target_element->contents->remove
                    unless $mod->{prepend} || $mod->{append};

                $mod->{prepend} ? $target_element->prepend($value)
                                : $target_element->append($value);
            }
        }

        # ArrayRef
        elsif (ref $action eq 'ARRAY') {

            $self->_render_directives($target_element, $action);
        }

        # HashRef
        elsif (ref $action eq 'HASH') {

            my ($new_data_root, $new_directives) = %$action;

            my $new_data = $self->get($new_data_root);

            # loop render
            if (defined $new_data && ref $new_data eq 'ARRAY') {

                my $total = @$new_data;
                my $item_tpl = $mod->{replace} ? $target_element->contents
                                               : $target_element;

                for (my $i = 0; $i < @$new_data; $i++) {

                    $self->_push_stack("$new_data_root.$i");

                    # temporary loop var
                    local $self->data->{$self->loop_var} = {
                        index => $i + 1,
                        total => $total
                    };

                    my $new_item = $item_tpl->clone;
                    $new_item->insert_before($target_element);
                    $self->_render_directives($new_item, $new_directives);

                    $self->_pop_stack;
                }

                $target_element->remove;
            }
            else {

                $self->_push_stack($new_data_root);
                $self->_render_directives($target_element, $new_directives);
                $self->_pop_stack;
            }
        }

        # CodeRef
        elsif (ref $action eq 'CODE') {
            # Template::Pure used this coderef to receive a value.
            # our coderef is used to perform custom element rendering,
            # We support evaluating a value from a coderef when a datapoint is a coderef.
            $action->($target_element, $self);
        }

        # replace
        $target_element->replace_with($target_element->contents)
            if $mod->{replace};
    }
}

sub _parse_matchspec_modifiers {
    my %mod;

    # ^<match_spec>
    $mod{replace} = $_[1] =~ /^\+?\^\+?/;

    # +<match_spec>
    $mod{prepend} = $_[1] =~ /^\^?\+\^?/;

    # <match_spec>+
    $mod{append} = $_[1] =~ /\+$/;

    # remove modifier characters
    $_[1] =~ s/^[+^]+(?=[\w\.\[\*\#])//g;
    $_[1] =~ s/(?<=[\w\.\#\*\]])[+]+$//g;

    \%mod;
}


sub run_snippet {
    my ($self, $name, $element, $params) = @_;

    # instantiate
    ($name, my $action) = split /\//, $name;
    my $snippet = $self->snippet($name, $params);

    # action
    $action ||= 'process';
    my $method = $snippet->can($action);

    die "Invalid action '$action' for snippet '$name'."
        unless $method;

    # run
    $snippet->$method($element, $self, $params);
}

sub snippet {
    my ($self, $name, $params) = @_;
    $params ||= {};
    $self->_load_snippet->($name, $params);
}





1;
__END__

=encoding utf-8

=head1 NAME

Plift::Context - Template data and instructions to be rendered.

=head1 SYNOPSIS


    use Plift;

    my $plift = Plift->new(
        path    => \@paths,                               # default ['.']
        plugins => [qw/ Script Blog Gallery GoogleMap /], # plugins not included
    );

    my $tpl = $plift->template("index");

    # set render directives
    $tpl->at({
        '#name' => 'fullname',
        '#contact' => [
            '.phone' => 'contact.phone',
            '.email' => 'contact.email'
        ]
    });

    # render render with data
    my $document = $tpl->render({

        fullname => 'Carlos Fernando Avila Gratz',
        contact => {
            phone => '+55 27 1234-5678',
            email => 'cafe@example.com'
        }
    });

=head1 METHODS

=head2 at

Adds on or more render directives.

=head2 set

Set data to be rendered.

=head2 get

Get data via a dotted data-point string.

    $context->set(posts => [
        { title => 'Post 01',  ... },
        { title => 'Post 02',  ... },
        { title => 'Post 03',  ... },
        ...
    ]);

    print $context->get('posts.0.title'); # Post 01

=head2 render

Renders the template. Returns a XML::LibXML::jQuery object containing the
XML::LibXML::Document node.

    print $context->render(\%data)->as_html;

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
