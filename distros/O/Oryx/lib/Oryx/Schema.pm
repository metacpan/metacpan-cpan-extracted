package Oryx::Schema;

use base qw(Class::Data::Inheritable);

=head1 NAME

Oryx::Schema - Schema class for Oryx

=head1 SYNOPSIS

  package CMS::Schema;
 
  # enable auto deploy for all classes 
  use Oryx::Class(auto_deploy => 1);
   
  # useful if you want to say $storage->deploySchema('CMS::Schema');
  use CMS::Page;
  use CMS::Paragraph;
  use CMS::Image;
  use CMS::Author;
   
  sub prefix { 'cms' }

  1;

  #==================================================================
  # ALTERNATIVE - With XML::DOM::Lite installed
  #==================================================================
  package CMS::Schema;
  use base qw(Oryx::Schema);
  1;
  __DATA__
  <Schema>
    <Class name="CMS::Page">
      <Attribute name="title" type="String"/>
      <Attribute name="num" type="Integer"/>
      <Association role="author" class="CMS::Author"/>
    </Class>
    <Class name="CMS::Author">
      <Attribute name="first_name" type="String"/>
      <Attribute name="last_name" type="String"/>
    </Class>
  </Schema>
  use CMS::Schema;
   
  my $cms_storage = Oryx->connect(\@conn, 'CMS::Schema'); 
  CMS::Schema->addClass('CMS::Revision');
  my @cms_classes = CMS::Schema->classes;
  $cms_storage->deploySchema();                 # deploys only classes seen by CMS::Schema
  $cms_storage->deploySchema('CMS::Schema')     # same thing, but `use's CMS::Schema first
  my $name = CMS::Schema->name;                 # returns CMS_Schema
  CMS::Schema->hasClass($classname);            # true if seen $classname
  

=head1 DESCRIPTION

Schema class for Oryx.

The use of this class is optional.

The intention is to allow arbitrary grouping of classes
into different namespaces to support simultaneous use of
different storage backends, or for having logically separate
groups of classes in the same database, but having table
names prefixed to provide namespace separation.

=cut

__PACKAGE__->mk_classdata('_classes');
__PACKAGE__->mk_classdata('_name');

sub new {
    my $class = shift;
    $class->_classes({ }) unless defined $class->_classes;
    return bless { }, $class;
}

sub name {
    my $self = shift;
    if (@_) {
        $_[0] =~ s/::/_/g;
        $self->_name($_[0]);
    }
    unless ($self->_name) {
        my $name = ref($self) || $self;
        $name =~ s/::/_/g;
        $self->_name($name);
    }
    return $self->_name;
}

sub prefix {
    my $self = shift;
    if (@_) {
        $self->{prefix} = shift;
    }
    unless (defined $self->{prefix}) {
        $self->{prefix} = '';
    }
    return $self->{prefix};
}

sub classes {
    my @gens = grep { UNIVERSAL::isa($_, 'Oryx::Schema::Generator') } @INC;
    foreach my $gen (@gens) { $gen->requireAll() }
    keys %{$_[0]->_classes};
}

sub addClass {
    my ($self, $class) = @_;
    $self->_classes->{$class}++;
}

sub hasClass {
    return shift->class(@_);
}

sub class {
    my $class = $_[0]->_classes->{$_[1]};
    return $class;
}

sub loadXML {
    my $self = shift;
    my $xstr = shift;
    use XML::DOM::Lite::Parser;
    use Oryx::Schema::Generator;

    my $parser = XML::DOM::Lite::Parser->new( whitespace => 'strip' );
    my $doc  = $parser->parse( $xstr );

    push @INC, Oryx::Schema::Generator->new( $doc );
}

sub import {
    my $class = shift;
    my $fh = *{"$class\::DATA"}{IO};
    return undef unless $fh;
    local $/ = undef;
    my $data = <$fh>;
    if ($data) {
	$class->loadXML($data);
    }
}

1;

=head1 SEE ALSO

L<Oryx>, L<Oryx::Class>

=head1 AUTHOR

Copyright (C) 2005 Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 LICENSE

This library is free software and may be used under the same terms as Perl itself.

=cut
