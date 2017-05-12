package Pod::Weaver::Section::Region;
# ABSTRACT: find a region and put its contents in place where desired
$Pod::Weaver::Section::Region::VERSION = '4.015';
use Moose;
with 'Pod::Weaver::Role::Section';

#pod =head1 OVERVIEW
#pod
#pod This section will find and include a located hunk of Pod.  In general, it will
#pod find a region with the specified name, such as:
#pod
#pod   =begin :myfoo
#pod
#pod   =head1 More Pod Here
#pod
#pod   =end :myfoo
#pod
#pod In other words, if your configuration include:
#pod
#pod   [Region]
#pod   region_name = myfoo
#pod
#pod ...then this weaver will look for "=begin :myfoo" ( and "=for :myfoo" and... ) and include
#pod it at the appropriate location in your output.
#pod
#pod Since you'll probably want to use Region several times, and that will require
#pod giving each use a unique name, you can omit C<region_name> if you provide a
#pod plugin name, and it will default to the plugin name.  In other words, the
#pod configuration above could be specified just as:
#pod
#pod   [Region / myfoo]
#pod
#pod If the C<required> attribute is given, and true, then an exception will be
#pod raised if this region can't be found.
#pod
#pod =cut

use Pod::Elemental::Element::Pod5::Region;
use Pod::Elemental::Selectors -all;
use Pod::Elemental::Types qw(FormatName);

#pod =attr required
#pod
#pod A boolean value specifying whether this region is required to be present or not. Defaults
#pod to false.
#pod
#pod If it's enabled and the region can't be found an exception will be raised.
#pod
#pod =cut

has required => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

#pod =attr region_name
#pod
#pod The name of this region. Defaults to the plugin name.
#pod
#pod =cut

has region_name => (
  is   => 'ro',
  isa  => FormatName,
  lazy => 1,
  required => 1,
  default  => sub { $_[0]->plugin_name },
);

#pod =attr allow_nonpod
#pod
#pod A boolean value specifying whether nonpod regions are allowed or not. Defaults to false.
#pod
#pod C<nonpod> regions are regions I<without> a C<:> prefix as explained in
#pod L<< perlpodspec|perlpodspec/About Data Paragraphs and "=begin/=end" Regions >>
#pod
#pod   # region_name = myregion
#pod   # is_pod = false
#pod   =begin myregion
#pod
#pod   # region_name = myregion
#pod   # is_pod = true
#pod   =begin :myregion
#pod
#pod =cut

has allow_nonpod => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

#pod =attr flatten
#pod
#pod A boolean value specifying whether the region's contents should be flattened or not. Defaults to true.
#pod
#pod   #unflattened
#pod   =begin :myregion
#pod
#pod   =head1
#pod
#pod   =end :myregion
#pod
#pod   #flattened
#pod   =head1
#pod
#pod =cut

has flatten => (
  is  => 'ro',
  isa => 'Bool',
  default => 1,
);

sub weave_section {
  my ($self, $document, $input) = @_;

  my @to_insert;

  my $idc = $input->{pod_document}->children;
  IDX: for (my $i = 0; $i < @$idc; $i++) {
    next unless my $para = $idc->[ $i ];
    next unless $para->isa('Pod::Elemental::Element::Pod5::Region')
         and    $para->format_name eq $self->region_name;
    next if     !$self->allow_nonpod and !$para->is_pod;

    if ( $self->flatten ) {
      push @to_insert, @{ $para->children };
    } else {
      push @to_insert, $para;
    }

    splice @$idc, $i, 1;

    redo IDX;
  }

  confess "Couldn't find required Region for " . $self->region_name . " in file "
    . (defined $input->{filename} ? $input->{filename} : '') if $self->required and not @to_insert;

  my $verb = $self->flatten ? 'flattening' : 'inserting';
  $self->log_debug($verb . q{ } . $self->region_name . ' into pod');
  push @{ $document->children }, @to_insert;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Region - find a region and put its contents in place where desired

=head1 VERSION

version 4.015

=head1 OVERVIEW

This section will find and include a located hunk of Pod.  In general, it will
find a region with the specified name, such as:

  =begin :myfoo

  =head1 More Pod Here

  =end :myfoo

In other words, if your configuration include:

  [Region]
  region_name = myfoo

...then this weaver will look for "=begin :myfoo" ( and "=for :myfoo" and... ) and include
it at the appropriate location in your output.

Since you'll probably want to use Region several times, and that will require
giving each use a unique name, you can omit C<region_name> if you provide a
plugin name, and it will default to the plugin name.  In other words, the
configuration above could be specified just as:

  [Region / myfoo]

If the C<required> attribute is given, and true, then an exception will be
raised if this region can't be found.

=head1 ATTRIBUTES

=head2 required

A boolean value specifying whether this region is required to be present or not. Defaults
to false.

If it's enabled and the region can't be found an exception will be raised.

=head2 region_name

The name of this region. Defaults to the plugin name.

=head2 allow_nonpod

A boolean value specifying whether nonpod regions are allowed or not. Defaults to false.

C<nonpod> regions are regions I<without> a C<:> prefix as explained in
L<< perlpodspec|perlpodspec/About Data Paragraphs and "=begin/=end" Regions >>

  # region_name = myregion
  # is_pod = false
  =begin myregion

  # region_name = myregion
  # is_pod = true
  =begin :myregion

=head2 flatten

A boolean value specifying whether the region's contents should be flattened or not. Defaults to true.

  #unflattened
  =begin :myregion

  =head1

  =end :myregion

  #flattened
  =head1

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
