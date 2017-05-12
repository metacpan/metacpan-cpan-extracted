#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Hook;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Hook - Hook class for the Nile framework.

=head1 SYNOPSIS
    
    # run this hook before the "start"
    $me->hook->before_start( sub {
        my ($me, @args) = @_; 

    });
    
    # run this hook after the "start"
    $me->hook->after_start( sub { 
        my ($me, @args) = @_;

    });
    
    # inside plugins and modules
    
    # call the before hook for "start"
    #$self->me->hook->on_start;

    # call the after hook for "start"
    #$self->me->hook->off_start;

=head1 DESCRIPTION

Nile::Hook - Hook class for the Nile framework.

=cut

use Nile::Base;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub AUTOLOAD {
    
    my ($self) = shift;

    my ($class, $method) = our $AUTOLOAD =~ /^(.*)::(\w+)$/;

    if ($self->can($method)) {
        return $self->$method(@_);
    }
    
    # $me->hook->before_start(sub {});
    my ($action, $name) = $method =~ /^(before|after|on|off)_(.*)/;

    if ($action && $name) {
        $action = "hook_$action";
        $self->$action($name, @_);
    }

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub BUILD {
    my ($self, $arg) = @_;
    $self->{hooks}->{before} = +{};
    $self->{hooks}->{after} = +{};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub hook_before {
    my ($self, $name, @args) = @_;
    #say "hook_before $name, @args";
    push @{$self->{hooks}->{before}->{$name}}, [@args];
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub hook_after {
    my ($self, $name, @args) = @_;
    push @{$self->{hooks}->{after}->{$name}}, [@args];
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub hook_on {
    
    my ($self, $name, @args) = @_;

    exists $self->{hooks}->{before}->{$name} || return sub {};

    my @hooks = @{$self->{hooks}->{before}->{$name}};

    @hooks || return sub {};
    
    my ($code, @hook_args);

    foreach my $hook (@hooks) {
        ($code, @hook_args) = @{$hook};
        $code->($self->me, @args, @hook_args);
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub hook_off {
    
    my ($self, $name, @args) = @_;
    
    exists $self->{hooks}->{after}->{$name} || return sub {};

    my @hooks = @{$self->{hooks}->{after}->{$name}};

    @hooks || return sub {};
    
    my ($code, @hook_args);

    foreach my $hook (@hooks) {
        ($code, @hook_args) = @{$hook};
        $code->($self->me, @args, @hook_args);
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
