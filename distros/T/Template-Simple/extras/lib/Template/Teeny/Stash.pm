package Template::Teeny::Stash;

use Moose;
use Moose::Util::TypeConstraints;

has vars => (is => 'rw', isa => 'HashRef', default => sub { {} });
has _sections => (is => 'rw', isa => 'HashRef[ArrayRef]', default => sub { {} });

sub BUILDARGS { return { vars => ($_[1]||{}) }; }

sub sections { @{ $_[0]->_sections->{$_[1]} || [] }; }
sub add_section {
    my ($self,$sec,@stashes) = @_;
    $self->_sections->{$sec} ||= [];
    push @{ $self->_sections->{$sec} }, (@stashes ? @stashes : undef); 
}

# XXX - add ability to deal with filters here
sub get { 
    # All values return are always strings
    "" . ( $_[0]->vars->{$_[1]} || '' ); 
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=head1 NAME

Template::Teeny::Stash - Object containing stashed variables

=head1 SYNOPSIS

    my $stash = Template::Teeny::Stash->new({
        a => 1,
        ...
    });

    $stash->add_section('section_foo', $other_stash);

Objects of this class store the variables and sections for use with templates.

=head1 METHODS

=head2 new

Basic constructor

=head2 get

 # TODO Add filter support

  $stash->get('variable1');

This returns the variable of the supplied name in this stash.

=head2 add_section

  $stash->add_section('topsection', $other_stash);

This adds a stash to the named section.

=head2 sections

  $stash->sections('somesection');

This returns the stashes that have been added to the named section.

=head2 vars

  $stash->vars();

This is an accessor for the variables associated with this stash.

=head2 BUILDARGS

This is a moose thang.

=cut

