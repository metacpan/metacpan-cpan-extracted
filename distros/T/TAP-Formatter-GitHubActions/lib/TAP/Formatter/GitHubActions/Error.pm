package TAP::Formatter::GitHubActions::Error;

use strict;
use warnings;
use v5.16;
use base 'TAP::Object';

my @ATTR;

BEGIN {
  @ATTR = qw(test_name filename line context_msg );
  __PACKAGE__->mk_methods(@ATTR);
}

my $TRIPHASIC_REGEX = qr/
  \s*
  (?<test_name>                   # Test header
    Failed\stest                  
    (?:\s*'[^']+')?               # Test name [usually last param in an assertion, optional]
  )
  \s*
  at\s(?<filename>.+)           # Location: File
  \s+
  line\s(?<line>\d+)\.          # Location: Line
  (\n)?
  (?<context_msg>[\w\W]*)       # Any additional content
/mx;

use constant {
  TRIPHASIC_REGEX => $TRIPHASIC_REGEX,
};

sub from_output {
  my ($class, $output) = @_;

  return undef unless $output =~ qr/$TRIPHASIC_REGEX/m;

  return $class->new(
    line => $+{line},
    filename => $+{filename},
    test_name => $+{test_name},
    context_msg => $+{context_msg}
  );
}

sub _initialize {
  my ($self, %args) = @_;

  $self->{test_name} = $args{test_name};
  $self->{filename} = $args{filename};
  $self->{line} = $args{line};
  $self->{context_msg} = $args{context_msg};

  return $self;
}

sub decorated_context_message {
  my ($self, $pre, $post) = @_;

  return unless $self->{context_msg};

  return join("\n",
    grep { $_ } ($pre, $self->context_msg, $post)
  );
}

sub as_plain_text {
  my ($self) = @_;
  my @components = (
    $self->test_name,
    $self->decorated_context_message(
      '--- CAPTURED CONTEXT ---',
      '---  END OF CONTEXT  ---')
  );
  return join("\n", grep { $_ } @components);
}

1;
__END__

=head1 NAME

TAP::Formatter::GitHubActions::Error - Error wrapper 

=head1 CONSTRUCTORS

=head2 from_output($output)

Builds a new C<TAP::Formatter::GitHubActions::Error> object out of an error
output section.

C<$output> must match C<$TAP::Formatter::GitHubActions::Error::TRIPHASIC_REGEX>

=head2 new(%args)

Builds a new C<TAP::Formatter::GitHubActions::Error> object.

=over 2

=item test_name

The name of the failing test, it'll be used as a sort-of header.

=item filename

The file name where the test happened.

=item line

The line name where the test happened.

=item context_msg

Any additional context provided.

Something similar to:

  got: 1
  expected: 2

=back

=head1 METHODS

=head2 decorated_context_message($pre, $post)

Returns the context message decorated with optional C<$pre> & C<$post> strings.

=head2 as_plain_text()

Returns the error in plain text.

=cut
