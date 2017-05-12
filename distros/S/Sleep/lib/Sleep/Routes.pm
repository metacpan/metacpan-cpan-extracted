package Sleep::Routes;

use strict;
use warnings;

sub new {
    my $klass  = shift;
    my $routes = shift;

    die "Not an ARRAY" unless ref($routes) eq 'ARRAY';

    my $self = bless {
        routes => $routes,
    }, $klass;

    return $self;
}


sub parse_url {
    my $self = shift;
    my $url  = shift;

    for (@{$self->{routes}}) {
        if (my (@vars) = $url =~ m/$_->{route}/) {
            return ($_, @vars);
        }
    }

    return;
}

sub resource {
    my $self = shift;
    my $url  = shift;

    my ($route, @vars) = $self->parse_url($url);
    return ($route, @vars);
}

1;

__END__


=head1 NAME

Sleep::Routes - From URI to classname.

=head1 SYNOPSYS

    my $routes = Sleep::Routes->new([
        { 
            route => qr{/question(?:/(\d+))?$},
            class => 'QA::Question' 
        },
        { 
            route => qr{/question/(\d+)/comments$},
            class => 'QA::Comment' 
        },
    ]);

=head1 DESCRIPTION

=head1 CLASS METHODS

=over 4

=item Sleep::Routes->new([ ROUTES ])

A route should contain at least two entries: C<route> and C<class>. The C<route> is a regular expression
which will be matched to an URL. The C<class> should the name of a subclass of C<Sleep::Resource> which will
work with the arguments.

=back

=head1 METHODS

=over 4

=item SELF->resource(URL)

Returns the first route that matched and the variables from the URL that were
parsed from it.

=item SELF->parse_url(URL)

Does the actual check of URL described in L<resource>

=back

=head1 BUGS

If you find a bug, please let the author know.

=head1 COPYRIGHT

Copyright (c) 2008 Peter Stuifzand.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 AUTHOR

Peter Stuifzand E<lt>peter@stuifzand.euE<gt>

