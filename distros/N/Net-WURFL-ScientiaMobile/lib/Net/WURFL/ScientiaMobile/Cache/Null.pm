package Net::WURFL::ScientiaMobile::Cache::Null;
use Moo;

with 'Net::WURFL::ScientiaMobile::Cache';

sub getDevice       { 0 }
sub getDeviceFromID { 0 }
sub setDevice       { 1 }
sub setDeviceFromID { 1 }
sub getMtime        { 0 }
sub setMtime        { 1 }
sub purge           { 1 }
sub incrementHit    {}
sub incrementMiss   {}
sub incrementError  {}
sub getCounters     { { hit => 0, miss => 0, error => 0, age => 0 } }
sub resetCounters   {}
sub resetReportAge  {}
sub getReportAge    { 0 }
sub stats           { {} }
sub close           {}

=head1 NAME

Net::WURFL::ScientiaMobile::Cache::Null - Bogus non-caching cache provider for the WURFL Cloud Client

=head1 SYNOPSIS

    use Net::WURFL::ScientiaMobile;
    use Net::WURFL::ScientiaMobile::Cache::Null;
    
    my $scientiamobile = Net::WURFL::ScientiaMobile->new(
        api_key => '...',
        cache   => Net::WURFL::ScientiaMobile::Cache::Null->new,
    );

=head1 DESCRIPTION

The Null WURFL Cloud Client Cache Provider. This exists only to disable caching and should not be 
used for production installations.

=head1 SEE ALSO

L<Net::WURFL::ScientiaMobile>, L<Net::WURFL::ScientiaMobile::Cache>

=head1 COPYRIGHT & LICENSE

Copyright 2012, ScientiaMobile, Inc.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
