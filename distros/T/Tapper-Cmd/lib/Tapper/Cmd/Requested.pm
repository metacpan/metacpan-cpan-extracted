package Tapper::Cmd::Requested;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Cmd::Requested::VERSION = '5.0.9';
use Moose;

use Tapper::Model 'model';
use parent 'Tapper::Cmd';





sub add_host {

    my ( $self, $testrun_id, $i_host_id ) = @_;

    if ( $i_host_id !~ /^\d+$/ ) {
        if (
            !(
                $i_host_id =
                    model('TestrunDB')
                        ->resultset('Host')
                        ->search({ name => $i_host_id },{ rows => 1 })
                        ->first
                        ->id
            )
        ) {
            return;
        }
    }

    my $or_request =
        model('TestrunDB')
            ->resultset('TestrunRequestedHost')
            ->new({ testrun_id => $testrun_id, host_id => $i_host_id })
    ;
    $or_request->insert();

    return $or_request->id;

}


sub add_feature {
        my ($self, $id, $feature) = @_;

        my $request = model('TestrunDB')->resultset('TestrunRequestedFeature')->new({testrun_id => $id, feature => $feature});
        $request->insert();
        return $request->id;
}




1; # End of Tapper::Cmd::Testrun

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Cmd::Requested

=head1 SYNOPSIS

This project is offers wrapper around database manipulation functions. These
wrappers handle things like setting default values or id<->name
translation. This module handles requested hosts and features for a
testrequest.

    use Tapper::Cmd::Testrun;

    my $bar = Tapper::Cmd::Testrun->new();
    $bar->add($testrun);
    ...

=head1 NAME

Tapper::Cmd::Request - Backend functions for manipluation of requested hosts or features in the database

=head1 FUNCTIONS

=head2 add_host

Add a requested host entry to database.

=head2 add_host

Add a requested host for a given testrun.

@param int              - testrun id
@param string/integer   - hostname or host id

@return success - local id (primary key)
@return error   - undef

=head2 add_feature

Add a requested feature for a given testrun.

@param int    - testrun id
@param string - feature

@return success - local id (primary key)
@return error   - undef

=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
