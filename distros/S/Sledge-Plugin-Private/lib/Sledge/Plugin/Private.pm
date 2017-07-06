package Sledge::Plugin::Private;

use strict;
use warnings;
our $VERSION = '0.02';

sub import {
    my $class = shift;
    my $pkg   = caller(0);
    if ($_[0] && uc($_[0]) eq 'POST') {
        $pkg->register_hook(
            AFTER_INIT => sub {
                my $self = shift;
                $self->set_private if $self->is_post_request;
            },
        );
    }
    no strict 'refs'; ## no critic
    *{"$pkg\::set_private"} = \&set_private;
}

sub set_private {
    my $self = shift;
    $self->r->header_out('Cache-Control' => 'private');
}

1;
__END__

=head1 NAME

Sledge::Plugin::Private - plugin to add private HTTP response

=head1 SYNOPSIS

 package Your::Pages;
 use Sledge::Plugin::Private;
 
 sub dispatch_foo {
     my $self = shift;
     $self->set_private;
 }

 # always private on POST request
 use Sledge::Plugin::Private 'POST';

=head1 DESCRIPTION

Sledge::Plugin::Private is a Sledge plugin to be able to use C<set_private()>
method on your Sledge based pages to append C<Cache-Control: private> header
on HTTP response.

Most part of this module is made by copy and paste from
C<Sledge::Plugin::NoCache>.

=head1 AUTHOR

Koichi Taniguchi (a.k.a. nipotan) E<lt>taniguchi@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Sledge>

=cut
