package Positron::Template;
our $VERSION = 'v0.1.3'; # VERSION

=head1 NAME

Positron::Template - a DOM based templating system

=head1 VERSION

version v0.1.3

=head1 SYNOPSIS

  use Positron::Template;

  my $template = Positron::Template->new();

  my $dom    = create_dom_tree();
  my $data   = { foo => 'bar', baz => [ 1, 2, 3 ] };
  my $result = $template->process($dom, $data); 

=cut

use v5.10;
use strict;
use warnings;

use Carp;
use Positron::Environment;
use Positron::Expression;
use Scalar::Util qw(blessed);

sub new {
    my ($class, %options) = @_;
    my $self = {
        opener => '{',
        closer => '}',
        dom => $options{dom} // undef,
        environment => Positron::Environment->new($options{env} // undef, { immutable => 1 }) // undef,
        handler => $options{handler} || _handler_for($options{dom}) // undef,
        include_paths => ['.'],
    };
    return bless ($self, $class);
}

# Stop writing these until need is shown
sub dom {
    my ($self, $dom) = @_;
    if (@_ == 1) {
        return $self->{'dom'};
    } else {
        $self->{'dom'} = $dom;
    }
}

sub add_include_paths {
    my ($self, @paths) = @_;
    push @{$self->{'include_paths'}}, @paths;
}


sub process {
    my ($self, $dom, $data) = @_;
    # TODO: what if only one is passed? -> $self attributes
    # What if a HashRef is passed? -> new Environment object
    if (ref($dom) eq 'HASH' or blessed($dom) and $dom->isa('Positron::Environment')) {
        $data = $dom;
        $dom = $self->{'dom'};
    }
    if (not $data) {
        $data = $self->{'environment'};
    }
    if (ref($data) eq 'HASH') {
        $data = Positron::Environment->new($data);
    }

    if (not ref($dom)) {
        return $self->_process_text($dom, $data);
    }
    # Real DOM -> List of nodes
    
    my @nodes = ();

    $self->{'handler'} //= _handler_for($dom);
    @nodes = $self->_process_element($dom, $data);
    # DESTROY Handler?

    # Many people know that they will get a single node here.
    # May as well not force them to unpack a list.
    return (wantarray) ? @nodes : $nodes[0];
}

sub _process_text {
    my ($self, $string, $environment, $with_quants) = @_;
    my $string_finder = $self->_make_finder('$');
    my $last_changing_quant = undef;
    my $did_change = undef;
    # First $ sigils; the quantifier chomps whitespace around it.
    $string =~ s{
        (\s*)
        $string_finder
        (\s*)
    }{
        my ($ws_before, $sigil, $quant, $expr, $ws_after) = ($1, $2, $3, $4, $5);
        my $replacement = Positron::Expression::evaluate($expr, $environment) // '';
        if ($quant eq '-') {
            $ws_before = '';
            $ws_after = '';
        } elsif ($quant eq '*') {
            $ws_before &&= ' ';
            $ws_after &&= ' ';
            if ($replacement eq '') {
                $ws_before = ' '; $ws_after = '';
            }
        }
        $last_changing_quant = $quant;
        $did_change = 1;
        "$ws_before$replacement$ws_after";
    }xmseg;
    # Next comments; the quantifier chomps whitespace around it.
    my $comment_finder = $self->_make_finder('#');
    $string =~ s{
        (\s*)
        $comment_finder
        (\s*)
    }{
        my ($ws_before, $sigil, $quant, $comment, $ws_after) = ($1, $2, $3, $4, $5);
        if ($quant eq '-') {
            $ws_before = '';
            $ws_after = '';
        } elsif ($quant eq '*') {
            $ws_before = ' ';
            $ws_after = '';
        }
        $last_changing_quant = $quant;
        $did_change = 1;
        "$ws_before$ws_after";
    }xmseg;
    # Next voider; the quantifier chomps whitespace around it.
    my $voider_finder = $self->_make_finder('~');
    $string =~ s{
        (\s*)
        $voider_finder
        (\s*)
    }{
        my ($ws_before, $sigil, $quant, undef, $ws_after) = ($1, $2, $3, $4, $5);
        if ($quant eq '-') {
            $ws_before = '';
            $ws_after = '';
        } elsif ($quant eq '*') {
            $ws_before = ' ';
            $ws_after = ' ';
            if ("$ws_before$ws_after" =~ m{\A \s+ \z}xms) {
                $ws_before = ' '; $ws_after = '';
            }
        }
        $last_changing_quant = $quant;
        $did_change = 1;
        "$ws_before$ws_after";
    }xmseg;
    return $with_quants? ($string, $did_change, $last_changing_quant) : $string;
}

sub _process_element {
    my ($self, $node, $environment) = @_;
    my $handler = $self->{'handler'};

    if (not ref($node)) {
        return $self->_process_text($node, $environment);
    }

    # check for assignments
    # create a modified environment if some are detected
    # proceed as normal

    # Evaluate structure sigils
    my ($sigil, $quant, $tail) = $self->_get_structure_sigil($node);

    # Have sigil, evaluate
    $sigil //= ''; # for 'eq'
    if ($sigil eq '@') {
        return $self->_process_loop($node, $environment, $sigil, $quant, $tail);
    } elsif ($sigil ~~ ['?', '!']) {
        return $self->_process_condition($node, $environment, $sigil, $quant, $tail);
    } elsif ($sigil eq '|') {
        return $self->_process_switch($node, $environment, $sigil, $quant, $tail);
    } elsif ($sigil eq '/') {
        return $self->_process_structure_comment($node, $environment, $sigil, $quant, $tail);
    } elsif ($sigil ~~ ['.', ',']) {
        return $self->_process_include($node, $environment, $sigil, $quant, $tail);
    } elsif ($sigil ~~ [':', ';']) {
        return $self->_process_wrap($node, $environment, $sigil, $quant, $tail);
    } elsif ($sigil eq '^') {
        return $self->_process_function($node, $environment, $sigil, $quant, $tail);
    } else {
        my $new_node = $handler->shallow_clone($node);
        $handler->push_contents( $new_node, map { $self->_process_element($_, $environment) } $handler->list_contents($node));
        $self->_remove_structure_sigils($new_node);
        #$self->resolve_hash_attr($new_node, $environment);
        $self->_resolve_text_attr($new_node, $environment);
        return $new_node;
    }
    # String ones
    return $node;
}

sub _process_loop {
	my ($self, $node, $environment, $sigil, $quant, $tail) = @_;
	my $handler = $self->{'handler'};
    # TODO: true() and coercion!
	my $loop = Positron::Expression::evaluate($tail, $environment) || [];
	if (not @$loop) {
		# keep if we should, else nothing
		return ($quant eq '+') ? ($self->_clone_and_resolve($node, $environment)) : ();
	}
	# else have loop
	my @contents;
	foreach my $row (@$loop) {
		my $env = Positron::Environment->new($row, {parent => $environment});
		my @row_contents = map { $self->_process_element( $_, $env) } $handler->list_contents($node);
		push @contents, ($quant eq '*') ? ($self->_clone_and_resolve($node, $env, @row_contents)) : @row_contents;
	}
	if ($quant ne '-' and $quant ne '*') { # remove this in any case
		return ($self->_clone_and_resolve($node, $environment, @contents));
	}
	return @contents;
}

sub _process_condition {
	my ($self, $node, $environment, $sigil, $quant, $tail) = @_;
	my $handler = $self->{'handler'};
    my $truth = Positron::Expression::true(Positron::Expression::evaluate($tail, $environment));
	if ($sigil eq '!') {$truth = not $truth;}
	my $keep = ($truth and $quant ne '-' or $quant eq '+');
	my @contents = ();
	if ($truth or $quant eq '*') {
		@contents = map { $self->_process_element($_, $environment) } $handler->list_contents($node);
	}
	return ($keep) ? ($self->_clone_and_resolve($node, $environment, @contents)) : @contents;
}

sub _process_switch {
	my ($self, $node, $environment, $sigil, $quant, $tail) = @_;
	my $handler = $self->{'handler'};
    my $truth;
    if ($tail =~ m{ \A : \s+ (.*) }xms) {
        # "switch/given": setter
        my $expr = $1;
        my $goal = Positron::Expression::evaluate($expr, $environment) // ''; # always defined
        $environment = Positron::Environment->new({'|' => $goal}, { parent => $environment, immutable => 0});
        $truth = 1; # counts as a true condition for quantifiers
    } else {
        # "case/when": getter
        my $goal = $environment->get('|');
        if (defined ($goal)) {
            # not consumed yet
            my $test = Positron::Expression::evaluate($tail, $environment) // '';
            # "truth" as in a condition
            # To trigger the default, the $tail expression must be "empty", not the result!
            $truth = ($goal eq $test or $tail =~ m{ \A \s* \z }xms);
            if ($truth) {
                # remember the match for defaults
                $environment->set('|', undef); # Don't delete, because of parent
            }
        } else {
            # already consumed, or never saw a '|:'
            $truth = 0;
        }
    }
    # Keep and contents (see condition)
    my @contents = ();
    my $keep = ($truth and $quant ne '-' or $quant eq '+');
    if ($truth or $quant eq '*') {
        @contents = map { $self->_process_element($_, $environment) } $handler->list_contents($node);
    }
    return ($keep) ? ($self->_clone_and_resolve($node, $environment, @contents)) : @contents;
}

sub _process_structure_comment {
	my ($self, $node, $environment, $sigil, $quant, $tail) = @_;
	my $handler = $self->{'handler'};
    # basically an always-false condition
    # we could reuse our $keep and @contents code here, but this is probably
    # more readable:
    if ($quant eq '+') {
        # keep node, not contents
        return $self->_clone_and_resolve($node, $environment);
    } elsif ($quant eq '*') {
        # keep contents, not node
        return map { $self->_process_element($_, $environment) } $handler->list_contents($node);
    } else {
        return; # nothing
    }
}

sub _process_include {
	my ($self, $node, $environment, $sigil, $quant, $tail) = @_;
	my $handler = $self->{'handler'};

    my @contents = ();

    if ($sigil eq '.') {
        # from file
        my $filename = Positron::Expression::evaluate($tail, $environment);
        my $filepath = undef;
        foreach my $include_path (@{$self->{'include_paths'}}) {
            if (-r $include_path . $filename) {
                $filepath = $include_path . $filename;
            }
        }
        if (not defined $filepath) {
            croak "Could not find $filename (from $tail) for inclusion";
        }


        # automatically die if we can't read this
        @contents = $handler->parse_file($filepath);
        @contents = map { $self->_process_element($_, $environment) } @contents;
    } else {
        # from env
        my $env_contents = Positron::Expression::evaluate($tail, $environment);
        if ($env_contents) {
            if (ref($env_contents) eq 'ARRAY') {
                # special case: can't allow ['a', 'text'], must be [['a', 'text']], sorry
                if ($handler->isa('Positron::Handler::ArrayRef') and not ref($env_contents->[0])) {
                    @contents = ($env_contents);
                } else {
                    @contents = @$env_contents;
                }
            } else {
                @contents = ($env_contents);
            }
        } else {
            # warn?
            @contents = ();
        }
    }

    my $keep = ($quant eq '+');
    return ($keep) ? ($self->_clone_and_resolve($node, $environment, @contents)) : @contents;
}

# TODO: Refactor. Either extract the parts that are common between _include and
#       _wrap, or just push them both together in one function.
sub _process_wrap {
	my ($self, $node, $environment, $sigil, $quant, $tail) = @_;
	my $handler = $self->{'handler'};

    my @contents = ();

    if ($tail =~ m{ \S }xms) {

        my @wrapping_contents;
        if ($sigil eq ':') {
            # filename, read that and include "us".
            my $filename = Positron::Expression::evaluate($tail, $environment);
            my $filepath = undef;
            foreach my $include_path (@{$self->{'include_paths'}}) {
                if (-r $include_path . $filename) {
                    $filepath = $include_path . $filename;
                }
            }
            if (not defined $filepath) {
                croak "Could not find $filename (from $tail) for wrapping";
            }
            # automatically die if we can't read this
            @wrapping_contents = $handler->parse_file($filepath);
        } else {
            # from env
            my $env_contents = Positron::Expression::evaluate($tail, $environment);
            if ($env_contents) {
                if (ref($env_contents) eq 'ARRAY') {
                    # special case: can't allow ['a', 'text'], must be [['a', 'text']], sorry
                    if ($handler->isa('Positron::Handler::ArrayRef') and not ref($env_contents->[0])) {
                        @wrapping_contents = ($env_contents);
                    } else {
                        @wrapping_contents = @$env_contents;
                    }
                } else {
                    @wrapping_contents = ($env_contents);
                }
            } else {
                # warn?
                @wrapping_contents = ();
            }
        }

        # TODO: resolve later? We'd need to clone $node and remove structure sigils to defeat recursion
        # Resolve now; also allows clone_and_resolve to clear sigils to defeat recursion
        @contents = map { $self->_process_element($_, $environment) } $handler->list_contents($node);
        # only quant-less versions pass the parent
        my @passed_nodes = $quant ? @contents : $self->_clone_and_resolve($node, $environment, @contents);

        $environment = Positron::Environment->new({':' => [ @passed_nodes ]}, { parent => $environment, immutable => 0});

        @contents = @wrapping_contents;
        @contents = map { $self->_process_element($_, $environment) } @contents;

    } else {
        # inclusion marker
        my $passed_nodes = $environment->get(':') || [];
        # On error, just kill all (warn, maybe?)
        # Remember: already resolved!
        @contents = @$passed_nodes;
    }

    # this works for both cases!
    my $keep = ($quant eq '+');
    return ($keep) ? ($self->_clone_and_resolve($node, $environment, @contents)) : @contents;
}

sub _process_function {
	my ($self, $node, $environment, $sigil, $quant, $tail) = @_;
	my $handler = $self->{'handler'};
    my $function = Positron::Expression::evaluate($tail, $environment);

    # The "self" node can be part of the arguments (quant ''), receive the results of the function
    # (quant '+'), or be dropped altogether (quant '-').
	my $keep = ($quant eq '+');
    my $pass_self = (not $keep and $quant ne '-');

	my @contents = ();
    # Need these in any case:
    @contents = map { $self->_process_element($_, $environment) } $handler->list_contents($node);
    if ($pass_self) {
        # we could also need to pass "self".
        @contents = $self->_clone_and_resolve($node, $environment, @contents);
    }

    @contents = $function->(@contents);
	return ($keep) ? ($self->_clone_and_resolve($node, $environment, @contents)) : @contents;
}


sub _make_finder {
    my ($self, $sigils) = @_;
    # What to do on empty sigils? Need to find during development!
    die "Empty sigil list!" unless $sigils;
    my ($opener, $closer) = ($self->{opener}, $self->{closer});
    my ($eopener, $ecloser) = ("\\$opener","\\$closer");
    my ($esigils) = join('', map { "\\$_" } split(qr{}, $sigils));
    return qr{
        $eopener
        ( [$esigils] )
        ( [-+*]? )
        ( [^$ecloser]* )
        $ecloser
    }xms;
}

# Handlers for:
# scalar string, no handler
# HTML::Element
# XML::LibXML
# ArrayRef Handler
# TODO: an extensible mechanism
sub _handler_for {
    my ($dom) = @_;
    return unless ref($dom); # Text at most, needs no handler
    if (ref($dom) eq 'ARRAY') {
        require Positron::Handler::ArrayRef;
        return Positron::Handler::ArrayRef->new();
    } elsif (my $package = blessed($dom)) {
        eval "require Positron::Handler::$package; 1;" or croak "Could not load handler for $package";
    }
}

sub _get_structure_sigil {
    my ($self, $node) = @_;
    my $handler = $self->{'handler'};
    my $structure_finder = $self->_make_finder('@?!/.:,;|^');
    foreach my $attr ($handler->list_attributes($node)) {
        my $value = $handler->get_attribute($node, $attr);
        if ($value =~ m{ $structure_finder }xms) {
            return ($1, $2, $3);
        }
    }
    return; # Has none
}

sub _remove_structure_sigils {
    my ($self, $node) = @_;
    my $handler = $self->{'handler'};
    # NOTE: we remove '=' here as well, even though it's not a structure sigil!
    my $structure_finder = $self->_make_finder('@?!/.:,;=|^');
    foreach my $attr ($handler->list_attributes($node)) {
        my $value = $handler->get_attribute($node, $attr);
        my $did_change = ($value =~ s{ $structure_finder }{}xmsg);
        if ($did_change) {
            # We removed something from this attribute -> delete it if empty
            if ($value eq '') {
                $handler->set_attribute($node, $attr, undef);
            }
        }
    }
    return; # void?
}

sub _clone_and_resolve {
    my ($self, $node, $environment, @contents) = @_;
    my $handler = $self->{'handler'};
    my $clone = $handler->shallow_clone($node);
    $self->_remove_structure_sigils($clone);
    $self->_resolve_text_attr($clone, $environment);
    $handler->push_contents($clone, @contents);
    return $clone;
}

sub _resolve_text_attr {
    my ($self, $node, $environment) = @_;
    my $handler = $self->{'handler'};
    foreach my $attr ($handler->list_attributes($node)) {
        my ($value, $did_change, $last_changing_quant) = $self->_process_text($handler->get_attribute($node, $attr), $environment, 1);
        if ($did_change) {
            if ($value eq '' and not $last_changing_quant eq '+') {
                # We removed somethin from this attribute -> delete it if empty, unless the last sigil says otherwise
                $value = undef;
            }
            $handler->set_attribute($node, $attr, $value);
        }
    }
    return;
}
1;

__END__

Decisions:

Bind DOM to $template object? Bind environment to $template object?
-> Force neither, allow both!


_next_sigil($self, $string, $sigils) -> ($match, $sigil, $quant, $payload)
