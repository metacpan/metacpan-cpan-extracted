package Net::Google::Code::Role::Authentication;
use Any::Moose 'Role';

with 'Net::Google::Code::Role::Fetchable';

has 'email' => (
    isa => 'Str',
    is  => 'rw',
);

has 'password' => (
    isa => 'Str',
    is  => 'rw',
);

sub sign_in {
    my $self = shift;
    return 1 if $self->signed_in;
    die "need password" unless $self->password;

    $self->mech->get('https://www.google.com/accounts/Login');

    $self->mech->submit_form(
        with_fields => {
            Email  => $self->email,
            Passwd => $self->password,
        },
    );

    die 'sign in failed to google code'
      unless $self->signed_in;

    return 1;
}

sub sign_out {
    my $self = shift;
    $self->mech->get('https://www.google.com/accounts/Logout');

    die 'sign out failed to google code'
      unless $self->signed_in;

    return 1;
}

sub signed_in {
    my $self = shift;

    my $html = $self->mech->content;
    return unless $html;
    # remove lines of head, style and script
    $html =~ s!<head>.*?</head>!!sg;
    $html =~ s!<style.*?</style>!!sg;
    $html =~ s!<script.*?</script>!!sg;

    my @lines = split /\n/, $html;
    my $signed_in;
    my $line = 0;

    # only check the first 30 lines or so in case user input of 'sign out'
    # exists below
    for ( @lines ) {
        $signed_in = 1 if /sign out/i;
        $line++;
        last if $line == 30;
    }
    return $signed_in;
}

no Any::Moose;

1;

__END__

=head1 NAME

Net::Google::Code::Role::Authentication - Authentication Role 

=head1 DESCRIPTION

=head1 INTERFACE


=head2 sign_in

sign in

=head2 sign_out

sign out

=head2 signed_in

return 1 if already signed in, return undef elsewise.

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2008-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


