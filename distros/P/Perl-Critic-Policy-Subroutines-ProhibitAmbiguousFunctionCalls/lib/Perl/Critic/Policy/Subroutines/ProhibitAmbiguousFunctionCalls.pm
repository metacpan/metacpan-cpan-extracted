package Perl::Critic::Policy::Subroutines::ProhibitAmbiguousFunctionCalls;

use strict;
use warnings;
use Digest::MD5;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.002';

use constant DESC => q{Fully qualified functions calls should end in parens.};
use constant EXPL => q{To differentiate from class methods and function calls, use Foo:Bar::baz()->gimble};

use constant default_severity => $SEVERITY_HIGH;
use constant default_themes   => qw( core );
use constant applies_to       => ('PPI::Statement');

use constant supported_parameters => ({
        name           => 'methods_always_ok',
        default_string => 'new add',
        description    => 'Names of methods which never trigger this policy',
        behavior       => 'string list',
    },
    {
        name           => 'uppercase_module_always_ok',
        description    => 'Indicates if Foo::Bar->baz is always ok because of the capital F',
        default_string => 1,
        behavior       => 'boolean',
    },

);

my ($docinfo, $file);

sub violates {

    my ($self, $elem, $doc) = @_;

    ## Workaround a slight bug in Perl::Critic
    return if ref $elem eq 'PPI::Statement::Null';

    ## We never want to consider elements in the END section
    return if ref $elem eq 'PPI::Statement::End';

    ## We may not have a filename, so we need some unique identifier
    $file = $doc->filename() // Digest::MD5::md5_hex($doc->content());

    ## We need to walk through the whole document, but only the first time we are called per file
    if (!defined $docinfo->{$file}) {
        $docinfo->{$file} = {};
        my $realdoc = $doc->ppi_document;
        ## This will set elements to matched
        $self->_kidwalk($realdoc);
    }

    my $elemid = $self->_nodeid($elem);
    if (!exists $docinfo->{$file}{$elemid}) {
        warn "No element found for $elemid";    ## Should not happen
        return;
    }

    ## If we have already marked this one, return a violation
    if ($docinfo->{$file}{$elemid}) {
        return $self->violation(DESC, EXPL, $elem);
    }

    return;
}

sub _match {

    ## Given a PPI::Node, see if it matches our criteria
    ## Returns 0 or 1

    my ($self, $lkid) = @_;

    ## We only care about things like Foo::Bar::Baz->gimble
    return 0 unless $lkid =~ / (\w+(?: ::\w+)+) -> (.+)/x;

    my ($module, $name) = ($1, $2);

    ## Some method names are always allowed
    return 0 if exists $self->{_methods_always_ok}{$name};

    ## Uppercase final part of module name may be ok
    return 0 if $module =~ /::[A-Z]\w+$/ and $self->{_uppercase_module_always_ok};

    return 1;
}

sub _kidwalk {

    ## Given a PPI::Node, recursively check all of its kids for a match

    my ($self, $parent) = @_;
    my @kids = $parent->schildren();

    for my $kid (@kids) {

        ## Build a unique ID for this node
        my $kidid = $self->_nodeid($kid);

        ## See if this chunk of code violated our Perl::Critic policy
        my $found_match = $self->_match($kid);
        $docinfo->{$file}{$kidid} = $found_match;

        ## If any ancestors have already found this match, remove it!
        ## As children content is always a subset of the parent's content, this is safe
        if ($found_match) {
            my $parentid = $self->_nodeid($kid->parent);
            $docinfo->{$file}{$parentid} = 0;
        }

        ## Some nodes do not have children, but if they do, recurse through them
        $self->_kidwalk($kid) if $kid->can('schildren');
    }

    return;

}

sub _nodeid {

    ## Given a PPI::Node, generate a unique ID for it

    my ($self, $node) = @_;

    ## Because the location() is a little different when coming
    ## via 'elem' vs 'doc', we replace some items
    my $locinfo = $node->location;
    $locinfo->[1] = ref $node;
    $locinfo->[2] = $node->can('schildren') ? $node->schildren : 0;
    return join ';' => map { $_ // 'NULL' } @$locinfo;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitAmbiguousFunctionCalls - Don't call fully qualified function methods without parens

=head1 DESCRIPTION

When writing code like this...

  Some::Class::Name::foo->mymethod

..it is not clear if 'foo' is part of the class, or a function within Some::Class::Name.
The better way to write it is:

  Some::Class::Name::foo()->method

=head1 CONFIGURATION

=over 4

=item C<method_always_ok> (string list, default is "new add")

A list of method names which should always be considered "ok"

=item C<uppercase_module_always_ok> (boolean, defaults to true)

Indicates whether module names starting with an uppercase letter are considered "ok".

For example, Foo::Bar->pop; is considered ok by default, but Foo::bar->pop is not.

=back
