package Path::Iterator::Rule::RT;

use 5.0100;
use strict;
use warnings FATAL => 'all';

use Path::Iterator::Rule;
use Error qw(:try);
use RT::Client::REST;
use RT::Client::REST::Ticket;

my $config_file = $ENV{HOME} . "/.rtrc";

my $config;

my $rt;

sub import {
    my $package = shift;
    if (@_ % 2) {
        die "${package}::import expects an even number of arguments, if any";
    }
    my %args =  @_;
    if ($args{config_file}) {
        $config_file = $args{config_file};
    }
}

# lazy builder for the RT client in $rt and the configuration in $config
sub _rt {
    unless ($rt) {
        $config = parse_config_file( $config_file );

        my ( $username, $password, $server ) =
  ( $config->{user}, $config->{passwd}, $config->{server} );

        $rt = RT::Client::REST->new(
    server  => $server,
    timeout => 30,
        );

        try {
    $rt->login( username => $username, password => $password );
        }
        catch Exception::Class::Base with {
    die "problem logging in: ", shift->message;
        };
    }

    return $rt;
}

Path::Iterator::Rule->add_helper(
    "status" => sub {
        my $status = shift;
        return sub {
            my ( $item, $basename ) = @_;
            return check_status( $basename, $status );
          }
    }
);

Path::Iterator::Rule->add_helper(
    "owner" => sub {
        my $owner = shift;
        return sub {
            my ( $item, $basename ) = @_;
            return check_owner( $basename, $owner );
          }
    }
);

Path::Iterator::Rule->add_helper(
    "TicketSQL" => sub {
        my $TicketSQL = shift;
        return sub {
            my ( $item, $basename ) = @_;
            return check_ticketSQL( $basename, $TicketSQL );
          }
    }
);

=head1 NAME

Path::Iterator::Rule::RT - Extends Path::Iterator::Rule with custom rule subroutines that make it easy to add RT ticket data as rules.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use Path::Iterator::Rule::RT;

    my $rule = Path::Iterator::Rule->new;
    $rule->status("resolved");
    for my $file ( $rule->all(@ARGV) ) {
        say $file;
    }


    my $rule = Path::Iterator::Rule->new;
    $rule->and(
	$rule->new->status("new"),
	$rule->new->owner("Nobody"),
    );
    for my $file ( $rule->all(@ARGV) ) {
        say $file;
    }

=head1 SUBROUTINES/METHODS

=head2 check_owner

$rule->owner("Nobody");

=cut

sub check_owner {
    my ( $id, $owner ) = @_;
    return unless $id =~ m/^\d+$/;
    my $ticket;
    try {
        $ticket = RT::Client::REST::Ticket->new(
            rt => _rt(),
            id => $id,
        )->retrieve;
    }
    catch Exception::Class::Base with {
        return;
    };
    return unless $ticket;
    return $owner eq $ticket->owner;
}

=head2 check_subject

$rule->subject("Foo");

=cut

sub check_subject{
    my ( $id, $subject) = @_;
    return unless $id =~ m/^\d+$/;
    my $ticket;
    try {
        $ticket = RT::Client::REST::Ticket->new(
            rt => _rt(),
            id => $id,
        )->retrieve;
    }
    catch Exception::Class::Base with {
        return;
    };
    return unless $ticket;
    return $subject eq $ticket->subject;
}

=head2 check_status

$rule->status("resolved");

=cut

sub check_status {
    my ( $id, $status ) = @_;
    return unless $id =~ m/^\d+$/;
    my $ticket;
    try {
        $ticket = RT::Client::REST::Ticket->new(
            rt => _rt(),
            id => $id,
        )->retrieve;
    }
    catch Exception::Class::Base with {
        return;
    };
    return unless $ticket;
    return $status eq $ticket->status;
}

=head2 check_ticketSQL

$rule->TicketSQL("Queue='General' AND Created = 'yesterday'");

The TicketSQL is not as it appears. It has id=<directory name> added to it. So 

this

$rule->TicketSQL("Queue='General' AND Created = 'yesterday'");

becomes

"id=<directory name> AND Queue='General' AND Created = 'yesterday'"

=cut

sub check_ticketSQL {
    my ( $id, $TicketSQL ) = @_;
    return unless $id =~ m/^\d+$/;
    my $query = "id=$id AND ";
    $query .= $TicketSQL;

    my @ids = rt()->search(
        type  => 'ticket',
        query => $query,
    );
    return scalar @ids == 1;
}

=head2 parse_config_file

NOTE: This code is a slightly modified version of RT::Client::CLI::parse_config_file.

=cut

sub parse_config_file {
    my %cfg;
    my ($file) = @_;
    local $_;

    open( my $handle, '<', $file ) or die "Error opening '$file' for reading: $!";

    while (<$handle>) {
        chomp;
        next if ( /^#/ || /^\s*$/ );

        if (/^(externalauth|user|passwd|server|query|orderby|queue)\s+(.*)\s?$/)
        {
            $cfg{$1} = $2;
        }
        else {
            die "rt: $file:$.: unknown configuration directive.\n";
        }
    }

    return \%cfg;
}

=head1 IMPORT

By default this module searches for RT client configuration in F<$HOME/.rtrc>

You can override the location by importing the module like so

    use Path::Iterator::Rule::RT config_file => '/path/to/config/file';


=head1 AUTHOR

Robert Blackwell, C<< <robert at robertblackwell.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-path-iterator-rule-rt at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Path-Iterator-Rule-RT>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/rblackwe/Path-Iterator-Rule-RT>

  git clone https://github.com/rblackwe/Path-Iterator-Rule-RT.git


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Path::Iterator::Rule::RT


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Path-Iterator-Rule-RT>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Path-Iterator-Rule-RT>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Path-Iterator-Rule-RT>

=item * Search CPAN

L<http://search.cpan.org/dist/Path-Iterator-Rule-RT/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Robert Blackwell.

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

1;    # End of Path::Iterator::Rule::RT
