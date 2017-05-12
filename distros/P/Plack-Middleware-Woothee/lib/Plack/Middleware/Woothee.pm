package Plack::Middleware::Woothee;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.05';

use parent 'Plack::Middleware';

use Plack::Util::Accessor qw/
    parse_all_req
    parser
/;

sub prepare_app {
    my ($self) = @_;

    unless ($self->parser) {
        $self->parser('Woothee');
    }

    LOAD_PARSER: {
        my $file = $self->parser;
        $file =~ s!::!/!g;
        require "$file.pm"; ## no critic
    }
}

sub call {
    my($self, $env) = @_;

    $env->{'psgix.woothee'} = Plack::Middleware::Woothee::Object->new(
        parser     => $self->parser,
        user_agent => $env->{HTTP_USER_AGENT},
    );

    $env->{'psgix.woothee'}->parse if $self->parse_all_req;

    $self->app->($env);
}

1;

package Plack::Middleware::Woothee::Object;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub user_agent { $_[0]->{user_agent} }

sub name {
    return $_[0]->_get('name');
}

sub category {
    return $_[0]->_get('category');
}

sub os {
    return $_[0]->_get('os');
}

sub vendor {
    return $_[0]->_get('vendor');
}

sub version {
    return $_[0]->_get('version');
}

sub _get {
    my ($self, $key) = @_;

    unless ($self->{$key}) {
        $self->parse;
    }

    return $self->{$key};
}

sub parse {
    my $self = shift;

    $self->{parse} ||= $self->{parser}->parse($self->{user_agent});

    for my $key (keys %{$self->{parse}}) {
        $self->{$key} = delete $self->{parse}{$key};
    }
}

sub is_crawler {
    my $self = shift;

    unless ( exists $self->{is_crawler} ) {
        $self->{is_crawler} ||= $self->{parser}->is_crawler($self->{user_agent});
    }

    return $self->{is_crawler};
}

1;

__END__

=head1 NAME

Plack::Middleware::Woothee - Set woothee information based on User-Agent

=head1 VERSION

This document describes Plack::Middleware::Woothee version 0.05.

=head1 SYNOPSIS

    use Plack::Middleware::Woothee;
    use Plack::Builder;

    my $app = sub {
        my $env = shift;
        # automatically assigned by Plack::Middleware::Woothee
        my $woothee = $env->{'psgix.woothee'};
        ...
    };
    builder {
        enable 'Woothee';
        $app;
    };

=head1 DESCRIPTION

This middleware get woothee information based on User-Agent and assign
this to `$env->{'psgix.woothee'}`.

You can use this information in your application.

=head1 MIDDLEWARE OPTIONS

=head2 parser

Switch parser from B<Woothee>(default) to something. A module must have a C<parse> methods, and should have an C<is_crawler> method.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl> L<Woothee>

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, Masayuki Matsuki. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
