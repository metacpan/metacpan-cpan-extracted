package OS::CheckUpdates::AUR;

use v5.16;
use strict;
use warnings;

use if $ENV{CHECKUPDATES_DEBUG}, 'Smart::Comments';

use WWW::AUR::URI qw(rpc_uri);
use WWW::AUR::UserAgent;
use IO::Pipe;
use JSON;

=head1 NAME

OS::CheckUpdates::AUR - checkupdates for aur

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

checkupdates for aur

Example of code:

    use OS::CheckUpdates::AUR;

    my $foo = OS::CheckUpdates::AUR->new();

    # Print available updates:

    $foo->print();
    # or
    printf("%s %s -> %s\n", @{$_}[0..2]) foreach (@{$foo->get()});

=head1 SUBROUTINES/METHODS

=head2 new()

New...

=cut

sub new {
    ### OS-CheckUpdates-AUR created here
    return bless({}, shift);
}

=head2 get()

Get array with checkupdates: [name, local_ver, aur_ver]

=cut

sub get {
    my $self = shift;

    ### get() run refresh() if updates db is not created

    exists $self->{'updates'}
        or $self->refresh();

    ### get() return updates

    return $self->{'updates'};
}

=head2 print

Print checkupdates into stdout in chekupdates format.

=cut

sub print {
    my $self = shift;

    printf("%s %s -> %s\n", @{$_}[0..2]) foreach (@{$self->get()});

    return 1;
}

=head2 refresh()

Create/retrive/parse/refresh data about packages.

=cut

sub refresh {
    my $self = shift;
    my $local;

    $self->{'updates'} = [];

    ### refresh() reading 'pacman -Qm' output

    my $pipe = IO::Pipe->new();
    $pipe->reader(qw[pacman -Qm]);

    while(<$pipe>) {
        my ($name, $version) = split(" ");
        $local->{$name} = $version;
    };

    if ($#{[keys %$local]} < 0) {
        ### found 0 packages, nothing to do...
        return $self;
    }

    ### refresh() getting multiinfo()

    my @multiinfo_results = @{$self->multiinfo(sort keys %$local)->{'results'}};

    ### refresh() comparing versions

    my %seen;
    foreach (@multiinfo_results) {
        my $name = $_->{'Name'};
        my $vloc = $local->{$name}    or next;
        my $vaur = $_->{'Version'};

        !$seen{$name}++
            and ($vaur ne $vloc)
            and ($self->vercmp($vloc, $vaur) eq "-1")
            and push @{$self->{'updates'}}, [$name, $vloc, $vaur];
    }

    ### Locally installed: $#{[keys %$local]} + 1
    ###      Found on AUR: $#multiinfo_results + 1
    ###           Updates: $#{$self->{'updates'}} + 1

    return $self
}


=head2 vercmp($$)

Compare two versions in pacman way. Frontend for vercmp command.

=cut

sub vercmp {
    my ($self, $a, $b) = @_;

    if (defined $a and defined $b) {
        my $pipe = IO::Pipe->new();
        $pipe->reader('vercmp', $a, $b);

        while(<$pipe>) {
            chomp;

            /^(-1|0|1)$/
                and return scalar $_
                or  last;
        };

        $!=1; die(__PACKAGE__ . '->varcmp(): command not generated proper output');
    };

    $!=1; die(__PACKAGE__ . '->varcmp(): one or more versions are empty');
}

=head2 multiinfo(@)

Fast method to get info about multiple packages.

=cut

sub multiinfo {
    my $self     = shift;
    my $lwp      = WWW::AUR::UserAgent->new(
        'timeout' => 10,
        'agent'   => sprintf(
            'WWW::AUR/v%s (OS::CheckUpdates::AUR/v%s)',
            $WWW::AUR::VERSION,
            $VERSION,
        ),
        'protocols_allowed' => ['https'],
    );

    my $response = $lwp->get(rpc_uri('multiinfo', @_));

    $response->is_success
        and return decode_json($response->decoded_content);

    ### LWP decoded: $response->decoded_content

    $!=1; die(__PACKAGE__ . '->multiinfo(): LWP status error: ' . $response->status_line)
}

=head1 AUTHOR

3ED, C<< <krzysztof1987 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-checkupdates-aur at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OS-CheckUpdates-AUR>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OS::CheckUpdates::AUR


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OS-CheckUpdates-AUR>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OS-CheckUpdates-AUR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OS-CheckUpdates-AUR>

=item * Search CPAN

L<http://search.cpan.org/dist/OS-CheckUpdates-AUR/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 3ED.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of OS::CheckUpdates::AUR
