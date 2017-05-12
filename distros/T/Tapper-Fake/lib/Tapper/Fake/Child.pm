package Tapper::Fake::Child;
BEGIN {
  $Tapper::Fake::Child::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::Fake::Child::VERSION = '4.1.1';
}
# ABSTRACT: Fake Tapper::MCP::Child for testing

use Moose;
use common::sense;
use Tapper::Model 'model';

has testrun  => (is => 'rw');


sub runtest_handling
{

        my  ($self, $hostname) = @_;

        my $search = model('TestrunDB')->resultset('Testrun')->find($self->{testrun});
        foreach my $precondition ($search->ordered_preconditions) {
                if ($precondition->precondition_as_hash->{precondition_type} eq 'testprogram' ) {
                        sleep $precondition->precondition_as_hash->{timeout};
                }
        }
        return 0;

}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::Fake::Child - Fake Tapper::MCP::Child for testing

=head1 SYNOPSIS

 use Tapper::Fake::Child;
 my $client = Tapper::Fake::Child->new($testrun_id);
 $child->runtest_handling($system);

sub BUILDARGS {
        my $class = shift;

        if ( @_ >= 1 and not ref $_[0] ) {
                return { testrun => $_[0] };
        }
        else {
                return $class->SUPER::BUILDARGS(@_);
        }
}

=head1 FUNCTIONS

=head2 runtest_handling

Start testrun and wait for completion.

@param string - system name

@return success - 0
@return error   - error string

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

