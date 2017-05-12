package Net::ISC::DHCPd::Config::Role;

=head1 NAME

Net::ISC::DHCPd::Config::Role - Role with generic config methods and attributes

=head1 DESCRIPTION

This role contains common methods and attributes for each of the config
classes in the L<Net::ISC::DHCPd::Config> namespace.

=head1 WARNINGS

This module will warn when a line in the input config could not be parsed.
This can be turned off by adding the line below before calling L</parse>.

    no warnings 'net_isc_dhcpd_config_parse';

=cut

use Class::Load;
use Moose::Role;

requires 'generate';

=head1 ATTRIBUTES

=head2 parent

The parent node in the config tree. This must be an object which does
this role.

=cut

has parent => (
    is => 'rw',
    does => 'Net::ISC::DHCPd::Config::Role',
    weak_ref => 1,
);

=head2 root

The root node in the config tree.

=cut

has root => (
    is => 'ro',
    isa => 'Object',
    weak_ref => 1,
    default => sub { $_[0] },
);

=head2 depth

Integer value that counts how far this node is from the root node.

=cut

has depth => (
    is => 'ro',
    isa => 'Int',
    lazy => 1,
    builder => '_build_depth',
);

sub _build_depth {
    my $self = shift;
    my $obj = $self;
    my $i = 0;

    while($obj = $obj->parent) {
        $i++;
        last if($obj == $self->root);
    }

    return $i;
}

=head2 children

Holds a list of possible child objects as objects. This list is used
when L</parse> or L</generate_config_from_children> is called.
The child list has a default value set from L</create_children> in each
of the config modules. This is a static list, which reflects the actual
documentation from C<dhcpd.conf(5)>. Example:

    package Net::ISC::DHCPd::Config::Foo;
    __PACKAGE__->create_children("Net::ISC::DHCPd::Config::Host");

    package main;
    $config = Net::ISC::DHCPd::Config::Foo->new;
    $config->add_host({ ... });
    @host_objects = $config->find_hosts({ ... });
    $config->remove_host({ ... });
    @host_objects = $config->hosts;

The L</create_children> method will autogenerate three methods and an
attribute. The name of the attribute and methods will be the last part
of the config class, with "s" at the end in some cases.

=over 4

=item foos

C<foos> is the name the attribute as well as the accessor. The accessor
will auto-deref the array-ref to a list if called in list context. (yes:
be aware of this!).

=item add_foo

Instead of pushing values directly to the C<foos> list, an C<add_foo>
method is available. It can take either a hash, hash-ref or an object
to add/construct a new child.

=item find_foos

This method will return zero or more objects as a list. It takes
a hash-ref which will be matched against the object attributes of
the children.

=item remove_foo

This method will remove zero or more children from the C<foos> attribute.
The method takes a hash-ref which will be used to match against the
child list. It returns the number of child nodes actually matched and
removed.

=back

=cut

# should be overridden by anything that has children
sub children { }

# actual children
has _children => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
);

=head2 comments

    @str = $self->comments;

Will return all the comments before this element appeared in the config file.
The comments will not contain leading hash symbol spaces, nor trailing newline.

=cut

has _comments => (
    is => 'ro',
    traits => ['Array'],
    init_arg => 'comments',
    default => sub { [] },
    handles => {
        comments => 'elements',
    },
);

=head1 CHILD METHODS

=head2 regex

Regex used to scan a line of config text, which then spawns an
a new node to the config tree. This is used inside l</parse>.

THIS IS A STATIC METHOD.  SELF is not used.

=cut

has _filehandle => (
    is => 'ro',
    lazy_build => 1,
);

sub _build__filehandle {
    my $self = shift;
    my $file;

    # get filehandle from parent to prevent seeking file from beginning
    if(my $parent = $self->parent) {
        return $parent->_filehandle;
    }

    if ($self->fh) {
        return $self->fh;
    }

    $file = $self->file;

    if($file->is_relative and !-e $file) {
        $file = Path::Class::File->new($self->root->file->dir, $file);
    }

    return $file->openr;
}


=head1 METHODS

=head2 BUILD

Used to convert input arguments to child nodes.

=cut

sub BUILD {
    my($self, $args) = @_;
    # skip the expensive method check if called through the parser.  The only
    # time this code applies is with code like add_method( submethod => { } );
    return if ($args->{'parse'});
    my $meta = $self->meta;

    for my $key (sort keys %$args) {
        my $list = $args->{$key};
        my $method = "add_$key";
        $method =~ s/s$//;
        if(ref $list eq 'ARRAY' and $meta->has_method($method)) {
            for my $element (@$list) {
                $self->$method($element);
            }
        }
    }
}

=head2 filename_callback

Callback for changing file paths when include files are on different relative paths.

    # here is an example:
    my $cb = sub {
        my $file = shift;
        print "We're in callback and file is $file\n";
        if ($file =~ /catphotos/) {
            return "/dog.conf";
        }
    };

=cut

has filename_callback => (
    is => 'rw',
    isa => 'CodeRef',
);

=head2 parse

Will read a line of the time from the current config
L<file|Net::ISC::DHCPd::Config::Root/file>. For each line, this method
will loop though each object in L</children> and try to match the line
against a given child and create a new node in the object graph if it
match the L</regex>. This method is called recursively for each child
when possible.

=cut

sub parse {
    my $self = shift;
    my $fh = $_[1];
    my $linebuf = $_[2];
    my($n, @comments);
    my $lines;
    my $line_from_array=0;
    # if $fh is a File::Temp or IO::File object then comparing on assignment
    # above makes it convert to a number (refaddr), which takes 4µs/call
    if (!defined($fh)) {
        $fh = $self->_filehandle;
    }

    LINE:
    while(1) {
        my $line;
        if (defined($linebuf->[0])) {
            $line = pop(@{$linebuf});
            $line_from_array=1;
        } else {
            defined($line = readline $fh) or last LINE;
            $n++;
            chomp $line;
            $line_from_array=0;
            # From here we need to preprocess the line to see if it can be broken
            # into multiple lines.  Something like group { option test; }
            # lines with comments can't be handled by this so we do them first
            if($line =~ /^\s*\#\s*(.*)/) {
                push @comments, $1;
                next LINE;
            }
            # lines with statements and comment, reprocess the statement and add the comment to comments array
            if($line =~ /^(.*)\s*\#\s*(.*)/) {
                push @comments, $2;
                push @{$linebuf}, $1;
                next LINE;
            }

            # after semicolon or braces if there isn't a semicolon or return insert a newline
            if ($line =~ s/([;\{\}])([^;\n\r])/$1\n$2/g) {
                push(@{$linebuf}, reverse split(/\n/, $line));
                next LINE;
            }
        }


        if ($line =~ /^(?:\s*|\s*\{\s*)$/) {
            next LINE;
        }
        elsif($line =~ /^\s*\}\s*$/) {
            next LINE if($self->root == $self);
            last LINE;
        }

        # this is how we handle incomplete lines
        # we need a space for lines like 'option\ndomain-name-servers'
        if ($lines) {
           $lines .= ' '.$line;
        } else {
            $lines = $line;
        }

        CHILD:
        for my $child ($self->children) {
            no strict 'refs';
            my $regex = ${"$child".'::regex'};
            my @c = $lines =~ $regex or next CHILD;
            my $add = 'add_' .lc +($child =~ /::(\w+)$/)[0];
            my $method = $child->can('captured_to_args');
            my $args = $method->(@c);
            my $obj;

            $args->{'comments'} = [@comments];
            $args->{'parse'} = 1;
            @comments = ();
            undef $lines;
            $obj = $self->$add($args);
            $n += $obj->_parse_slurp($fh, $linebuf) if ($obj->can('slurp'));

            # the recursive statement is used for Include.pm
            $n += $obj->parse('recursive', $fh, $linebuf) if(@_ = $obj->children);

            next LINE;
        }

        # if we get here that means our parse failed.  If the incoming line
        # doesn't have a semicolon then we can guess it's a partial line and
        # append the next line to it.
        # we could do this with Slurp but then everything would need to
        # support slurp and odd semicolon handling.  If we figure out a way to
        # merge the lines then the normal parser should be able to cover it.
        if ($lines !~ /;/) {
            next LINE;
        }

        if(warnings::enabled('net_isc_dhcpd_config_parse')) {
            warn sprintf qq[Could not parse "%s" at %s line %s\n],
                $line,
                $self->root->file,
                $fh->input_line_number
                ;
        }
    }

    return $n ? $n : '0e0';
}

=head2 _parse_slurp

This is a simplified parser for the slurp method.  It's only used when slurp
is available in a child method.

=cut


sub _parse_slurp {
    my $self = shift;
    my $fh = shift;
    my $linebuf = shift;
    my($n, @comments);

    LINE:
    while(1) {
        my $line;
        if (defined($linebuf->[0])) {
            $line = pop(@{$linebuf});
        } else {
            defined($line = readline $fh) or last LINE;
            $n++;
            chomp $line;
        }


        if($self->can('slurp')) {
            my $action = $self->slurp($line); # next or last
            if($action eq 'next') {
                next LINE;
            }
            elsif($action eq 'last') {
                last LINE;
            }
            elsif($action eq 'backtrack') {
                push(@{$linebuf}, $line);
                last LINE;
            }
        }
    }
    return $n;
}

=head2 captured_to_args

 $hash_ref = $self->captured_to_args(@list);

Called when a L</regex> matches, with a list of captured strings.
This method then returns a hash-ref passed on to the constructor when
a new node in the object graph is constructed.

THIS IS A STATIC METHOD.  SELF is not used.

=cut

sub captured_to_args {
    return {};
}

=head2 create_children

This method takes a list of classes, and creates builder method for
the L</children> attribute, an attribute and helper methods. See
L</children> for more details.

=cut

sub create_children {
    my $self = shift;
    my $meta = $self->meta;
    my @children = @_;

    for my $class (@children) {
        my $name = lc (($class =~ /::(\w+)$/)[0]);
        my $attr = $name .'s';

        # hack so the child method for class is classes instead of classs
        $attr = $name . 'es' if ($name =~ /s$/);


        Class::Load::load_class($class);

        unless($meta->find_method_by_name($attr)) {
            $meta->add_method("add_${name}" => sub { shift->_add_child($class, @_) });
            $meta->add_method("find_${attr}" => sub { shift->_find_children($class, @_) });
            $meta->add_method("remove_${attr}" => sub { shift->_remove_children($class, @_) });
            $meta->add_method($attr => sub {
                my $self = shift;
                return $self->_set_children($class, @_) if(@_);
                return $self->_get_children_by_class($class);
            });
        }
    }

    return \@children;
}

sub _set_children {
    my($self, $attr, $class, $children) = @_;

    for my $child (@$children) {
        $child = $class->new(parent => $self, root => $self->root, %$child) if(ref $child eq 'HASH');
    }

    @{ $self->_children } = @$children;
}

sub _get_children_by_class {
    my($self, $class) = @_;
    my @children = grep { $class eq ref $_ } @{ $self->_children };

    return wantarray ? @children : \@children;
}

sub _add_child {
    my $self = shift;
    my $class = shift;
    my $child = @_ == 1 ? $_[0] : {@_};
    my $children = $self->_children;

    if(ref $child eq 'HASH') {
        $child = $class->new(parent => $self, root => $self->root, %$child);
    }

    push @$children, $child;
    return $child;
}

sub _find_children {
    my($self, $class, $query) = @_;
    my @children;

    if(ref $query ne 'HASH') {
        return;
    }

    CHILD:
    for my $child (@{ $self->_children }) {
        if($class ne ref $child) {
            next CHILD;
        }
        for my $key (keys %$query) {
            next CHILD unless($child->$key eq $query->{$key});
        }
        push @children, $child;
    }

    return @children;
}

sub _remove_children {
    my $self = shift;
    my $class = shift;
    my $query = shift or return;
    my $children = $self->_children;
    my $i = 0;
    my @removed;

    CHILD:
    while($i < @$children) {
        if($class ne ref $children->[$i]) {
            next CHILD;
        }
        for my $key (keys %$query) {
            next CHILD unless($children->[$i]->$key eq $query->{$key});
        }
        push @removed, splice @$children, $i, 1;
        $i--;
    } continue {
        $i++;
    }

    return @removed;
}


=head2 find_all_children

Loops through all child nodes with recursion looking for nodes of "class"
type.  Returns an array of those nodes.  You can use the full classname or
just the end part.  For subclasses like Host::FixedAddress you would need to
use the whole name.

    my @subnet = $config->find_all_children('subnet');

=cut

sub find_all_children {
    my $self = shift;
    my $class = shift;
    my @children;

    if ($class !~ /::/) {
        # strip plural if they put it.
        $class =~ s/s\z//;
        $class =~ s/(class|address)e/$1/;
        $class = 'Net::ISC::DHCPd::Config::' . ucfirst(lc($class));
    }

    for my $child (@{ $self->_children }) {
        if (ref($child) eq $class) {
            push(@children, $child);
        }

        if ($child->_children) {
            push(@children, $child->find_all_children($class));
        }
    }
    return @children;
}

=head2 generate_config_from_children

Loops all child nodes in reverse order and calls L</generate> on each
of them. Each L</generate> method must return a list of strings which
will be indented correctly and concatenated with newline inside this
method, before returned as one string.

=cut

sub generate_config_from_children {
    return join "\n", shift->_generate_config_from_children;
}

sub _generate_config_from_children {
    my $self = shift;
    my $indent = '';
    my @text;

    if($self->parent and !$self->can('generate_with_include')) {
        $indent = ' ' x 4;
    }

    for my $child (@{ $self->_children }) {
        push @text, map { "$indent# $_" } $child->comments;
        push @text, map { "$indent$_" } $child->generate;
    }

    return @text;
}

=head2 generate

A C<generate()> must be defined in the consuming class. This method
must return a list of lines (zero or more), which will be indented
and concatenated inside L</generate_config_from_children>.

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut

package # hack to register a new warnings category
    net_isc_dhcpd_config_parse;
use warnings::register;

1;
