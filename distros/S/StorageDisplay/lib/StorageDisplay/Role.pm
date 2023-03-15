#
# This file is part of StorageDisplay
#
# This software is copyright (c) 2014-2023 by Vincent Danjean.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package StorageDisplay::Role;
# ABSTRACT: Load all roles used in StorageDisplay

our $VERSION = '1.1.0'; # VERSION

1;

##################################################################
package StorageDisplay::Role::ProvideName::Plain;

use Moose::Role;

sub name; # forward decl for 'requires'
has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => 'name',
    required => 1,
    );

1;

##################################################################
package StorageDisplay::Role::ProvideName::Recursive;

use Moose::Role;
use Carp;

requires 'has_parent';

has '_name' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => 'name',
    required => 1,
    lazy     => 1,
    default  => sub {
	my $self = shift;
	if (!$self->ignore_name) {
	    confess "no name provided and ignore_name not set in $self\n";
	}
	return "NONAME";
    },
    );

sub name; # forward decl for 'requires'
has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    required => 1,
    lazy     => 1,
    default  => sub {
	my $self = shift;
	my $lname = $self->name_prefix;
	if (!$self->ignore_name) {
	    $lname .= '@'.$self->_name;
	}
	#print STDERR "In $self\t: using $lname as name\n";
	return $lname;
    },
    );

has 'fullname' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    required => 1,
    lazy     => 1,
    default  => sub {
	my $self = shift;
	my $lname = $self->fullname_prefix;
	if (!$self->ignore_name) {
	    $lname .= '@'.$self->_name;
	}
	if (! $self->has_parent) {
	    #print STDERR "no parent in fullname for $self\n";
	    return $lname;
	}
	my $fullname = join('|', $self->parent->fullname, $lname);
	#print STDERR "In $self\t: using $fullname as fullname\n";
	return $fullname;
    },
    );

has 'name_prefix' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    lazy     => 1,
    default  => sub {
	my $self = shift;
	my $kind = ref($self);
	$kind =~ s/^StorageDisplay::Data:://;
	return $kind;
    },
    );

has 'fullname_prefix' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    required => 1,
    lazy     => 1,
    default  => sub {
	my $self = shift;
	my $kind = ref($self);
	$kind =~ s/^StorageDisplay::Data:://;
	my $name_prefix = $self->name_prefix;
	if ($kind ne $name_prefix) {
	    return $name_prefix;
	}
	if ($self->has_parent) {
	    my $pkind = ref($self->parent);
	    $pkind =~ s/^StorageDisplay::Data:://;
	    $kind =~ s/^$pkind//;
	}
	return $kind;
    },
    );

has 'ignore_name' => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
    lazy     => 1,
    default  => 0,
    );

1;

##################################################################
package StorageDisplay::Role::WithName;

use Moose::Role;

requires 'name';

1;

##################################################################
package StorageDisplay::Role::Iterable;

use MooseX::Role::Parameterized;
use Types::Standard qw(Enum);

use Carp;

parameter iterable => (
    isa      => 'Str',
    required => 1,
    );

parameter _kindname => (
    is       => 'ro',
    isa      => Enum[qw/Plain Recursive/],
    init_arg => 'name',
    required => 1,
    #default  => "Plain",
    );

role {
    my $p = shift;
    my $role_provide = "StorageDisplay::Role::ProvideName::".$p->_kindname;

    with (
	$role_provide,
	"StorageDisplay::Role::WithName",
	);

    my $iterable = $p->iterable;
    my $iterator = $iterable.'::Iterator';
    my $iteratorframe = $iterator.'::Frame';

    has '_parents' => (
        traits   => [ 'Hash' ],
        is       => 'ro',
        isa      => "HashRef[$iterable]",
        required => 1,
        default  => sub { return {}; },
        handles  => {
            '_add_parents' => 'set',
                'hasParent' => 'exists',
                '_getParent' => 'get',
        }
        );

    has '_parents_tab' => (
        traits   => [ 'Array' ],
        is       => 'ro',
        isa      => "ArrayRef[$iterable]",
        required => 1,
        default  => sub { return []; },
        handles  => {
            '_add_parents_tab' => 'push',
                'parents' => 'elements',
		'nb_parents' => 'count',
        }
        );

    method "_addParent" => sub {
        my $self = shift;
        my $parent = shift;
        my $parent_name = $parent->name;
        if ($self->hasParent($parent_name)) {
            if ($parent != $self->_getParent($parent_name)) {
                croak "Two different parents with name $parent_name for ".$self->name;
            }
        } else {
            $self->_add_parents($parent_name, $parent);
            $self->_add_parents_tab($parent);
        }
    };

    has '_children' => (
        traits   => [ 'Hash' ],
        is       => 'ro',
        isa      => "HashRef[$iterable]",
        required => 1,
        default  => sub { return {}; },
        handles  => {
            '_addChild' => 'set',
                'hasChild' => 'exists',
                '_getChild' => 'get',
        }
        );

    has '_children_tab' => (
        traits   => [ 'Array' ],
        is       => 'ro',
        isa      => "ArrayRef[$iterable]",
        required => 1,
        default  => sub { return []; },
        handles  => {
        '_addChild_tab' => 'push',
            'children' => 'elements',
        }
        );

    method "addChild" => sub {
        my $self = shift;
        my $child = shift;
        my $child_name = $child->name;
        if ($self->hasChild($child_name)) {
            if ($child != $self->_getChild($child_name)) {
                croak "Two different children with name $child_name for ".$self->name;
            }
        } else {
            $self->_addChild($child_name, $child);
            $self->_addChild_tab($child);
        }
        $child->_addParent($self);
        return $child;
    };

    method "iterator" => sub {
        my $self = shift;

        return "$iterator"->new(
            $self,
            @_,
            );
    };
    ######################################################
    ######################################################
    # ::Iterator class
    my $iteratorclass = Moose::Meta::Class->create(
        $iterator,
        #attributes => [],
        #roles => [],
        #methods => {},
        superclasses => ["Moose::Object"],
        );

    $iteratorclass->add_attribute(
        'recurse' => (
            is  => 'ro',
            isa => 'Bool',
            required => 1,
            default => 1,
        ));
    $iteratorclass->add_attribute(
        'with-self' => (
            is  => 'bare',
            reader => 'with_self',
            isa => 'Bool',
            required => 1,
            default => 0,
        ));
    $iteratorclass->add_attribute(
        '_seen' => (
            traits => [ 'Hash' ],
            is  => 'ro',
            isa => 'HashRef[Bool]',
            required => 1,
            default => sub { return {}; },
            handles  => {
                '_found' => 'exists',
                    '_mark' => 'set',
            }
        ));
    $iteratorclass->add_attribute(
        'uniq' => (
            is  => 'ro',
            isa => 'Bool',
            required => 1,
            default => 0,
        ));
    $iteratorclass->add_attribute(
        'postfix' => (
            is => 'ro',
            isa => 'Bool',
            required => 1,
            default => 0,
        ));
    $iteratorclass->add_attribute(
        '_stack_frame' => (
            traits => [ 'Array' ],
            is  => 'ro',
            isa => "ArrayRef[$iteratorframe]",
            required => 1,
            default => sub { return []; },
            handles  => {
                '_push_frame' => 'push',
                    '_pop_frame' => 'pop',
            }
        ));
    $iteratorclass->add_attribute(
        '_init_block' => (
            is  => 'ro',
            isa => $iterable,
            required => 1,
        ));
    $iteratorclass->add_attribute(
        '_cur_frame' => (
            is  => 'rw',
            isa => "Maybe[$iteratorframe]",
            required => 1,
            lazy => 1,
            default => sub {
                my $self = shift;
                return $iteratorframe->new(
                    $self->_init_block,
                    $self,
                    );
            },
        ));
    $iteratorclass->add_attribute(
        '_next_computed' => (
            is  => 'rw',
            isa => 'Bool',
            required => 0,
            default => 0,
        ));
    $iteratorclass->add_attribute(
        '_next' => (
            is  => 'rw',
            isa => "Maybe[$iterable]",
            required => 0,
            default => undef,
        ));
    $iteratorclass->add_method(
        'has_next' => sub {
            my $self = shift;
            if (! $self->_next_computed) {
                $self->_compute_next;
            }
            return defined($self->_next);
        });
    $iteratorclass->add_method(
        'next' => sub {
            my $self = shift;
            if (! $self->_next_computed) {
                $self->_compute_next;
            }
            $self->_next_computed(0);
            return $self->_next;
        });
    $iteratorclass->add_attribute(
        'filter' => (
            traits  => ['Code'],
            is      => 'ro',
            isa     => 'CodeRef',
            default => sub {
                sub { 1; }
            },
            handles => {
                do_filter => 'execute',
            },
        ));
    $iteratorclass->add_method(
        '_compute_next' => sub {
            my $self = shift;

            $self->_next_computed(1);
            if (!defined($self->_cur_frame)) {
                $self->_next(undef);
                return;
            }
            #print STDERR "****\nBegin compute: ", $self->_cur_frame->dump, "\n";
            do {
                do {
                    my $n = $self->_cur_frame->next_child;
                    while (! defined($n)) {
                        # nothing more in this frame. Poping it.
                        my $cur_frame = $self->_cur_frame;
                        $self->_cur_frame($self->_pop_frame);
                        if ($self->postfix) {
                            $n=$cur_frame->current;
                            #print STDERR "Poping frame and found: ", $n->name, "\n";
                            if ($n == $self->_init_block) {
                                $self->_next(undef);
                                return;
                            }
                            $self->_next($n);
                            $n=undef;
                            last;
                        } else {
                            if (!defined($self->_cur_frame)) {
                                $self->_next(undef);
                                return;
                            }
                            #print STDERR "Poping frame: ", $self->_cur_frame->dump, "\n";
                            $n = $self->_cur_frame->next_child;
                        }
                    }
                    while (defined($n)) {
                        # $n : next in _cur_frame
                        my @children = ($n->children);
                        if (! $self->recurse || scalar(@children) == 0) {
                            # no children for current node (or no recursion), just using it and go
                            $self->_next($n);
                            #print STDERR "Found no children: ", $n->name, "\n";
                            last;
                        } else {
                            # Building new frame
                            my $new_frame = $iteratorframe->new(
                                $n,
                                $self,
                                );
                            #print STDERR "Building new frame: ", $new_frame->dump, "\n";
                            $self->_push_frame($self->_cur_frame);
                            $self->_cur_frame($new_frame);
                            if (! $self->postfix) {
                                $self->_next($n);
                                last;
                            } else {
                                $n = $new_frame->next_child;
                            }
                        }
                    }
                } while ($self->uniq && $self->_found($self->_next));
                $self->_mark($self->_next, 1);
                #FIXME# if not a real bloc, accept it
                #last if not $self->_next->isa($iterable);
            } while (
                ($self->with_self || $self->_next != $self->_init_block)
                && !$self->do_filter($self->_next)
                );


            #if ($self->has_next) {
            #    print STDERR "Found: ", $self->_next->name, "\n";
            #}
            #use Data::Dumper;
            #$Data::Dumper::Maxdepth = 3;
            #print STDERR Dumper($self);
        });
    $iteratorclass->add_around_method_modifier(
        'BUILDARGS' => sub {
            my $orig  = shift;
            my $class = shift;
            my $init_block = shift;
            my %args = (@_);

            return $class->$orig(
                @_,
		'_init_block' => $init_block,
                );
        });
    ######################################################
    ######################################################
    # ::Iterator::Frame class
    my $iteratorframeclass = Moose::Meta::Class->create(
        $iteratorframe,
        #attributes => [],
        #roles => [],
        #methods => {},
        superclasses => ["Moose::Object"],
        );
    $iteratorframeclass->add_attribute(
        'current' => (
            is  => 'ro',
            isa => $iterable,
            required => 1,
        ));
    $iteratorframeclass->add_attribute(
        '_children' => (
            traits => [ 'Array' ],
            is  => 'ro',
            isa => "ArrayRef[$iterable]",
            required => 1,
            handles  => {
                'next_child' => 'shift',
                    '_all_children' => 'elements',
            }
        ));
    $iteratorframeclass->add_attribute(
        'it' => (
            is  => 'ro',
            isa => $iterator,
            required => 1,
        ));
    $iteratorframeclass->add_around_method_modifier(
        'BUILDARGS' => sub {
            my $orig  = shift;
            my $class = shift;
            my $current = shift;
            my $it = shift;

            return $class->$orig(
                'current' => $current,
                'it' => $it,
                '_children' => [ $current->children ],
		@_
                );
        });
};

1;

package StorageDisplay::Role::Elem::Kind;

use MooseX::Role::Parameterized;

parameter kind => (
    isa      => 'Str',
    required => 1,
    );

role {
    my $role = shift;

    my $kind = $role->kind;

    around 'BUILDARGS' => sub {
	my $orig  = shift;
	my $class = shift;

	return $class->$orig(@_, 'name_prefix' => $kind);
    };
};

1;

##################################################################
package StorageDisplay::Role::HasBlock;

use Moose::Role;

has 'block' => (
    is       => 'ro',
    isa      => 'StorageDisplay::Block',
    required => 1,
    );

1;

##################################################################
package StorageDisplay::Role::Style::Base;

use Moose::Role;

1;

##################################################################
package StorageDisplay::Role::Style::Base::Elem;

use Moose::Role;

use Carp;

sub dotJoinStyle {
    my $self = shift;
    my $t = shift // "\t";

    return join(';', grep { defined($_) } @_);
}

sub dotIndent {
    my $self = shift;
    my $t = shift // "\t";

    return map { $t.$_ } @_;
}

sub dotLabel {
    my $self = shift;
    return ($self->_dotDefaultLabel(@_));
}

sub dotFullLabel {
    my $self = shift;
    return $self->_dotDefaultFullLabel(@_);
}

sub dotNode {
    my $self = shift;
    #print STDERR "dotNode in ".__PACKAGE__." for ".$self->name."\n";
    return $self->_dotDefaultNode(@_);
}

sub dotStyleNode {
    my $self = shift;
    return $self->_dotDefaultStyleNode(@_);
}

sub dotStyleNodeState {
    my $self = shift;

    return $self->_dotDefaultStyleNodeState;
}

sub dotFormatedFullLabel {
    my $self = shift;
    my $t = shift;

    return join($self->_dotLabelNL,
                $self->dotFullLabel);
}

# default implementations

# will be overrided when a Table is generated
sub _dotTableLabel {
    my $self = shift;
    return $self->dotFormatedFullLabel(@_);
}

sub _dotDefaultLabel {
    my $self = shift;
    return ($self->name);
}

sub _dotDefaultStyleNodeState {
    my $self = shift;

    return ();
}

sub _dotDefaultStyleNode {
    my $self = shift;
    my @style = grep { $_ !~ m/[node]/ } $self->dotStyle(@_);

    push @style, $self->dotStyleNodeState(@_);
    return @style;
}

sub _dotLabelNL {
    my $self = shift;
    return '\n';
}

# will be overrided with Size, Used, Free infos
sub _dotDefaultFullLabel {
    my $self = shift;

    return ($self->dotLabel(@_));
}

# will be overrided for HTML
sub _dotDefaultLabelLine {
    my $self = shift;
    my @label = $self->dotFormatedFullLabel(@_);
    confess "Multiline formated label!" if scalar(@label) > 1;
    return 'label="";' if scalar(@label) == 0;

    return ('label="'.$label[0].'";');
}

# will be overrided when another node kind is selected
sub _dotDefaultNode {
    my $self = shift;
    my $t = shift // "\t";

    #print STDERR "coucou2 from ".$self->name."\n";
    my @text = (
        "{ ".$self->linkname.' [',
        $self->dotIndent(
            $t,
            $self->_dotDefaultLabelLine($t, @_),
            $self->dotStyleNode(),
        ),
        ']; }',
        );
    return @text;
}

1;

##################################################################
package StorageDisplay::Role::Style::Base::HTML;

use Moose::Role;

around '_dotLabelNL' => sub {
    my $orig = shift;
    my $self = shift;
    return '<BR/>';
};

around '_dotDefaultLabelLine' => sub {
    my $orig = shift;
    my $self = shift;
    my $t = shift;

    my @text=$self->dotIndent($t, $self->_dotTableLabel($t, @_));

    if (scalar(@text) == 0) {
        return ('label=<>;')
    }

    $text[0] =~ s/^\s+//;
    $text[0] = 'label=<'.$text[0];
    push @text, '>;';

    return @text;
};

1;

##################################################################
package StorageDisplay::Role::Style::IsLabel;

use Moose::Role;

with (
    'StorageDisplay::Role::Style::Base',
    );

around '_dotDefaultNode' => sub {
    my $orig = shift;
    my $self = shift;

    #print STDERR "coucou from ".$self->name."\n";
    return $self->_dotTableLabel(@_);
};

1;

##################################################################
package StorageDisplay::Role::Style::IsSubGraph;

use Moose::Role;

sub dotSubGraph {
    my $self = shift;
    return $self->_dotDefaultSubGraph(@_);
}

sub _dotDefaultSubGraph {
    my $self = shift;
    my $t = shift;

    my @text;
    my $it = $self->iterator(recurse => 0);
    while (defined(my $e = $it->next)) {
        push @text, $e->dotNode($t, @_);
    }
    return @text;
}

around '_dotDefaultNode' => sub {
    my $orig = shift;
    my $self = shift;
    my $t = shift // "\t";

    my @text = (
        'subgraph "cluster_'.$self->rawlinkname.'" {',
        $self->dotIndent(
            $t,
            $self->dotStyle($t, @_),
            $self->dotSubGraph($t, @_),
            $self->_dotDefaultLabelLine($t, @_),
            $self->dotStyleNode(),
        ),
        '}',
        );
    return @text;
};

around '_dotDefaultStyleNode' => sub {
    my $orig = shift;
    my $self = shift;

    return ();
};

with (
    'StorageDisplay::Role::Style::Base',
    );

1;

##################################################################
package StorageDisplay::Role::Style::Label::HTML;

use Moose::Role;

with (
    'StorageDisplay::Role::Style::Base::HTML',
    'StorageDisplay::Role::Style::Base',
    );

1;

##################################################################
package StorageDisplay::Role::Style::Label::HTML::Table;

use Moose::Role;

sub dotStyleTable {
    return '';
};

around '_dotTableLabel' => sub {
    my $orig = shift;
    my $self = shift;
    my $t = shift;
    my $it = $self->iterator(recurse => 0);

    return ('<TABLE '.$self->dotStyleTable(@_).'>',
            $self->dotIndent(
                $t,
                $self->dotTable($t, $it, @_),
            ),
            '</TABLE>',
        );
};

sub dotTable {
    my $self=shift;

    return $self->_dotDefaultTable(@_);
}

sub _dotDefaultTable {
    my $self=shift;
    my $t = shift;
    my $it = shift;

    my @text;
    while (defined(my $e = $it->next)) {
        push @text, '<TR><TD>',
            $self->dotIndent($t, $e->dotNode($t, @_)),
            '</TD></TR>'
    }

    return @text;
}

with (
    'StorageDisplay::Role::Style::Base::HTML',
    'StorageDisplay::Role::Style::Base',
    );

1;

##################################################################
package StorageDisplay::Role::Style::Plain;

use Moose::Role;

sub dotStyle {
    my $orig  = shift;
    my $self = shift;

    return ( );
};

with (
    'StorageDisplay::Role::Style::Base',
    );

1;

##################################################################
package StorageDisplay::Role::Style::WithSize;

use Moose::Role;

has 'size' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    );

sub dotStyle {
    my $orig  = shift;
    my $self = shift;

    return (
        "style=filled;",
        "color=lightgrey;",
        "fillcolor=lightgrey;",
        "node [style=filled,color=lightgrey,fillcolor=lightgrey,shape=rectangle];",
        );
};

around '_dotDefaultFullLabel' => sub {
    my $orig  = shift;
    my $self = shift;

    return (
        $self->$orig(@_),
        "Size: ".$self->disp_size($self->size),
        );
};

with (
    'StorageDisplay::Role::Style::Base',
    );

1;

##################################################################
package StorageDisplay::Role::Style::WithFree;

use Moose::Role;

with 'StorageDisplay::Role::Style::WithSize';

has 'free' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    );

around _dotDefaultStyleNode => sub {
    my $orig  = shift;
    my $self = shift;

    my $fillcolor='"green"';
    if ($self->size != $self->free) {
        $fillcolor=
            '"pink;'.
                       sprintf("%f.2", ($self->size - $self->free) / $self->size).
                       ':green"';
    }

    return $self->dotJoinStyle(
        $self->$orig(@_),
        'shape=rectangle',
        'style=striped',
        'fillcolor='.$fillcolor,
        );
};

around '_dotDefaultFullLabel' => sub {
    my $orig  = shift;
    my $self = shift;

    return (
        $self->$orig(@_),
        "Free: ".$self->disp_size($self->free),
        );
};

1;

##################################################################
package StorageDisplay::Role::Style::WithUsed;

use Moose::Role;

with 'StorageDisplay::Role::Style::WithFree';

has 'used' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    );

sub dotStyle {
    my $orig  = shift;
    my $self = shift;

    return (
        "style=filled;",
        "color=lightgrey;",
        "fillcolor=lightgrey;",
        "node [style=filled,color=lightgrey,fillcolor=lightgrey,shape=rectangle];",
        );
};

around '_dotDefaultFullLabel' => sub {
    my $orig  = shift;
    my $self = shift;

    my $label = $self->$orig(@_);
    return (
        $self->$orig(@_),
        "Used: ".$self->disp_size($self->used),
        );
};

1;

##################################################################
package StorageDisplay::Role::Style::SubInternal;

use Moose::Role;

sub dotStyle {
    my $self = shift;
    my $t = shift // "\t";

    return (
		#"style=filled;",
		"color=white;",
		"fillcolor=white;",
		#"node [style=filled,color=lightgrey,fillcolor=lightgrey,shape=rectangle];",
        );
}

with (
    'StorageDisplay::Role::Style::Base',
    );

1;

##################################################################
package StorageDisplay::Role::Style::Grey;

use Moose::Role;

sub dotStyle {
    my $self = shift;
    my $t = shift // "\t";

    return (
        "style=filled;",
        "color=lightgrey;",
        "fillcolor=lightgrey;",
        "node [style=filled,color=white,fillcolor=lightgrey,shape=rectangle];",
        );
}

with (
    'StorageDisplay::Role::Style::Base',
    );

1;

##################################################################
package StorageDisplay::Role::Style::Machine;

use Moose::Role;

sub dotStyle {
    my $self = shift;
    my $t = shift // "\t";

    return (
        "style=filled;",
        "color=lightgrey;",
        "fillcolor=white;",
        "node [style=filled,color=white,fillcolor=white,shape=rectangle];",
        );
}

with (
    'StorageDisplay::Role::Style::Base',
    );

1;

##################################################################
package StorageDisplay::Role::Style::FromBlockState;

use Moose::Role;

sub _dotDefaultStyleNodeState {
    my $self = shift;

    my $state = "unknown";
    if (defined($self->block)) {
        $state = $self->block->state;
    }

    return 'fillcolor="'.$self->statecolor($state).'"';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

StorageDisplay::Role - Load all roles used in StorageDisplay

=head1 VERSION

version 1.1.0

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
