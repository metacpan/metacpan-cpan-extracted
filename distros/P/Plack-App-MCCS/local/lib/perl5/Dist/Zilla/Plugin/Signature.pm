package Dist::Zilla::Plugin::Signature;
BEGIN {
  $Dist::Zilla::Plugin::Signature::VERSION = '1.100930';
}
use Moose;
with 'Dist::Zilla::Role::FileGatherer';
with 'Dist::Zilla::Role::BeforeArchive';
with 'Dist::Zilla::Role::AfterBuild';


has sign => (is => 'ro', default => 'archive');


sub do_sign {
  my $self = shift;
  my $dir  = shift;

  require Module::Signature;
  require File::chdir;

  local $File::chdir::CWD = $dir;
  Module::Signature::sign(overwrite => 1) && die "Cannot sign";
}

sub before_archive {
  my $self = shift;

  $self->do_sign($self->zilla->built_in)
    if $self->sign =~ /archive/i;
}

sub after_build {
  my $self = shift;
  my $arg  = shift;

  $self->do_sign($arg->{build_root})
    if $self->sign =~ /always/i;
}


sub gather_files {
  my ($self, $arg) = @_;

  require Dist::Zilla::File::InMemory;

  my $file = Dist::Zilla::File::InMemory->new(
    { name    => 'SIGNATURE',
      content => "",
    }
  );

  $self->add_file($file);

  return;
}

sub BUILDARGS {
  my $self = shift;
  my $args = @_ == 1 ? shift : {@_};
  $args->{sign} = $ENV{DZSIGN} if exists $ENV{DZSIGN};
  $args;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::Signature - sign releases with Module::Signature


=head1 VERSION

version 1.100930

=head1 DESCRIPTION

This plugin will sign a distribution using Module::Signature.

This plugin should appear after any other AfterBuild plugin in your C<dist.ini> file
to ensre that no files are modified after it has been run

=head1 ATTRIBUTES

=over

=item sign

A string value. If C<archive> then a signature will be created when an archive is being created.
If C<always> then the directory will be signed whenever it is built. Default is C<archive>

This attribute can be overridden by an environment variable C<DZSIGN>

=back

=head1 AUTHOR

  Graham Barr <gbarr@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Graham Barr.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut