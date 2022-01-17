package OpenTracing::DSL;

use strict;
use warnings;

our $VERSION = '1.006'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

no indirect;
use utf8;

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

use Syntax::Keyword::Try;

use Exporter qw(import export_to_level);

use Log::Any qw($log);
use OpenTracing::Any qw($tracer);

our %EXPORT_TAGS = (
    v1 => [qw(trace)],
);
our @EXPORT_OK = $EXPORT_TAGS{v1}->@*;

=head2 trace

Takes a block of code and provides it with an L<OpenTracing::SpanProxy>.

 trace {
  my ($span) = @_;
  $span->tag(
   'extra.details' => '...'
  );
 } operation_name => 'your_code';

Returns whatever your code did.

If the block of code throws an exception, that'll cause the span to be
marked as an error.

=cut

sub trace(&;@) {
    my ($code, %args) = @_;
    $args{operation_name} //= 'unknown';
    my $span = $tracer->span(%args);
    try {
        return $code->($span);
    } catch {
        my $err = $@;
        eval {
            $span->tag(
                error => 1,
                'operation.status' => 'failed'
            );
            $span->log(
                event   => 'general exception',
                payload => "$err"
            );
            1
        } or $log->warnf('Exception during span exception handler - %s', $@);
        die $err;
    } finally {
        undef $span
    }
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2018-2021. Licensed under the same terms as Perl itself.

