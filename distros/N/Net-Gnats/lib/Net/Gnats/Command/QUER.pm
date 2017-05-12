package Net::Gnats::Command::QUER;
use parent 'Net::Gnats::Command';
use strictures;
BEGIN {
  $Net::Gnats::Command::QUER::VERSION = '0.22';
}
use vars qw($VERSION);

use Net::Gnats::Constants qw(CODE_PR_READY CODE_INVALID_QUERY_FORMAT CODE_NO_PRS_MATCHED);

=head1 NAME

Net::Gnats::Command::QUER

=head1 DESCRIPTION

Searches the contents of the database for PRs that match the
(optional) specified expressions with the EXPR command. If no
expressions were specified with EXPR, the entire set of PRs is
returned.

If one or more PRs are specified on the command line, only those PRs
will be searched and/or output.

The format of the output from the command is determined by the query
format selected with the QFMT command.

=head1 PROTOCOL

 QUER [pr...]

=head1 RESPONSES

The possible responses are:

418 (CODE_INVALID_QUERY_FORMAT)
A valid format was not specified with the QFMT command prior to invoking QUER.

300 (CODE_PR_READY) One or more PRs will be output using the
    requested query format. The PR text is quoted using the normal
    quoting mechanisms for PRs.

220 (CODE_NO_PRS_MATCHED)  No PRs met the specified criteria.

=cut

my $c = 'QUER';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless \%options, $class;
  $self->{pr_numbers} = [] if not defined $self->{pr_numbers};
  return $self;
}

sub as_string {
  my $self = shift;
  return $c . ' ' . join ' ', @{ $self->{pr_numbers}}
    if ( scalar @{$self->{pr_numbers}} != 0);
  return $c;
}

sub is_ok {
  my $self = shift;
  return 1 if $self->response->code == CODE_PR_READY;
  return 0;
}

1;
