# $Id: /mirror/coderepos/lang/perl/MooseX-DOM/trunk/lib/MooseX/DOM/LibXML.pm 68283 2008-08-12T02:34:53.003080Z daisuke  $

package MooseX::DOM::LibXML;
use Moose::Role;
use MooseX::DOM::LibXML::ContextNode;
use MooseX::DOM::Meta::LibXML;

use constant DEFAULT_NAMESPACE_PREFIX => "#default";

has 'node' => (
    is => 'rw',
    isa => 'MooseX::DOM::LibXML::ContextNode',
);

has 'namespaces' => (
    is => 'rw',
    isa => 'HashRef',
    required => 1,
    default => sub { +{} }
);

no Moose;

sub init_meta {
    # Only MooseX::DOM knows the true caller, so we expect it to
    # provide us with one
    my ($class, $caller) = @_;

    Moose::init_meta( 
        $caller, 
        undef,
        'MooseX::DOM::Meta::LibXML'
    );
}

sub BUILDARGS {
    my ($self, %args) = @_;

    my $namespaces = $args{namespaces} || {};
    my $node = delete $args{node};
    if ($node) {
        if (! ref $node) {
            $node = MooseX::DOM::LibXML::ContextNode->new(
                node => XML::LibXML->new->parse_string($node)->documentElement,
                namespaces => $namespaces
            );
        } elsif ($node->isa('XML::LibXML::Element')) {
            $node = MooseX::DOM::LibXML::ContextNode->new(
                node => $node,
                namespaces => $namespaces
            );
        } else {
            confess "Don't know how to handle $node";
        }

        $args{node} = $node;
    }

    return  { %args };
}

BOOTSTRAP: {
    my $subname = sub { join('::', $_[1] || __PACKAGE__, $_[0]) };
    my $subassign = sub {
        no strict 'refs';
        *{$_[0]} = Class::MOP::subname($_[0], $_[1]);
    };

    # Used to convert element node to its text content
    my $textfilter = sub {
        my $self = shift;
        return map { blessed $_ && $_->can('textContent') ? $_->textContent : $_ } @_;
    };

    # Used only in has_dom_children, to create a list of element nodes from
    # list of text
    my $text2elements = Class::MOP::subname($subname->('text2elements') => sub {
        my($self, %args) = @_;

        my $values = $args{values};
        my $namespace = $args{namespace};
        my $tag = $args{tag};

        my $node = $self->node;

        my $nsuri = $self->namespaces->{ $namespace };
        my $document = $node->ownerDocument;
        my @children;
        foreach my $data (@$values) {
            my $child = ($nsuri) ?
                $document->createElementNS($nsuri, $tag) :
                $document->createElement($tag)
            ;
            $child->appendTextNode($data);
            push @children, $child;
            $node->appendChild($child);
        }
        return @children;
    });

    my %exports = (
        has_dom_root => sub {
            return Class::MOP::subname($subname->('has_dom_root') => sub ($;%) {
                my $caller = caller();
                my ($tag, %args) = @_;
                # tag => $tag
                # attributes => { attr1 => $val1, attr2 => $val2 }

                $tag = $args{tag} if $args{tag};
                my $attrs = $args{attributes};

                my $meta = $caller->meta;
                $meta->dom_root( { tag => $tag, attributes => $attrs } );

                # This needs to be done here so that the /applied/ class
                # can use it instead of this class, which is a role
                $meta->add_around_method_modifier(new => sub {
                    my $next = shift;
                    my $self = $next->(@_);
                    $self->meta->assert_root_node($self);
                    return $self;
                });
                $meta->add_after_method_modifier(node => sub {
                    my $self = shift;
                    if (@_) {
                        $self->meta->assert_root($self, @_);
                    }
                });
            });
        },
        has_dom_content => sub {
            return Class::MOP::subname($subname->('has_dom_content') => sub ($) {
                my $caller = caller();
                my $name = shift;
                my $method = $subname->($name, $caller);
                $subassign->($method => sub {
                    my $self = shift;
                    my $node = $self->node;
                    return () unless $node;

                    if (@_) {
                        $node->removeChildNodes();
                        $node->appendText($_[0]);
                    }

                    return $node->textContent;
                } );
            });
        },
        has_dom_attr => sub {
            return Class::MOP::subname($subname->('has_dom_attr') => sub ($;%) {
                my $caller = caller();
                my ($name, %args) = @_;

                if ($args{accessor}) {
                    $name = $args{accessor};
                }

                $caller->meta->register_dom_attribute( $name );

                my $method = $subname->($name, $caller);
                $subassign->($method => sub {
                    my $self = shift;
                    my $meta = $self->meta;
                    if (@_) {
                        $meta->set_dom_attribute( $self, $name, $_[0] );
                    }
                    return $meta->get_dom_attribute( $self, $name );
                });
            });
        },
        has_dom_children => sub {
            return Class::MOP::subname($subname->('has_dom_children') => sub ($;%) {
                my $caller = caller();
                my($name, %args) = @_;
                my $namespace = $args{namespace} ||= DEFAULT_NAMESPACE_PREFIX;
                my $tagname   = $args{tag} || $name;
                my $filter    = $args{filter} || $textfilter;
                my $create    = $args{create} || $text2elements;
                if ($args{accessor}) {
                    $name = $args{accessor};
                }

                $caller->meta->register_dom_child( $name => {
                    tag => $tagname,
                    namespace => $namespace,
                    filter => $filter,
                    create => $create
                } );

                my $method = $subname->($name, $caller);

                # list accessor
                $subassign->($method => sub {
                    my $self = shift;
                    my $meta = $self->meta;
                    if (@_) {
                        $meta->set_dom_children( $self, $name, @_ );
                    }

                    return $meta->get_dom_children( $self, $name );
                });
            });
        },
        has_dom_child => sub {
            return Class::MOP::subname($subname->('has_dom_child') => sub ($;%) {
                my $caller = caller();
                my ($name, %args) = @_;

                my $namespace = $args{namespace} ||= DEFAULT_NAMESPACE_PREFIX;
                my $tagname   = $args{tag} || $name;
                my $filter    = $args{filter} || $textfilter;
                my $create    = $args{create} || $text2elements;
                if ($args{accessor}) {
                    $name = $args{accessor};
                }

                $caller->meta->register_dom_child( $name => {
                    tag => $tagname,
                    namespace => $namespace,
                    filter => $filter,
                    create => $create
                } );

                my $method = $subname->($name, $caller);
                $subassign->($method => sub {
                    my $self = shift;
                    my $meta = $self->meta;
                    if (@_) {
                        $meta->set_dom_children( $self, $name, @_ );
                    }

                    my @ret = $meta->get_dom_children( $self, $name );
                    return $ret[0];
                } );
            });
        }
    );

    my $export = Sub::Exporter::build_exporter({
        exports => \%exports,
        groups  => { default => [ ':all' ] }
    });
    sub export_dsl {
        goto &$export if $export;
    }

    sub unexport_dsl {
        no strict 'refs';
        my $class = caller();

        # loop through the exports ...
        foreach my $name ( keys %exports ) {

            # if we find one ...
            if ( defined &{ $class . '::' . $name } ) {
                my $keyword = \&{ $class . '::' . $name };

                # make sure it is from Moose
                my ($pkg_name) = Class::MOP::get_code_info($keyword);
                next if $pkg_name ne __PACKAGE__;

                # and if it is from Moose then undef the slot
                delete ${ $class . '::' }{$name};
            }
        }
    }
}

sub from_xml {
    my $class = shift;
    return $class->new(node => XML::LibXML->new->parse_string($_[0])->documentElement);
}
sub from_file {
    my $class = shift;
    return $class->new(node => XML::LibXML->new->parse_file($_[0])->documentElement);
}

sub as_xml {
    my $self = shift;
    $self->node->toString(1);
}


1;

