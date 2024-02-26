package Pod::Elemental::Transformer::Cowl_GenDoc;
# ABSTRACT: Transformer for Cowl generated docs links

use Moose;
use Pod::Elemental::Transformer 0.101620;
with 'Pod::Elemental::Transformer';

use Pod::Elemental::Element::Pod5::Command;

use namespace::autoclean;

has command_name => (
  is  => 'ro',
  init_arg => undef,
);

sub transform_node {
  my ($self, $node) = @_;

  for my $i (reverse(0 .. $#{ $node->children })) {
    my $para = $node->children->[ $i ];
    next unless $self->__is_xformable($para);
    my @replacements = $self->_expand( $para );
    splice @{ $node->children }, $i, 1, @replacements;
  }
}

my $command_dispatch = {
  'cowl_gendoc'     => \&_expand_cowl_gendoc,
};

sub __is_xformable {
  my ($self, $para) = @_;

  return unless $para->isa('Pod::Elemental::Element::Pod5::Command')
         and exists $command_dispatch->{ $para->command };

  return 1;
}

sub _expand {
  my ($self, $parent) = @_;
  $command_dispatch->{ $parent->command }->( @_ );
};

sub _expand_cowl_gendoc {
  my ($self, $parent) = @_;
  my @replacements;

  my $content = $parent->content;

  my @ids = split /,\s*/, $content;
  my $doc_name = 'RDF::Cowl::Lib::Gen::Class::';
  my $new_content = <<~EOF =~ s/\n*\z//sr;
  See more documentation at:

  @{[ join ", ", map {
      "L<${doc_name}$_>"
    } @ids
  ]}

  EOF

  push @replacements,
    Pod::Elemental::Element::Pod5::Command->new({
      command => 'head1',
      content => "GENERATED DOCUMENTATION\n",
    }),
    Pod::Elemental::Element::Pod5::Ordinary->new(
      content => $new_content,
    );

  return @replacements;
}

1;
