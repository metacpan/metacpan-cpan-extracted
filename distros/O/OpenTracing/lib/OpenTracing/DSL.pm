package OpenTracing::DSL;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION

=encoding utf8

=head1 NAME

OpenTracing::DSL - application tracing

=head1 SYNOPSIS

 use OpenTracing::DSL qw(:v1);

 trace {
  my ($span) = @_;
  print 'operation starts here';
  $span->add_tag(internal_details => '...');
  sleep 2;
  print 'end of operation';
 };

=cut

use Exporter qw(import export_to_level);

use OpenTracing::Any qw($tracer);

our %EXPORT_TAGS = (
    v1 => [qw(trace)],
);
our @EXPORT_OK = $EXPORT_TAGS{v1}->@*;

sub trace(&;@) {
    my ($code, %args) = @_;
    my $name = delete($args{operation_name}) // 'unknown';
    my $span = $tracer->span($name, %args);
    return $code->($span);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2018-2019. Licensed under the same terms as Perl itself.

