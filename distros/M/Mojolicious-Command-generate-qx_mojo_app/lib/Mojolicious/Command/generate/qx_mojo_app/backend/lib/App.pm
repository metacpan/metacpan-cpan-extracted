% my $p = shift;
package <%= $p->{class} %>;

use Mojo::Base 'Mojolicious';

=head1 NAME

<%= $p->{class} %> - the Mojolicious application class

=head1 SYNOPSIS

 use Mojolicious::Commands;
 Mojolicious::Commands->start_app('<%= $p->{class} %>');

=head1 DESCRIPTION

Configure the mojo engine to run our application logic as web requests arrive.

=head1 ATTRIBUTES

All the attributes from L<Mojolicious>.

=cut

=head1 METHODS

All the methods of L<Mojolicious> as well as:

=cut

=head2 startup

Mojolicious calls the startup method at initialization time.

=cut

sub startup {
    my $app = shift;

    # $app->secrets(['my very own secret']);

    $app->plugin('qooxdoo',{
        path => '/jsonrpc',
        controller => 'RpcService'
    });
}

1;

<%= '__END__' %>

=head1 COPYRIGHT

Copyright (c) <%= $p->{year} %> by <%= $p->{fullName} %>. All rights reserved.

=head1 AUTHOR

S<<%= $p->{fullName} %> E<lt><%= $p->{email} %>E<gt>>

=cut

