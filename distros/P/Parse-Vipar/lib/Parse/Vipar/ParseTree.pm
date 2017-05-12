# -*- cperl -*-

require Tk;

package Parse::Vipar::ParseTree;
use strict;
use Tk::Tree;
use Carp;

use base 'Tk::Tree';
Construct Tk::Widget 'ParseTree';
use Tk::English;

sub ClassInit
{
    my ($class,$mw) = @_;
    $class->SUPER::ClassInit($mw);
    return $class;
}

sub InitObject {
    my ($super, $args) = @_;
#    die "Must use two columns"
#      if exists $args->{'-columns'} && $args->{'-columns'} != 2;
#    $args->{'-columns'} = 2;
    $super->SUPER::InitObject($args);
}

# Push a toplevel entry
sub push {
    my ($self, $symstr, $val) = @_;
    my $name = $symstr;
    my $on = $name;
#    print "$on -> $name\n" if
    $name =~ s/[\W.]/-/g;
    $self->{name_counters}->{$name}++;
    my $label = $self->add("${name}_".$self->{name_counters}->{$name},
                           -data => $val);
#    print "$label added as toplevel node\n";
    $self->itemCreate($label, 0, -text => $symstr);
    $self->itemCreate($label, 1, -text => $val);
    $self->setmode($label, "none");
    return $label;
}

sub _pushCapturedChild {
    my ($self, $parent, $kid) = @_;
    croak "not a capturedEntry($kid)" if ref $kid ne 'capturedEntry';
    my $label = $self->addchild($parent);
#    print "$label added as child of $parent\n";

    my $mode = $kid->[0]->{-mode};
    delete $kid->[0]->{-mode};
    for my $col (0 .. $#$kid) {
        $self->itemCreate($label, $col, %{ $kid->[$col] });
    }

    $self->setmode($label, $mode);

    return $label;
}

# Returns: [ colnum => { option => value } ]
sub _captureEntry {
    my ($self, $entrypath) = @_;
    my $entry = bless [], 'capturedEntry';
    my $col = 0;
    while (eval { $self->itemExists($entrypath, $col) }) {
        my %options = map { $_->[0] => $_->[4] }
                          $self->itemConfigure($entrypath, $col);
        $entry->[$col] = \%options;
        $col++;
    }

    $entry->[0]->{-mode} = $self->getmode($entrypath);
    return $entry;
}

sub getEntries {
    my ($self, $pattern) = @_;
    my $node = $self->info('root');
    my @entries = ($node);
    push(@entries, $node) while $node = $self->info('next', $node);

    return @entries if !defined $pattern;
    $pattern = qr/$pattern/ if !ref $pattern;

    return grep { $_ =~ $pattern } @entries
        if (UNIVERSAL::isa($pattern, 'Regexp'));

    return grep { $pattern->($_) } @entries
        if (UNIVERSAL::isa($pattern, 'CODE'));

    die "Unknown pattern type for $pattern";
}

# Returns: [ node, child0, child1, ... ]
sub _getSubTree {
    my ($self, $entry) = @_;
    my $node = $self->_captureEntry($entry);
    my @children = map { $self->_getSubTree($_) }
                       $self->info('children', $entry);
    my $subtree = bless [ $node ], 'subtree';
    push(@$subtree, @children);
    return $subtree;
}

sub _addSubTree {
    my ($self, $parent, $subtree) = @_;
    croak "not a subtree" if ref $subtree ne 'subtree';
    my $node = $subtree->[0];
#    print "node=$node\n";
    $node = $self->_pushCapturedChild($parent, $node);
    my @kids = @$subtree;
    shift(@kids);
#    print "subtree=$_\n" foreach (@kids);
    $self->_addSubTree($node, $_) foreach (@kids);
}

# Change NODE's parent to NEWPARENT
sub reparent {
    my ($self, $node, $newparent) = @_;
    my $subtree = $self->_getSubTree($node);
    $self->delete('entry', $node);
    $self->_addSubTree($newparent, $subtree);
}

# Pop off the last N toplevels, push SYMSTR=VAL, and put the popped
# symbols in as children under the new node. There ought to be a much
# more direct way to do this.
sub reduce {
    my ($self, $n, $symstr, $val) = @_;

    my @tops = $self->info('children');
#    print "tops = ".join(" ", @tops)."\n";
    my @popped = $n ? splice(@tops, -$n) : ();
#    print "popped = ".join(" ", @popped)."\n";
    my $lhs = $self->push($symstr, $val);
#    print "reduced to $lhs\n";
    $self->reparent($_, $lhs) foreach (@popped);
    $self->setmode($lhs, "close") if @popped;
    $self->close($lhs) if @popped;
}

1;
