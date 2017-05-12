package Path::Router::Shell;
our $AUTHORITY = 'cpan:STEVAN';
$Path::Router::Shell::VERSION = '0.15';
use Term::ReadLine  1.11;
use Types::Standard 1.000005 qw(InstanceOf);
use Data::Dumper    2.154;

use Moo              2.000001;
use namespace::clean 0.23;
# ABSTRACT: An interactive shell for testing router configurations

has 'router' => (
    is       => 'ro',
    isa      => InstanceOf['Path::Router'],
    required => 1,
);

sub shell {
    my $self = shift;

    my $term = Term::ReadLine->new(__PACKAGE__);
    my $OUT = $term->OUT || \*STDOUT;

    while ( defined ($_ = $term->readline("> ")) ) {
        chomp;
        return if /[qQ]/;
        my $map = $self->router->match($_);
        if ($map) {
            print $OUT Dumper $map;
            print $OUT "Round-trip URI is : " . $self->router->uri_for(%$map),
        }
        else {
            print $OUT "No match for $_\n";
        }
        $term->addhistory($_) if /\S/;
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Router::Shell - An interactive shell for testing router configurations

=head1 VERSION

version 0.15

=head1 SYNOPSIS

  #!/usr/bin/perl

  use strict;
  use warnings;

  use My::App::Router;
  use Path::Router::Shell;

  Path::Router::Shell->new(router => My::App::Router->new)->shell;

=head1 DESCRIPTION

This is a tool for helping test the routing in your applications, so
you simply write a small script like showing in the SYNOPSIS and then
you can use it to test new routes or debug routing issues, etc etc etc.

=head1 METHODS

=over 4

=item B<new (router => $router)>

=item B<router>

=item B<shell>

=item B<meta>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
