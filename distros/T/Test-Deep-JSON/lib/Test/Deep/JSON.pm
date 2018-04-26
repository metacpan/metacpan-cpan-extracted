package Test::Deep::JSON;
use strict;
use warnings;
use 5.008_001;
use Test::Deep ();
use Test::Deep::Cmp;
use JSON::MaybeXS;
use Exporter::Lite;

our $VERSION = '0.05';

our @EXPORT = qw(json);

sub json ($) {
    my ($expected) = @_;
    return __PACKAGE__->new($expected);
}

sub init {
    my ($self, $expected) = @_;
    $self->{val} = $expected;
}

sub descend {
    my ($self, $got) = @_;
    my $parsed = eval { decode_json($got) };
    if ($@) {
        $self->{error} = $@;
        return 0;
    }
    return Test::Deep::wrap($self->{val})->descend($parsed);
}

sub diagnostics {
    my $self = shift;
    return $self->{error} if defined $self->{error} && length $self->{error};
    return $self->{val}->diagnostics(@_);
}

1;

__END__

=head1 NAME

Test::Deep::JSON - Compare JSON with Test::Deep

=head1 SYNOPSIS

  use Test::Deep;
  use Test::Deep::JSON;

  cmp_deeply {
      foo => 'bar',
      payload => '{"a":1}',
  }, {
      foo => 'bar',
      payload => json({ a => ignore() }),
  };

=head1 DESCRIPTION

Test::Deep::JSON provides the C<json($expected)> function to expect that
target can be parsed as a JSON string and matches (by C<cmp_deeply>) with
I<$expected>.

=head1 FUNCTIONS

=over 4

=item json($expected)

Exported by default.

I<$expected> can be anything that C<Test::Deep> recognizes.

This parses the data as a JSON string, and compares the parsed object
and I<$expected> by C<Test::Deep> functionality.

Fails if the data cannot be parsed as a JSON string.

=back

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=head1 SEE ALSO

L<Test::Deep>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
