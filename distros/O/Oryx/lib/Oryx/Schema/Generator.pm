package Oryx::Schema::Generator;

use Oryx::Schema::Stub;
use XML::DOM::Lite qw(:constants);

sub new {
    my ($class, $xmldoc) = @_;

    my $self = bless { xmldoc => $xmldoc }, $class;
    $self->{_classes} = { };

    foreach (@{ $xmldoc->documentElement->childNodes }) {
	$self->{_classes}->{$_->getAttribute("name")} = $_;
    }

    return $self;
}

sub Oryx::Schema::Generator::INC {
    my ($self, $filename) = @_;
    my $class = "$filename";
    $class =~ s/\//::/g;
    $class =~ s/\.pm$//;
    my $node = $self->{_classes}->{$class};

    if ( $node ) {
	my $stub = $INC{'Oryx/Schema/Stub.pm'};
	$INC{$filename} = $stub;

	$self->load_class($class, $node);
	open DEVNULL, "<$stub";
	return \*DEVNULL;
    }

    return undef;
}

sub load_class {
    my ($self, $class, $node) = @_;
    my $pkg = qq{
package $class;
use base qw(Oryx::Class);
};
    $self->generate($class, $node);
    eval $pkg; die $@ if $@;
}

sub generate {
    my ($self, $class, $node) = @_;

    my $schema = { attributes => [ ], associations => [ ] };
    no strict 'refs';
    foreach my $n (@{$node->childNodes}) {
        if ($n->nodeType == ELEMENT_NODE) {
            if ($n->nodeName eq 'Attribute') {
                push @{$schema->{attributes}}, {
                    name => $n->getAttribute('name'),
                    type => $n->getAttribute('type'),
                };
            } elsif ($n->nodeName eq 'Association') {
                push @{$schema->{associations}}, {
                    class => $n->getAttribute('class'),
                    role  => $n->getAttribute('role'),
                    type  => $n->getAttribute('type'),
                };
            } elsif ($n->nodeName eq 'Parent') {
                push @{$class.'::ISA'}, $n->getAttribute('class');
            }
        }
    }
    no warnings 'once';
    ${$class.'::schema'} = $schema;
    return $schema;
}

sub requireAll {
    my $self = shift;
    foreach (keys %{$self->{_classes}}) {
	eval "use $_"; die $@ if $@;
    }
}

1;
