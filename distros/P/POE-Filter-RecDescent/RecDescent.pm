package POE::Filter::RecDescent;

use strict;
use Parse::RecDescent;
use Carp qw(croak);
use vars qw($VERSION);

$VERSION = '0.02';

sub DEBUG() { 0 };
#sub DEBUG() { 1 };

# {{{ new
sub new {
  my $type = shift;
  my $grammar = shift;
  my $self = {
    parser => Parse::RecDescent->new($grammar),
    buffer => '',
    crlf => "\x0D\x0A",
  };
  bless $self, $type;
  return $self;
}
# }}}
# {{{ get
sub get {
  my ($self, $stream) = @_;

  return [ $self->{parser}->startrule(join('',@$stream)) ];
}
# }}}
#sub get_one_start { }
#sub get_one { }
sub put { }
sub get_pending { }

1;

__END__

# {{{ Documentation
=head1 NAME

POE::Filter::RecDescent - Parse an incoming data stream under specified rules.

=head1 SYNOPSIS

  $msg = POE::Filter::RecDescent->new($grammar_string);
  $parse_tree = $msg->get($array_ref_of_raw_chunks_from_driver);

=head1 DESCRIPTION

The RecDescent filter relies on Parse::RecDescent for its grammar and parser.
Each call to get() invokes the parser on the text string passed in.

=head1 PUBLIC FILTER METHODS

Please see POE::Filter.

=head1 SEE ALSO

L<POE::Filter>, L<Parse::RecDescent>

The SEE ALSO section in L<POE> contains a table of contents covering
the entire POE distribution.

=head1 AUTHORS & COPYRIGHTS

Jeff Goff, E<lt>jgoff@cpan.orgE<gt> (DrForr on irc.perl.org)

Please see L<POE> for more information about authors and contributors.

=cut
# }}}
