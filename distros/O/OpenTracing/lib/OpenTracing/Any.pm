package OpenTracing::Any;

use strict;
use warnings;

our $VERSION = '1.003'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

no indirect;
use utf8;

=encoding utf8

=head1 NAME

OpenTracing::Any - application tracing

=head1 SYNOPSIS

 use OpenTracing::Any qw($tracer);
 {
  my $span = $tracer->span(operation_name => 'whatever');
  $span->add_tag(xyz => 'abc');
  sleep 3;
 }
 # at this point the span will be finished and have an approximate timing of ~3s

=head1 DESCRIPTION

This provides a tracer to the current package. By default it will be given the
package variable name C<< $tracer >>, but you can override this by providing a
different name:

 use OpenTracing::Any qw($renamed_tracer_variable);
 $renamed_tracer_variable->span(...);

See L<OpenTracing::Tracer> for more details on available methods.

See also: L<Log::Any>.

=cut

use OpenTracing;

sub import {
    my ($class, @args) = @_;
    die 'too many parameters when loading OpenTracing::Any - expects a single variable name'
        if @args > 1;

    # Normally we'd expect the caller to provide a variable name - but if they don't,
    # '$tracer' seems as good a default as any
    my ($injected_variable) = (@args, '$tracer');
    my ($bare_name) = $injected_variable =~ /^\$(\w+)$/
        or die 'invalid injected variable name ' . $injected_variable;

    my ($pkg) = caller;
    my $fully_qualified = $pkg . '::' . $bare_name;
    {
        no strict 'refs';
        # This mostly does what we'd want if we're called at compiletime before any code actually tries
        # to use the injected variable - but as soon as the compiler sees $SomeModule::tracer it'll happily
        # tell the symbol table about it and trigger this check. Thus, it's currently disabled, and
        # since Log::Any also skips the check it seems we're in good company.
        # require B;
        # die $pkg . ' already has a variable called ' . $injected_variable if B::svref_2object(\*$fully_qualified)->SV->$*;
        *{$fully_qualified} = \(OpenTracing->global_tracer());
    }
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2018-2020. Licensed under the same terms as Perl itself.

