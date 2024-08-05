package MooseX::JSONSchema::Role;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Role for classes who have JSON Schema
$MooseX::JSONSchema::Role::VERSION = '0.001';
use Moose::Role;
use JSON::MaybeXS;

sub json_schema_data {
  my ( $self ) = @_;
  return {
    map {
      my $has = 'has_'.$_; $self->$has ? ( $_ => $self->$_ ) : ()
    } keys %{$self->meta->json_schema_properties},
  };
}

sub json_schema_data_json {
  my ( $self, %args ) = @_;
  my $data = $self->json_schema_data;
  my $json = JSON::MaybeXS->new(
    utf8 => 1,
    canonical => 1,
    %args,
  );
  return $json->encode($data);
}

1;

__END__

=pod

=head1 NAME

MooseX::JSONSchema::Role - Role for classes who have JSON Schema

=head1 VERSION

version 0.001

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/perl-moosex-jsonschema>

  git clone https://github.com/Getty/perl-moosex-jsonschema.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
