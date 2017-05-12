package Net::Lighthouse;

use MIME::Base64;
use LWP::UserAgent;
use Params::Validate ':all';
use Net::Lighthouse::Project;
use Net::Lighthouse::Token;
use Net::Lighthouse::User;
use base 'Net::Lighthouse::Base';

our $VERSION = '0.06';

sub project { return shift->_new( 'Project' ) }
sub user { return shift->_new( 'User' ) }
sub token { return shift->_new( 'Token' ) }

sub _new {
    my $self = shift;
    validate_pos(
        @_,
        {
            type  => SCALAR,
            regex => qr/^(Project|Token|User)$/,
        }
    );
    my $class  = 'Net::Lighthouse::' . shift;
    my $object = $class->new(
        map { $_ => $self->$_ }
          grep { $self->$_ } qw/account auth/
    );
    return $object;
}

sub projects {
    my $self   = shift;
    my $object = Net::Lighthouse::Project->new(
        map { $_ => $self->$_ }
          grep { $self->$_ } qw/account auth/
    );
    return $object->list(@_);
}

1;

__END__

=head1 NAME

Net::Lighthouse - Perl interface to lighthouseapp.com


=head1 VERSION

This document describes Net::Lighthouse version 0.06


=head1 SYNOPSIS

    use Net::Lighthouse;
    my $lh;
    $lh = Net::Lighthouse->new(
        account => 'foo',
        auth    => { token => 'bla' },
    );

    $lh = Net::Lighthouse->new(
        account => 'foo',
        auth    => { email => 'bar@example.com', password => 'password' },
    );

    my @projects = $lh->projects;
    my $project = $lh->project;
    my $token = $lh->token;
    my $user = $lh->user;


=head1 DESCRIPTION

L<Net::Lighthouse> is a Perl interface to lighthouseapp.com, by means of its official api.

=head1 INTERFACE

=over 4

=item projects

return a list of projects, each isa L<Net::Lighthouse::Project>.

=item project, token, user

return a corresponding object, with account and auth prefilled if exist.

=back

=head1 DEPENDENCIES

L<Any::Moose>, L<Params::Validate>, L<XML::TreePP>, L<LWP>, L<MIME::Base64>,
L<YAML::Syck>, L<DateTime>, L<URI::Escape>

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 SEE ALSO

L<Net::Lighthouse::Base>, L<http://lighthouseapp.com/api>

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2009-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

