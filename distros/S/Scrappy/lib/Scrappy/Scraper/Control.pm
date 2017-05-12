# ABSTRACT: Scrappy HTTP Request Constraints System
# Dist::Zilla: +PodWeaver

package Scrappy::Scraper::Control;

BEGIN {
    $Scrappy::Scraper::Control::VERSION = '0.94112090';
}

# load OO System
use Moose;

# load other libraries
use URI;

has 'allowed' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'options' => (
    is        => 'ro',
    isa       => 'HashRef',
    'default' => sub { {} }
);
has 'restricted' => (is => 'rw', isa => 'HashRef', default => sub { {} });


sub allow {
    my ($self, $target, %constraints) = @_;
    my $i = 0;

    $target = URI->new($target);

    next
      unless $target
          && ("URI::http" eq ref $target || "URI::https" eq ref $target);

    $target = $target->host;

    delete $self->restricted->{$target}
      if defined $self->restricted->{$target};
    $self->allowed->{$target} = {%constraints};
    $i++ if defined $target;

    return $i;
}


sub restrict {
    my ($self, $target, %constraints) = @_;
    my $i = 0;

    $target = URI->new($target);

    next
      unless $target
          && ("URI::http" eq ref $target || "URI::https" eq ref $target);

    $target = $target->host;

    delete $self->allowed->{$target} if defined $self->allowed->{$target};
    $self->restricted->{$target} = {%constraints};
    $i++ if defined $target;

    return $i;
}


sub is_allowed {
    my $self    = shift;
    my $url     = shift;
    my %options = @_;

    # empty domain not allowed
    return 0 unless $url;

    # for advanced constraints checking, an HTTP::Response object may be passed
    my $http;

    if ("HTTP::Response" eq ref $url) {
        $http = $url;
        $url  = $url->request->uri;
    }

    return 0 unless ("URI::http" eq ref $url || "URI::https" eq ref $url);

    $url = $url->host;

    # is anything explicitly allowed, if so everything is restricted unless
    # explicitly defined in allowed
    if (keys %{$self->allowed}) {
        if (keys %{$self->allowed}) {

            # return $self->allowed->{$url} ? 1 : 0;
            if ($self->allowed->{$url}) {
                if ($self->allowed->{$url}->{if}) {
                    return $self->_check_constraints(
                        $self->allowed->{$url}->{if}, $http);
                }
                else {
                    return 1;
                }
            }
            else {
                return 0;
            }
        }
    }

    # is it explicitly restricted
    if (keys %{$self->restricted}) {
        if (keys %{$self->restricted}) {

            # return 0 if $self->restricted->{$url};
            if ($self->restricted->{$url}) {
                if ($self->restricted->{$url}->{if}) {
                    return $self->_check_constraints(
                        $self->allowed->{$url}->{if}, $http);
                }
                else {
                    return 1;
                }
            }
            else {
                return 0;
            }
        }
    }

    # i guess its cool
    return 1;
}

sub _check_constraints {
    my ($self, $constraints, $http_response) = @_;

    # check for failure, if not pass it
    if ($constraints->{content_type}) {
        my $ctype = $http_response->header('content_type');
        my $types =
          "ARRAY" eq ref $constraints->{content_type}
          ? $constraints->{content_type}
          : [$constraints->{content_type}];

        return 1 if (grep { $ctype eq $_ } @{$types});

    }
    return 0;
}

1;

__END__

=pod

=head1 NAME

Scrappy::Scraper::Control - Scrappy HTTP Request Constraints System

=head1 VERSION

version 0.94112090

=head1 SYNOPSIS

    #!/usr/bin/perl
    use Scrappy::Scraper::Control;

    my  $control = Scrappy::Scraper::Control->new;
    
        $control->allow('http://search.cpan.org');
        $control->allow('http://search.cpan.org', if => {
                content_type => ['text/html', 'application/x-tar']
            }
        );
        
        $control->restrict('http://www.cpan.org');
        
        if ($control->is_allowed('http://search.cpan.org/')) {
            ...
        }
        
        # constraints will only be checked if the is_allowed method is
        # passed a HTTP::Response object.

=head1 DESCRIPTION

Scrappy::Scraper::Control provides HTTP request access control for the L<Scrappy> framework.

=head2 ATTRIBUTES

The following is a list of object attributes available with every Scrappy::Scraper::Control
instance.

=head3 allowed

The allowed attribute holds a hasherf of allowed domain/contraints.

    my  $control = Scrappy::Scraper::Control->new;
        $control->allowed;
        
        e.g.
        
        {
            'www.foobar.com' => {
                methods => [qw/GET POST PUSH PUT DELETE/],
                content_type => ['text/html']
            }
        }

=head3 restricted

The restricted attribute holds a hasherf of restricted domain/contraints.

    my  $control = Scrappy::Scraper::Control->new;
        $control->restricted;
        
        e.g.
        
        {
            'www.foobar.com' => {
                methods => [qw/GET POST PUSH PUT DELETE/]
            }
        }

=head1 METHODS

=head2 allow

    my  $control = Scrappy::Scraper::Control->new;
        $control->allow('http://www.perl.org');
        $control->allow('http://search.cpan.org', if => {
                content_type => ['text/html', 'application/x-tar']
            }
        );

=head2 restrict

    my  $control = Scrappy::Scraper::Control->new;
        $control->restrict('http://www.perl.org');
        $control->restrict('http://search.cpan.org', if => {
                content_type => ['text/html', 'application/x-tar']
            }
        );

=head2 is_allowed

    my  $control = Scrappy::Scraper::Control->new;
        $control->allow('http://search.cpan.org');
        $control->restrict('http://www.perl.org');
        
        if (! $control->is_allowed('http://perl.org')) {
            die 'Cant get to Perl.org';
        }

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

