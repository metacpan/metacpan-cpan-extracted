package MsOffice::Word::Template::Engine;
use 5.024;
use Moose;
use MooseX::AbstractMethod;

# syntactic sugar for attributes
sub has_slot ($@) {my $attr = shift; has($attr => @_, is => 'bare', init_arg => undef)}

use namespace::clean -except => 'meta';

our $VERSION = '2.0';

#======================================================================
# ATTRIBUTES
#======================================================================

has_slot '_constructor_args'  => (isa => 'HashRef');
has_slot '_compiled_template' => (isa => 'HashRef');

#======================================================================
# ABSTRACT METHODS -- to be defined in subclasses
#======================================================================

abstract 'start_tag';
abstract 'end_tag';
abstract 'compile_template';
abstract 'process';

#======================================================================
# INSTANCE CONSTRUCTION
#======================================================================


sub BUILD {
  my ($self, $args) = @_;
  $self->{_constructor_args} = $args; # stored to be available for lazy attr constructors
}


1;

__END__

=encoding ISO-8859-1

=head1 NAME

MsOffice::Word::Template::Engine -- abstract class for template engines

=head1 DESCRIPTION

This class does nothing; it just declares a couple of generic attributes 
and methods to be implemented by engine subclasses.
See for example the L<MsOffice::Word::Template::Engine::TT2> subclass.




